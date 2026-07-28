"""Source exposure for the rasdaemon 0.6.8 salsa snapshot.

Header cc_libraries live here rather than in the rasdaemon module because
`includes` paths resolve relative to the declaring package.
"""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "hdrs_lib",
    hdrs = glob(
        [
            "*.h",
            "libtrace/*.h",
        ],
        allow_empty = False,
    ),
    includes = [
        ".",
        "libtrace",
    ],
)

# Makefile.am rasdaemon_SOURCES with the WITH_* conditionals resolved to
# debian/rules' flag set (mce, aer, sqlite3, extlog, abrt-report). Notably
# --enable-arm is deliberately absent: debian/rules records that it is
# experimental and does not compile.
filegroup(
    name = "rasdaemon_srcs",
    srcs = [
        "bitfield.c",
        "mce-amd-k8.c",
        "mce-amd-smca.c",
        "mce-amd.c",
        "mce-intel-broadwell-de.c",
        "mce-intel-broadwell-epex.c",
        "mce-intel-dunnington.c",
        "mce-intel-haswell.c",
        "mce-intel-i10nm.c",
        "mce-intel-ivb.c",
        "mce-intel-knl.c",
        "mce-intel-nehalem.c",
        "mce-intel-p4-p6.c",
        "mce-intel-sb.c",
        "mce-intel-skylake-xeon.c",
        "mce-intel-tulsa.c",
        "mce-intel.c",
        "ras-aer-handler.c",
        "ras-events.c",
        "ras-extlog-handler.c",
        "ras-mc-handler.c",
        "ras-mce-handler.c",
        "ras-record.c",
        "ras-report.c",
        "rasdaemon.c",
    ],
)

# libtrace/Makefile.am — the bundled copy of the kernel's trace event parser.
filegroup(
    name = "libtrace_srcs",
    srcs = [
        "libtrace/event-parse.c",
        "libtrace/kbuffer-parse.c",
        "libtrace/parse-filter.c",
        "libtrace/parse-utils.c",
        "libtrace/trace-seq.c",
    ],
)

exports_files([
    "util/ras-mc-ctl.in",
    "misc/rasdaemon.service.in",
    "misc/ras-mc-ctl.service.in",
    "misc/rasdaemon.env",
    "debian/rasdaemon.init",
])
