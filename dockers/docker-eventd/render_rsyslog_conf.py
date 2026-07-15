"""Render rsyslog_plugin.conf.j2 against a *_events_info.json file.

Mirrors `j2 -f json rsyslog_plugin.conf.j2 <stream>_events_info.json` from
docker-eventd's Dockerfile.j2 lines 40-44, but runs at Bazel build time so the
.json + .j2 sources are not shipped into the image.

Implements only the Jinja2 subset the template actually uses ({% for proc in
proclist %}...{% endfor %} plus {{ var }} / {{ obj.attr }} interpolation),
so no jinja2 dependency is required at build time.
"""

import argparse
import json
import re
import sys


_VAR_RE = re.compile(r"\{\{\s*([\w\.]+)\s*\}\}")
_FOR_RE = re.compile(
    r"\{%\s*for\s+(\w+)\s+in\s+(\w+)\s*%\}(.*?)\{%\s*endfor\s*%\}",
    re.DOTALL,
)


def _resolve(expr, ctx):
    parts = expr.split(".")
    val = ctx[parts[0]]
    for p in parts[1:]:
        val = val[p]
    return val


def _interpolate(text, ctx):
    return _VAR_RE.sub(lambda m: str(_resolve(m.group(1), ctx)), text)


def render(template_text, ctx):
    def expand_for(m):
        loop_var, list_expr, body = m.group(1), m.group(2), m.group(3)
        rendered = []
        for item in _resolve(list_expr, ctx):
            local_ctx = dict(ctx, **{loop_var: item})
            rendered.append(_interpolate(body, local_ctx))
        return "".join(rendered)

    expanded = _FOR_RE.sub(expand_for, template_text)
    return _interpolate(expanded, ctx)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--template", required=True)
    p.add_argument("--data", required=True)
    p.add_argument("--output", required=True)
    args = p.parse_args()

    with open(args.template) as f:
        tmpl = f.read()
    with open(args.data) as f:
        ctx = json.load(f)
    with open(args.output, "w") as f:
        f.write(render(tmpl, ctx))


if __name__ == "__main__":
    sys.exit(main() or 0)
