"""Source view of the patched pam_tacplus tree.

Header search paths are expressed as cc_library targets carrying `hdrs` +
`strip_include_prefix`, so consumers pick them up transitively through deps —
no -I flags anywhere. Compilation itself is wired in //:BUILD.bazel; autotools
is not used, and config.h is written there to match what configure resolves to
on glibc/trixie.
"""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

exports_files(glob(["**"]))

filegroup(
    name = "all",
    srcs = glob(["**"]),
)

filegroup(
    name = "libtac_srcs",
    srcs = glob(
        ["libtac/lib/*.c"],
        allow_empty = False,
    ),
)

# libtac's public API (libtac_la_CFLAGS: -I libtac/include).
cc_library(
    name = "libtac_headers",
    hdrs = glob(["libtac/include/*.h"]),
    strip_include_prefix = "libtac/include",
)

# libtac's internal headers, included unqualified by its own .c files.
cc_library(
    name = "libtac_private_headers",
    hdrs = glob(["libtac/lib/*.h"]),
    strip_include_prefix = "libtac/lib",
)

# The top-level headers (support.h / pam_tacplus.h), included unqualified by
# support.c, pam_tacplus.c and tacc.c.
cc_library(
    name = "top_headers",
    hdrs = [
        "pam_tacplus.h",
        "support.h",
    ],
)
