"""Source exposure for the makedumpfile 1.7.7 tarball."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "hdrs_lib",
    hdrs = glob(
        ["*.h"],
        allow_empty = False,
    ),
    includes = ["."],
)

# Makefile SRC_BASE + SRC_PART. extension_eppic.c is excluded: it builds the
# separate eppic_makedumpfile.so, which the deb does not ship.
filegroup(
    name = "srcs",
    srcs = [
        "cache.c",
        "detect_cycle.c",
        "dwarf_info.c",
        "elf_info.c",
        "erase_info.c",
        "makedumpfile.c",
        "print_info.c",
        "printk.c",
        "sadump_info.c",
        "tools.c",
    ],
)

# Makefile SRC_ARCH. Every arch is compiled in (they are guarded internally by
# the target's __<arch>__ define), matching the upstream build.
filegroup(
    name = "arch_srcs",
    srcs = [
        "arch/arm.c",
        "arch/arm64.c",
        "arch/ia64.c",
        "arch/loongarch64.c",
        "arch/mips64.c",
        "arch/ppc.c",
        "arch/ppc64.c",
        "arch/riscv64.c",
        "arch/s390x.c",
        "arch/sparc64.c",
        "arch/x86.c",
        "arch/x86_64.c",
    ],
)

exports_files([
    "makedumpfile-R.pl",
    "makedumpfile.conf",
])
