"""Source view of the patched libnss-tacplus tree.

Header search paths ride on cc_library targets rather than -I flags; the build
itself lives in //:BUILD.bazel and uses native cc rules, not autotools.
"""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

exports_files(glob(["**"]))

cc_library(
    name = "nss_tacplus_headers",
    hdrs = ["nss_tacplus.h"],
)
