"""Build-time helpers for the sonic-frr Bazel port (FRR 10.5.4, Approach B).

Adapted from the sonic-alibgp reference (FRR 8.2.2) for:
  * a *root-layout* patched source tree (@frr_patched repo root == FRR top
    srcdir), so quoted includes `#include "lib/foo.h"` / `#include "config.h"`
    / `#include "zebra/foo_clippy.c"` resolve through Bazel's automatic
    `-iquote <repo-src-root>` and `-iquote <repo-genfile-root>` (no hardcoded
    `-Iexternal/...+` / `-Ibazel-out/k8-opt/...` copts -> arch-agnostic,
    Lesson 11 clean).
  * libyang3 (`@libyang3//:yang_shared`, `@libyang3//:yang_hdrs_prefixed`).
  * FRR 10.5.4 daemon set.
"""

load(
    "@rules_proto_grpc//:defs.bzl",
    "ProtoPluginInfo",
    "filter_files",
    "proto_compile_attrs",
    "proto_compile_impl",
    "proto_compile_toolchains",
)

# =============================================================================
# clippy_genrule
# =============================================================================

def _clippy_genrule_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.basename + "_clippy.c")
    clippy_files = ctx.attr.clippy[DefaultInfo].files_to_run
    clippy_runfiles = ctx.attr.clippy[DefaultInfo].default_runfiles.files

    py_prefix_files = ctx.attr._exec_py_prefix[DefaultInfo].files.to_list()
    py_prefix_file = None
    for f in py_prefix_files:
        if f.path.endswith(".prefix"):
            py_prefix_file = f
            break

    extra_inputs = []
    for dep in ctx.attr.frr_extra_inputs:
        extra_inputs.extend(dep.files.to_list())

    inputs = depset(
        direct = ctx.files.src + ctx.files.clidef + ctx.files.clippy_pkg +
                 extra_inputs + py_prefix_files,
        transitive = [clippy_runfiles],
    )

    route_types = None
    for f in extra_inputs:
        if f.basename == "route_types.h":
            route_types = f
            break
    if route_types == None:
        fail("clippy_genrule: route_types.h must be passed via frr_extra_inputs")

    cmd = (
        "set -euo pipefail\n" +
        "WD=$(mktemp -d)\n" +
        "mkdir -p \"$WD/lib\"\n" +
        "ln -s \"$PWD/" + route_types.path + "\" \"$WD/lib/route_types.h\"\n" +
        "ABS_CLIPPY=\"$PWD/" + clippy_files.executable.path + "\"\n" +
        "ABS_CLIDEF=\"$PWD/" + ctx.file.clidef.path + "\"\n" +
        "ABS_OUT=\"$PWD/" + out.path + "\"\n" +
        "ABS_SRC=\"$PWD/" + ctx.file.src.path + "\"\n" +
        "ABS_CLIDEF_DIR=\"$PWD/" + ctx.file.clidef.dirname + "\"\n" +
        "ABS_PYHOME=\"$PWD/$(cat " + py_prefix_file.path + ")\"\n" +
        "cd \"$WD\"\n" +
        "exec env \\\n" +
        "    PYTHONHOME=\"$ABS_PYHOME\" \\\n" +
        "    PYTHONPATH=\"$ABS_CLIDEF_DIR\" \\\n" +
        "    \"$ABS_CLIPPY\" \"$ABS_CLIDEF\" -o \"$ABS_OUT\" \"$ABS_SRC\"\n"
    )

    ctx.actions.run_shell(
        outputs = [out],
        inputs = inputs,
        tools = [clippy_files],
        command = cmd,
        progress_message = "CLIPPY %s" % out.short_path,
        mnemonic = "Clippy",
    )

    return [DefaultInfo(files = depset([out]))]

def _exec_py_prefix_impl(ctx):
    py_runtime = ctx.toolchains["@rules_python//python:toolchain_type"].py3_runtime
    prefix_file = ctx.actions.declare_file(ctx.attr.name + ".prefix")
    ctx.actions.write(prefix_file, py_runtime.interpreter.dirname + "/..")
    return [DefaultInfo(files = depset([prefix_file] + py_runtime.files.to_list()))]

exec_py_prefix = rule(
    implementation = _exec_py_prefix_impl,
    toolchains = ["@rules_python//python:toolchain_type"],
)

clippy_genrule = rule(
    implementation = _clippy_genrule_impl,
    attrs = {
        "src": attr.label(allow_single_file = [".c"], mandatory = True),
        "basename": attr.string(mandatory = True),
        "clippy": attr.label(
            mandatory = True,
            executable = True,
            cfg = "exec",
        ),
        "clidef": attr.label(allow_single_file = [".py"], mandatory = True),
        "clippy_pkg": attr.label_list(allow_files = [".py"]),
        "frr_extra_inputs": attr.label_list(allow_files = True),
        "_exec_py_prefix": attr.label(
            default = ":_clippy_exec_py_prefix",
            cfg = "exec",
        ),
    },
)

# =============================================================================
# yang_genrule
# =============================================================================

def _yang_genrule_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.outname)

    ctx.actions.run_shell(
        outputs = [out],
        inputs = depset(direct = [ctx.file.src, ctx.file.embedmodel]),
        command = "python3 \"{}\" \"{}\" \"{}\"".format(
            ctx.file.embedmodel.path,
            ctx.file.src.path,
            out.path,
        ),
        progress_message = "YANG %s" % out.short_path,
        mnemonic = "YangEmbed",
        use_default_shell_env = True,
    )

    return [DefaultInfo(files = depset([out]))]

yang_genrule = rule(
    implementation = _yang_genrule_impl,
    attrs = {
        "src": attr.label(allow_single_file = [".yang"], mandatory = True),
        "outname": attr.string(mandatory = True),
        "embedmodel": attr.label(allow_single_file = [".py"], mandatory = True),
    },
)

# =============================================================================
# vtysh_cmd_genrule: mirror vtysh/extract.pl -> vtysh/vtysh_cmd.c.
# =============================================================================

_VTYSH_EXTRACT_PY = r"""
import os
import re
import sys

_DEFUN_RE = re.compile(
    r"((?:DEFUN_HIDDEN|DEFUN_YANG|DEFUN|ALIAS_HIDDEN|ALIAS_YANG|ALIAS"
    r"|DEFPY_HIDDEN|DEFPY_YANG|DEFPY)\s*\(.+?\));?\s?\s?\n",
    re.DOTALL,
)
_INSTALL_RE = re.compile(
    r"install_element\s*\(\s*[0-9A-Z_]+,\s*&[^;]*;\s*\n",
    re.DOTALL,
)
_HEAD_RE = re.compile(r"^(.*?)\s*\((.*)\)$", re.DOTALL)
_DEFINE_BODY_RE = re.compile(
    r"^[ \t]*#[ \t]*define[ \t]+([A-Z][A-Z0-9_]*)[ \t]+([^\n]*?)[ \t]*$",
    re.MULTILINE,
)
_DEFINE_FUNC_RE = re.compile(
    r"^[ \t]*#[ \t]*define[ \t]+([A-Z][A-Z0-9_]*)\(",
    re.MULTILINE,
)


def protocol_for(path):
    p = path.replace(os.sep, "/")
    if p.endswith("lib/keychain.c") or p.endswith("lib/keychain_cli.c"):
        return "VTYSH_RIPD|VTYSH_EIGRPD|VTYSH_ISISD"
    if p.endswith("lib/routemap.c") or p.endswith("lib/routemap_cli.c"):
        return "VTYSH_RMAP"
    if p.endswith("lib/vrf.c"):
        return "VTYSH_VRF"
    if p.endswith("lib/if.c"):
        return "VTYSH_INTERFACE"
    if p.endswith("lib/filter.c") or p.endswith("lib/filter_cli.c"):
        return "VTYSH_ACL"
    if p.endswith("lib/lib_vty.c") or p.endswith("lib/log_vty.c"):
        return "VTYSH_ALL"
    if p.endswith("lib/affinitymap.c") or p.endswith("lib/affinitymap_cli.c"):
        return "VTYSH_AFFINITYMAP"
    if p.endswith("lib/agentx.c") or p.endswith("lib/libagentx.c"):
        return ("VTYSH_ISISD|VTYSH_RIPD|VTYSH_OSPFD|VTYSH_OSPF6D"
                "|VTYSH_BGPD|VTYSH_ZEBRA")
    if p.endswith("lib/nexthop_group.c"):
        return "VTYSH_NH_GROUP"
    if p.endswith("lib/resolver.c"):
        return "VTYSH_NHRPD|VTYSH_BGPD"
    if p.endswith("lib/spf_backoff.c"):
        return "VTYSH_ISISD"
    if p.endswith("lib/vty.c") or p.endswith("lib/event.c"):
        return "VTYSH_ALL"
    if "/librfp/" in p or "/rfapi/" in p:
        return "VTYSH_BGPD"
    m = re.match(r"^(?:.*/)?([a-z0-9]+)/[a-zA-Z0-9_\-]+\.c$", p)
    if not m:
        sys.stderr.write("could not derive protocol for %s\n" % p)
        sys.exit(1)
    return "VTYSH_" + m.group(1).upper()


def plist_protocol(file_path, cmd_struct):
    if "ipv6" in cmd_struct:
        return ("VTYSH_RIPNGD|VTYSH_OSPF6D|VTYSH_BGPD|VTYSH_ZEBRA"
                "|VTYSH_BABELD|VTYSH_ISISD|VTYSH_FABRICD")
    return ("VTYSH_RIPD|VTYSH_OSPFD|VTYSH_BGPD|VTYSH_ZEBRA"
            "|VTYSH_PIMD|VTYSH_EIGRPD|VTYSH_BABELD|VTYSH_ISISD|VTYSH_FABRICD")


def if_rmap_protocol(cmd_struct):
    if "ipv6" in cmd_struct:
        return "VTYSH_RIPNGD"
    return "VTYSH_RIPD"


def build_macro_table(header_paths):
    table = {}
    func_like = set()
    for hp in header_paths:
        try:
            with open(hp, "r", encoding="utf-8", errors="replace") as fh:
                text = fh.read()
        except (OSError, IOError):
            continue
        text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
        text = re.sub(r"\\\n", " ", text)
        for m in _DEFINE_FUNC_RE.finditer(text):
            func_like.add(m.group(1))
        for m in _DEFINE_BODY_RE.finditer(text):
            name, body = m.group(1), m.group(2).strip()
            if name in func_like:
                continue
            body = re.sub(r"//.*$", "", body).strip()
            table[name] = body
    return table


_TOKEN_RE = re.compile(
    r'("(?:[^"\\]|\\.)*")|'
    r"('(?:[^'\\]|\\.)*')|"
    r"\b([A-Za-z_][A-Za-z_0-9]*)\b|"
    r"(.)",
    re.DOTALL,
)


def expand_once(text, table):
    out = []
    changed = False
    for m in _TOKEN_RE.finditer(text):
        s, c, w, ch = m.group(1), m.group(2), m.group(3), m.group(4)
        if s is not None:
            out.append(s)
        elif c is not None:
            out.append(c)
        elif w is not None:
            if w in table:
                out.append(table[w])
                changed = True
            else:
                out.append(w)
        elif ch is not None:
            out.append(ch)
    return "".join(out), changed


def expand_macros(text, table):
    for _ in range(32):
        text, changed = expand_once(text, table)
        if not changed:
            break
    for _ in range(4):
        new = re.sub(r'"\s*"', "", text)
        if new == text:
            break
        text = new
    return text


def scan_text(path, text, fabricd, cmd2str, cmd2defun, cmd2proto, cmd2hidden):
    p = path.replace(os.sep, "/")
    installs = []
    for raw in _DEFUN_RE.findall(text):
        m = _HEAD_RE.match(raw)
        if not m:
            continue
        head, body = m.group(1), m.group(2)
        hidden = "_HIDDEN" in head
        parts = body.split(",")
        if len(parts) < 3:
            continue
        cmd = parts[1].strip()
        if fabricd:
            cmd = "fabricd_" + cmd
        if p.endswith("lib/plist.c"):
            proto = plist_protocol(p, parts[1])
        elif p.endswith("lib/if_rmap.c"):
            proto = if_rmap_protocol(parts[1])
        elif fabricd:
            proto = "VTYSH_FABRICD"
        else:
            proto = protocol_for(p)
        parts[0] = ""
        parts[1] = cmd + "_vtysh"
        rebuilt = ", ".join(parts)
        cmd2str[cmd] = parts[2].strip()
        cmd2defun[cmd] = rebuilt
        cmd2proto[cmd] = proto
        cmd2hidden[cmd] = hidden
    for raw in _INSTALL_RE.findall(text):
        body = raw.strip()
        inner = body[len("install_element"):].strip()
        if not inner.startswith("(") or not inner.endswith(";"):
            continue
        inner = inner[1:].rstrip(";").rstrip().rstrip(")")
        elems = inner.split(",")
        if len(elems) < 2:
            continue
        node = elems[0].strip()
        m_node = re.search(r"([0-9A-Z_]+)$", node)
        if not m_node:
            continue
        ecmd_m = re.search(r"&([^\)]+)", elems[1])
        if not ecmd_m:
            continue
        ecmd = ecmd_m.group(1).strip()
        if fabricd:
            ecmd = "fabricd_" + ecmd
        installs.append((m_node.group(1), ecmd))
    return installs


def main():
    have_isisd = False
    have_fabricd = False
    args = []
    headers = []
    i = 1
    while i < len(sys.argv):
        a = sys.argv[i]
        if a == "--have-isisd":
            have_isisd = True
        elif a == "--have-fabricd":
            have_fabricd = True
        elif a == "--header-list":
            i += 1
            with open(sys.argv[i], "r") as fh:
                headers += [line.strip() for line in fh if line.strip()]
        else:
            args.append(a)
        i += 1
    out_path = args[0]
    files = args[1:]

    macro_table = build_macro_table(headers + files)

    def read(path):
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            return fh.read()

    cmd2str = {}
    cmd2defun = {}
    cmd2proto = {}
    cmd2hidden = {}
    all_installs = []

    def scan(path, fabricd):
        text = read(path)
        return scan_text(path, text, fabricd, cmd2str, cmd2defun, cmd2proto,
                         cmd2hidden)

    for f in files:
        rel = f.replace(os.sep, "/")
        if "/isisd/" in rel:
            if rel.endswith("isis_vty_isisd.c"):
                if have_isisd:
                    all_installs += [(n, e, f) for n, e in scan(f, False)]
            elif rel.endswith("isis_vty_fabricd.c"):
                if have_fabricd:
                    all_installs += [(n, e, f) for n, e in scan(f, True)]
            else:
                if have_isisd:
                    all_installs += [(n, e, f) for n, e in scan(f, False)]
                if have_fabricd:
                    all_installs += [(n, e, f) for n, e in scan(f, True)]
        else:
            all_installs += [(n, e, f) for n, e in scan(f, False)]

    for k, v in cmd2defun.items():
        cmd2defun[k] = expand_macros(v, macro_table)
    expanded_installs = []
    for node, ecmd, src in all_installs:
        node = expand_macros(node, macro_table).strip()
        m = re.match(r"^[A-Z][A-Z0-9_]*$", node)
        if not m:
            sys.stderr.write(
                "install_element node didn't reduce to identifier: %r "
                "(from %s)\n" % (node, src))
            continue
        expanded_installs.append((node, ecmd, src))
    all_installs = expanded_installs

    ocmd = {}
    odefun = {}
    defsh = {}
    oproto = {}
    for node, ecmd, _ in all_installs:
        if ecmd not in cmd2str:
            continue
        key = node + "," + cmd2str[ecmd]
        ocmd[key] = ecmd
        odefun[key] = cmd2defun[ecmd]
        defsh[key] = "DEFSH_HIDDEN" if cmd2hidden[ecmd] else "DEFSH"
        oproto.setdefault(key, []).append(cmd2proto[ecmd])

    live = {}
    for key, defun in odefun.items():
        live[ocmd[key]] = key

    out = []
    out.append("#include <zebra.h>\n\n")
    out.append('#include "command.h"\n')
    out.append('#include "linklist.h"\n\n')
    out.append('#include "vtysh/vtysh.h"\n\n')

    for cmd in sorted(live.keys()):
        key = live[cmd]
        proto = "|".join(oproto[key])
        out.append("%s (%s%s)\n\n" % (defsh[key], proto, odefun[key]))

    out.append("void vtysh_init_cmd(void)\n")
    out.append("{\n")
    for key in sorted(odefun.keys()):
        node = key.split(",", 1)[0]
        cmd = ocmd[key]
        if cmd.endswith("_cmd"):
            cmd = cmd[:-len("_cmd")] + "_cmd_vtysh"
        else:
            cmd = cmd + "_vtysh"
        out.append("  install_element (%s, &%s);\n" % (node, cmd))
    out.append("}\n")

    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write("".join(out))


if __name__ == "__main__":
    main()
"""

def _vtysh_cmd_genrule_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.outname)
    extract = ctx.actions.declare_file(ctx.label.name + "_extract.py")
    ctx.actions.write(extract, _VTYSH_EXTRACT_PY)

    header_list = ctx.actions.declare_file(ctx.label.name + "_headers.list")
    ctx.actions.write(
        header_list,
        "\n".join([f.path for f in ctx.files.headers]) + "\n",
    )

    inputs = list(ctx.files.srcs) + list(ctx.files.headers) + [
        extract,
        header_list,
    ]

    args = []
    if ctx.attr.have_isisd:
        args.append("--have-isisd")
    if ctx.attr.have_fabricd:
        args.append("--have-fabricd")
    args += ["--header-list", header_list.path]
    args.append(out.path)
    args += [f.path for f in ctx.files.srcs]

    ctx.actions.run(
        executable = "/usr/bin/python3",
        arguments = [extract.path] + args,
        inputs = inputs,
        outputs = [out],
        progress_message = "Generating %s" % out.short_path,
        mnemonic = "VtyshCmdGen",
        env = {"LC_ALL": "C"},
    )
    return [DefaultInfo(files = depset([out]))]

vtysh_cmd_genrule = rule(
    implementation = _vtysh_cmd_genrule_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".c"], mandatory = True),
        "headers": attr.label_list(allow_files = True),
        "outname": attr.string(mandatory = True),
        "have_isisd": attr.bool(default = False),
        "have_fabricd": attr.bool(default = False),
    },
)

# =============================================================================
# vtysh_daemons_h_genrule
# =============================================================================

def _vtysh_daemons_h_genrule_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.outname)
    daemons = ctx.attr.daemons
    daemons_list = "|".join(daemons)
    daemons_str = "".join(["For the %s daemon\\n" % d for d in daemons])
    content = ('#define DAEMONS_LIST "<' + daemons_list + '>"\n' +
               '#define DAEMONS_STR "' + daemons_str + '"\n')
    ctx.actions.write(out, content)
    return [DefaultInfo(files = depset([out]))]

vtysh_daemons_h_genrule = rule(
    implementation = _vtysh_daemons_h_genrule_impl,
    attrs = {
        "daemons": attr.string_list(mandatory = True),
        "outname": attr.string(mandatory = True),
    },
)

# =============================================================================
# protoc_c_compile + protoc_c_proto
# =============================================================================

protoc_c_compile = rule(
    implementation = proto_compile_impl,
    attrs = dict(
        proto_compile_attrs,
        _plugins = attr.label_list(
            providers = [ProtoPluginInfo],
            default = ["@protobuf_c//:protoc_gen_c_plugin"],
            cfg = "exec",
            doc = "Pinned to the protoc-gen-c plugin from the protobuf-c tarball.",
        ),
    ),
    toolchains = proto_compile_toolchains,
)

# =============================================================================
# vtysh_cmd_xref_genrule (FRR 10.5.4): generate vtysh/vtysh_cmd.c from the
# ELF-embedded FRRouting XREF note of every daemon/module binary.
#
# 10.5.4 replaced the old Perl `extract.pl` .c-scanning flow with an xref-based
# pipeline: each daemon/lib/module carries an ELF ".xref" section (emitted by
# the DEFUN/DEFPY xref macros at compile time); `clippy python/xrelfo.py -c
# vtysh_cmd.c <binaries...>` reads those sections (via the _clippy ELF module
# built into the clippy binary) and synthesises the DEFSH wrapper table.
# =============================================================================
def _vtysh_cmd_xref_genrule_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.outname)
    clippy_files = ctx.attr.clippy[DefaultInfo].files_to_run
    clippy_runfiles = ctx.attr.clippy[DefaultInfo].default_runfiles.files

    py_prefix_files = ctx.attr._exec_py_prefix[DefaultInfo].files.to_list()
    py_prefix_file = None
    for f in py_prefix_files:
        if f.path.endswith(".prefix"):
            py_prefix_file = f
            break

    bin_files = ctx.files.binaries
    origins = ctx.attr.origins

    inputs = depset(
        direct = [ctx.file.xrelfo] + ctx.files.py_pkg + bin_files + py_prefix_files,
        transitive = [clippy_runfiles],
    )

    # Stage each input ELF at its FRR-expected "origin" path so xref2vtysh
    # derives the right VTYSH_<daemon> token AND its `origin == "isisd/fabricd"`
    # special-case fires: daemon binaries need a dot-free basename (e.g.
    # "zebra"); versioned libs / plugin .so's need the correct parent directory
    # (xref2vtysh uses path.parts[-2] for dotted names); fabricd must be at the
    # literal relative path "isisd/fabricd".  We cd into the staging dir and
    # pass RELATIVE paths so xrelfo records the origin exactly as the staged
    # relative path.
    if origins and len(origins) == len(bin_files):
        stage_cmds = ["STAGE=\"$(mktemp -d)\""]
        rel_args = []
        for i in range(len(bin_files)):
            f = bin_files[i]
            origin = origins[i]
            stage_cmds.append("mkdir -p \"$STAGE/$(dirname '" + origin + "')\"")
            stage_cmds.append("ln -sf \"$PWD/" + f.path + "\" \"$STAGE/" + origin + "\"")
            rel_args.append("\"" + origin + "\"")
        bin_args = " ".join(rel_args)
        cmd = (
            "set -euo pipefail\n" +
            "\n".join(stage_cmds) + "\n" +
            "ABS_CLIPPY=\"$PWD/" + clippy_files.executable.path + "\"\n" +
            "ABS_XRELFO=\"$PWD/" + ctx.file.xrelfo.path + "\"\n" +
            "ABS_OUT=\"$PWD/" + out.path + "\"\n" +
            "ABS_PYHOME=\"$PWD/$(cat " + py_prefix_file.path + ")\"\n" +
            "PYDIR=\"$PWD/" + ctx.file.xrelfo.dirname + "\"\n" +
            "cd \"$STAGE\"\n" +
            "exec env \\\n" +
            "    PYTHONHOME=\"$ABS_PYHOME\" \\\n" +
            "    PYTHONPATH=\"$PYDIR\" \\\n" +
            "    \"$ABS_CLIPPY\" \"$ABS_XRELFO\" " + bin_args + " -c \"$ABS_OUT\"\n"
        )
    else:
        bin_args = " ".join(["\"$PWD/" + f.path + "\"" for f in bin_files])
        cmd = (
            "set -euo pipefail\n" +
            "ABS_CLIPPY=\"$PWD/" + clippy_files.executable.path + "\"\n" +
            "ABS_XRELFO=\"$PWD/" + ctx.file.xrelfo.path + "\"\n" +
            "ABS_OUT=\"$PWD/" + out.path + "\"\n" +
            "ABS_PYHOME=\"$PWD/$(cat " + py_prefix_file.path + ")\"\n" +
            "PYDIR=\"$PWD/" + ctx.file.xrelfo.dirname + "\"\n" +
            "exec env \\\n" +
            "    PYTHONHOME=\"$ABS_PYHOME\" \\\n" +
            "    PYTHONPATH=\"$PYDIR\" \\\n" +
            "    \"$ABS_CLIPPY\" \"$ABS_XRELFO\" " + bin_args + " -c \"$ABS_OUT\"\n"
        )

    ctx.actions.run_shell(
        outputs = [out],
        inputs = inputs,
        tools = [clippy_files],
        command = cmd,
        progress_message = "VTYSH_CMD (xref) %s" % out.short_path,
        mnemonic = "VtyshCmdXref",
    )
    return [DefaultInfo(files = depset([out]))]

vtysh_cmd_xref_genrule = rule(
    implementation = _vtysh_cmd_xref_genrule_impl,
    attrs = {
        "outname": attr.string(mandatory = True),
        "binaries": attr.label_list(allow_files = True, mandatory = True),
        "origins": attr.string_list(),
        "xrelfo": attr.label(allow_single_file = [".py"], mandatory = True),
        "py_pkg": attr.label_list(allow_files = [".py"]),
        "clippy": attr.label(mandatory = True, executable = True, cfg = "exec"),
        "_exec_py_prefix": attr.label(
            default = ":_clippy_exec_py_prefix",
            cfg = "exec",
        ),
    },
)

def protoc_c_proto(name, proto, basename, visibility = None):
    """proto_library -> protoc_c_compile -> `#include "config.h"` prepend."""
    compile_name = name + "_compile"
    protoc_c_compile(
        name = compile_name,
        protos = [proto],
        output_mode = "NO_PREFIX",
        visibility = ["//visibility:private"],
    )

    prepended_c_path = basename + ".pb-c.with_config.c"

    filter_files(
        name = name + "_h_filegroup",
        target = ":" + compile_name,
        extensions = ["h"],
        visibility = ["//visibility:private"],
    )
    filter_files(
        name = name + "_c_filegroup",
        target = ":" + compile_name,
        extensions = ["c"],
        visibility = ["//visibility:private"],
    )

    native.genrule(
        name = name + "_src",
        srcs = [":" + name + "_c_filegroup"],
        outs = [prepended_c_path],
        cmd = "{ echo '#include \"config.h\"'; cat $(execpath :" + name +
              "_c_filegroup); } > $@",
        visibility = visibility,
    )

    native.filegroup(
        name = name,
        srcs = [
            ":" + name + "_h_filegroup",
            ":" + name + "_src",
        ],
        visibility = visibility,
    )

# =============================================================================
# frr_daemon macro (root layout).
# =============================================================================

_FRR_DAEMON_COPTS = [
    "-D_GNU_SOURCE",
    "-DHAVE_CONFIG_H",
    "-DSYSCONFDIR=\\\"/etc/frr/\\\"",
    "-DCONFDATE=20260101",
    "-std=gnu11",
    "-fms-extensions",
    "-Wno-error=implicit-function-declaration",
    "-Wno-sign-compare",
    "-Wno-implicit-fallthrough",
    "-Wno-unused-but-set-variable",
    "-Wno-unused-function",
    "-Wno-unused-parameter",
    "-Wno-unused-variable",
    "-Wno-misleading-indentation",
    "-Wno-deprecated-declarations",
    "-fno-omit-frame-pointer",
]

_FRR_DAEMON_LINKOPTS = [
    "-Wl,--export-dynamic",
    "-pthread",
    "-lm",
]

_FRR_DAEMON_BASE_DEPS = [
    "@frr_patched//:frr_assert_hdrs",
    "@frr_patched//:frr_lib_v_hdrs",
    "@frr_patched//:frr_v_hdrs",
    "@frr_patched//:frr_lib_hdrs",
    "@libyang3//:yang_hdrs_prefixed",
    "@frr_patched//:libfrr",
    "@frr_deps//libcap-dev:libcap",
    "@frr_deps//libjson-c-dev:libjson-c",
]

_FRR_DAEMON_DYNAMIC_DEPS = [
    "@frr_patched//:libfrr_shared",
    "@libyang3//:yang_shared",
]

def frr_daemon(
        name,
        sources,
        clippy_sources = [],
        yang_models = [],
        nodist_yang = [],
        clippy_frr_inputs = [],
        extra_deps = [],
        extra_dynamic_deps = [],
        extra_linkopts = [],
        extra_copts = []):
    """Emit a complete FRR daemon target group (root layout)."""

    for c in clippy_sources:
        clippy_genrule(
            name = "{}_{}_clippy".format(name, c),
            src = "frr/{}/{}.c".format(name, c),
            basename = "frr/{}/{}".format(name, c),
            clippy = ":clippy",
            clidef = "frr/python/clidef.py",
            clippy_pkg = native.glob([
                "frr/python/clippy/*.py",
                "frr/python/*.py",
            ]),
            frr_extra_inputs = clippy_frr_inputs,
        )

    for stem, src_path in yang_models:
        yang_genrule(
            name = "yang_{}".format(stem.replace("/", "_").replace("-", "_")),
            src = src_path,
            outname = "frr/{}.yang.c".format(stem),
            embedmodel = "frr/yang/embedmodel.py",
        )

    native.cc_library(
        name = "{}_v_hdrs".format(name),
        hdrs = native.glob(["frr/{}/*.h".format(name)]),
        strip_include_prefix = "frr/{}".format(name),
        visibility = ["//visibility:private"],
    )
    native.cc_library(
        name = "{}_q_hdrs".format(name),
        hdrs = native.glob(["frr/{}/*.h".format(name)]),
        strip_include_prefix = "frr",
        visibility = ["//visibility:private"],
    )

    if clippy_sources:
        native.cc_library(
            name = "{}_clippy_textual_hdrs".format(name),
            textual_hdrs = [":{}_{}_clippy".format(name, c) for c in clippy_sources],
            visibility = ["//visibility:private"],
        )
        clippy_dep = [":{}_clippy_textual_hdrs".format(name)]
    else:
        clippy_dep = []

    own_yang_srcs = [
        ":yang_{}".format(stem.replace("/", "_").replace("-", "_"))
        for stem, _ in yang_models
    ]
    nodist_yang_srcs = [
        ":yang_{}".format(stem.replace("/", "_").replace("-", "_"))
        for stem in nodist_yang
    ]

    native.cc_binary(
        name = name,
        srcs = sources + own_yang_srcs + nodist_yang_srcs,
        deps = [
            ":{}_v_hdrs".format(name),
            ":{}_q_hdrs".format(name),
        ] + clippy_dep + _FRR_DAEMON_BASE_DEPS + extra_deps,
        dynamic_deps = _FRR_DAEMON_DYNAMIC_DEPS + extra_dynamic_deps,
        copts = _FRR_DAEMON_COPTS + extra_copts,
        linkopts = _FRR_DAEMON_LINKOPTS + extra_linkopts,
        visibility = ["//visibility:public"],
    )
