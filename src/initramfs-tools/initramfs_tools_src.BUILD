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
