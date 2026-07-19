# Bazel build for libpsample 1.1-1 (commit e48fad2).
#
# Upstream is a CMake project producing:
#   * libpsample.so.1.0 (SONAME libpsample.so.1) from src/psample.c + src/mnlg.c,
#     linked against libmnl.
#   * a psample_tool CLI (output name "psample") from psample_tool/psample.c.
# Reproduced natively: sonic_shared_library_versioned for the versioned .so +
# symlink chain, and a cc_binary for the tool (renamed to "psample").

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@sonic_build_infra//shared_library:shared_library.bzl", "sonic_shared_library_versioned")

package(default_visibility = ["//visibility:public"])

# libpsample.so.1.0 + symlinks (.so -> .so.1 -> .so.1.0). soversion 1, version 1.0.
sonic_shared_library_versioned(
    name = "psample",
    srcs = [
        "src/psample.c",
        "src/mnlg.c",
    ],
    hdrs = [
        "include/psample.h",
        "src/mnlg.h",
    ],
    copts = [
        "-D_GNU_SOURCE",
        "-Wno-unused-parameter",
    ],
    includes = [
        "include",
        "src",
    ],
    output_name = "libpsample",
    soversion = "1",
    version = "1.0",
    visibility = ["//visibility:public"],
    deps = [
        "@sflow_deps//libmnl-dev:libmnl",
    ],
)

# psample CLI tool. Links the psample library (static CcInfo path) which pulls
# in its transitive libmnl dependency. Output file renamed to "psample".
cc_binary(
    name = "psample_tool",
    srcs = ["psample_tool/psample.c"],
    copts = [
        "-D_GNU_SOURCE",
        "-Wno-unused-parameter",
    ],
    deps = [":psample"],
)

genrule(
    name = "psample_bin",
    srcs = [":psample_tool"],
    outs = ["bin/psample"],
    cmd = "cp $< $@",
)

# man page: gzip -9n for reproducibility.
genrule(
    name = "psample_man_gz",
    srcs = ["man/psample.8"],
    outs = ["psample.8.gz"],
    cmd = "gzip -9nc $< > $@",
)
