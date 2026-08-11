"""apt_tree — unpack apt `:data` payload tars into a directory output.

genrule only keeps the outputs it declares, so copying a whole deb payload out
of a tar needs either an exhaustive `outs` list (what src/libyang3-py3 does for
its five .so) or a directory output. python3-dbus + python3-gi ship ~54 files
between them, so declare a directory and let the action fill it.

The `strip` argument is the prefix inside the payload to lift to the root of
the output, e.g. "usr/lib/python3/dist-packages" for python packages or
"usr/lib/x86_64-linux-gnu" for shared libraries.
"""

def _apt_tree_impl(ctx):
    out = ctx.actions.declare_directory(ctx.attr.dirname or ctx.label.name)
    ctx.actions.run_shell(
        inputs = ctx.files.tars,
        outputs = [out],
        command = """
set -e
work=$(mktemp -d)
for t in "$@"; do tar -xzf "$t" -C "$work"; done
# -L: materialise symlink targets, the runfiles copy must stand alone.
cp -rL "$work/{strip}/." "{out}/"
rm -rf "$work"
""".format(strip = ctx.attr.strip, out = out.path),
        arguments = [f.path for f in ctx.files.tars],
        mnemonic = "AptTree",
        progress_message = "Unpacking %s" % ctx.label,
    )
    return [DefaultInfo(files = depset([out]))]

apt_tree = rule(
    implementation = _apt_tree_impl,
    attrs = {
        "tars": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "apt `:data` targets (content.tar.gz) to unpack.",
        ),
        "strip": attr.string(
            mandatory = True,
            doc = "Path inside the payload whose contents become the output root.",
        ),
        "dirname": attr.string(
            doc = "Output directory name; defaults to the target name.",
        ),
    },
)
