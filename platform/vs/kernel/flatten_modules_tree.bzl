"""flatten_modules_tree: re-root a kernel modules tree.

The kernel build emits lib/modules/<kversion>/... (the `make modules_install`
PREFIX shape). The initramfs rule instead wants a tree whose ROOT is the
CONTENTS of lib/modules/<kversion>/, because its builder does
`cp -RL "$MODULES_TREE/." "$STAGE/lib/modules/$KVER/"`. This rule bridges the
two by declaring a directory output and copying the inner subtree into it.
"""

def _flatten_modules_tree_impl(ctx):
    out = ctx.actions.declare_directory(ctx.attr.out_dir)
    src = ctx.file.modules_tree
    ctx.actions.run_shell(
        inputs = [src],
        outputs = [out],
        command = "cp -a '{src}/lib/modules/{kver}/.' '{out}/'".format(
            src = src.path,
            kver = ctx.attr.kversion,
            out = out.path,
        ),
        mnemonic = "FlattenModulesTree",
        progress_message = "Re-rooting kernel modules tree for %s" % ctx.attr.kversion,
    )
    return [DefaultInfo(files = depset([out]))]

flatten_modules_tree = rule(
    implementation = _flatten_modules_tree_impl,
    attrs = {
        "modules_tree": attr.label(allow_single_file = True, mandatory = True),
        "kversion": attr.string(mandatory = True),
        "out_dir": attr.string(default = "modules_flat_dir"),
    },
)
