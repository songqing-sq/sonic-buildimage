"""deb_modules_tree: extract the kernel modules tree from a linux-image deb
as a Bazel tree artifact (declare_directory), rooted so it contains
lib/modules/<kversion>/... — the layout initramfs's `modules_tree` expects
(the `make modules_install` PREFIX shape)."""

def _deb_modules_tree_impl(ctx):
    out = ctx.actions.declare_directory(ctx.attr.out_dir)
    ctx.actions.run_shell(
        inputs = [ctx.file.deb],
        outputs = [out],
        command = (
            "set -e; d=$(mktemp -d); " +
            "dpkg-deb -x '{deb}' \"$d\"; " +
            "mkdir -p '{out}/lib/modules'; " +
            # trixie linux-image ships modules under usr/lib/modules (merged-usr);
            # normalize to lib/modules/<kver> which is what consumers expect.
            "cp -a \"$d\"/usr/lib/modules/{kver} '{out}/lib/modules/'; " +
            "rm -rf \"$d\""
        ).format(deb = ctx.file.deb.path, out = out.path, kver = ctx.attr.kversion),
        mnemonic = "DebModulesTree",
        progress_message = "Extracting modules tree from %s" % ctx.file.deb.basename,
    )
    return [DefaultInfo(files = depset([out]))]

deb_modules_tree = rule(
    implementation = _deb_modules_tree_impl,
    attrs = {
        "deb": attr.label(allow_single_file = True, mandatory = True),
        "kversion": attr.string(mandatory = True),
        "out_dir": attr.string(default = "modules_install"),
    },
)
