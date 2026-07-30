"""Source exposure for the lm-sensors 3.6.0 tarball.

Only the pieces the sensord build needs live here. `includes` paths are resolved
relative to the package that declares them, so the header cc_library has to be
in this repo rather than in the lm-sensors module.

debian/sensord.default and debian/sensord.init do not exist in Debian's
lm-sensors packaging -- they are created by SONiC's
patch/0001-patch-the-debian-package-info-to-get-sensord.patch, which
debian_source applies after debian/patches/series.
"""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "sensord_hdrs",
    hdrs = [
        "lib/error.h",
        "lib/sensors.h",
        "prog/sensord/args.h",
        "prog/sensord/sensord.h",
        "version.h",
    ],
    # sensord's sources include both `"lib/sensors.h"` (repo-root relative) and
    # `"sensord.h"` (sibling relative).
    includes = [
        ".",
        "prog/sensord",
    ],
)

# prog/sensord/Module.mk SENSORDSOURCES.
filegroup(
    name = "sensord_srcs",
    srcs = [
        "prog/sensord/args.c",
        "prog/sensord/chips.c",
        "prog/sensord/lib.c",
        "prog/sensord/rrd.c",
        "prog/sensord/sense.c",
        "prog/sensord/sensord.c",
    ],
)

exports_files([
    "debian/sensord.default",
    "debian/sensord.init",
])
