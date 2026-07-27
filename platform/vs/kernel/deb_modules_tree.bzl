"""deb_modules_tree: extract the kernel modules tree from a linux-image deb
as a Bazel tree artifact (declare_directory).

Two shapes:
  flat = False (default): tree contains lib/modules/<kversion>/... — for
      laying directly into a rootfs.
  flat = True: tree root IS the contents of lib/modules/<kversion>/ — the
      shape initramfs_real's mkinitramfs_build.sh expects (it does
      `cp -RL "$MODULES_TREE/." "$STAGE/lib/modules/$KVER/"`).
"""

def _deb_modules_tree_impl(ctx):
    out = ctx.actions.declare_directory(ctx.attr.out_dir)
    if ctx.attr.flat:
        copy = "cp -a \"$d\"/usr/lib/modules/{kver}/. '{out}/'; "
    else:
        copy = "mkdir -p '{out}/lib/modules'; cp -a \"$d\"/usr/lib/modules/{kver} '{out}/lib/modules/'; "
    ctx.actions.run_shell(
        inputs = [ctx.file.deb],
        outputs = [out],
        command = (
            "set -e; d=$(mktemp -d); " +
            "dpkg-deb -x '{deb}' \"$d\"; " +
            # trixie linux-image ships modules under usr/lib/modules (merged-usr);
            # normalize away the usr/ prefix.
            copy +
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
        "flat": attr.bool(default = False),
    },
)
