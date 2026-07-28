"""Source view of the patched audisp-tacplus tree.

Header paths ride on a cc_library rather than -I flags; the build itself lives
in //:BUILD.bazel and uses native cc rules, not autotools.
"""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

exports_files(glob(["**"]))

cc_library(
    name = "local_headers",
    hdrs = glob(["*.h"]),
    # The sources include these unqualified (trace.h, password.h, ...), so put
    # the repo root on the include path via the attribute rather than a -I.
    includes = ["."],
)
