"""Helper: copy yang_hdr_files into an `include/libyang/` tree artifact.

cc_library doesn't accept `srcs` as raw files for headers, and a regular
genrule can't enumerate outputs at load time. So we declare a single tree
artifact directory output and emit all headers under it. cc_library can
then point at `include/` via `includes = ["include"]` and gcc finds them
under the `libyang/` subdir.
"""

def _libyang_headers_tree_impl(ctx):
    tree = ctx.actions.declare_directory("include/libyang")
    inputs = ctx.files.hdrs

    cmds = [
        "set -e",
        'out="{}"'.format(tree.path),
        'mkdir -p "$out"',
    ]
    for h in inputs:
        cmds.append('cp "{}" "$out/"'.format(h.path))

    ctx.actions.run_shell(
        command = "\n".join(cmds),
        inputs = inputs,
        outputs = [tree],
        mnemonic = "LibyangHdrs",
    )
    return [DefaultInfo(files = depset([tree]))]

libyang_headers_tree = rule(
    implementation = _libyang_headers_tree_impl,
    attrs = {
        "hdrs": attr.label_list(allow_files = [".h"]),
    },
)
