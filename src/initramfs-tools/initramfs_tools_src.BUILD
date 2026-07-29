"""Source-tree view of the patched upstream initramfs-tools v0.142.

The @initramfs_tools_src repo holds the salsa tarball with SONiC's two
loopback patches already applied (see MODULE.bazel). This BUILD only needs to
expose the files the two debs install; the layout mapping itself lives in
//:BUILD.bazel, driven by debian/*.install.
"""

package(default_visibility = ["//visibility:public"])

exports_files(glob(["**"]))

filegroup(
    name = "all",
    srcs = glob(["**"]),
)

# initramfs-tools-core content (debian/initramfs-tools-core.install).
filegroup(
    name = "core_scripts",
    srcs = glob(["scripts/**"]),
)

filegroup(
    name = "core_hooks",
    srcs = glob(["hooks/**"]),
)

# `kernel  etc` in debian/initramfs-tools.install: the kernel/{postinst,postrm}.d
# hooks that rebuild/remove the initrd when a kernel package is (un)installed.
filegroup(
    name = "kernel_postinst_d",
    srcs = glob(["kernel/postinst.d/*"]),
)

filegroup(
    name = "kernel_postrm_d",
    srcs = glob(["kernel/postrm.d/*"]),
)
