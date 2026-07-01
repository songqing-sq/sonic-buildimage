"""Render a single sonic-yang Jinja2 template.

Mirrors the template-rendering loop in setup.py: takes one input .yang.j2
file plus the desired yang_model_type ("py" or "cvl") and writes the
rendered .yang to the output path.
"""

import argparse
import os
import sys

import jinja2


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--template", required=True)
    parser.add_argument("--yang_model_type", required=True, choices=("py", "cvl"))
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    template_dir = os.path.dirname(args.template)
    template_name = os.path.basename(args.template)
    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(template_dir),
        trim_blocks=True,
    )
    template = env.get_template(template_name)
    rendered = template.render(yang_model_type=args.yang_model_type)
    with open(args.out, "w") as f:
        f.write(rendered)


if __name__ == "__main__":
    sys.exit(main())
