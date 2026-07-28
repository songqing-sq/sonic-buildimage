"""Source exposure for pam_radius (FreeRADIUS pam_radius @149c25df).

The tarball is patched by the four SONiC patches in debian/patches/, which add
CHAP, PEAP-MSCHAPv2, NAS-IP-Address config and the BlastRADIUS fix. Three of the
six compiled sources only exist after patching (mschapv2.c, radpeapclient.c,
pam_radius_stats.c), so the source list here assumes the patched tree.

Only file groups live here; compilation is in the libpam-radius-auth module,
which supplies the generated config.h.
"""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

# Declared here so the -I lands on this repo's root (see freeradius_src.BUILD).
cc_library(
    name = "hdrs_lib",
    hdrs = glob(
        ["src/*.h"],
        allow_empty = False,
    ),
    includes = ["src"],
)

# Matches the .o set of Make's build exactly. pam_radius_stats.c,
# radpeapclient.c and mschapv2.c are introduced by the SONiC patches.
filegroup(
    name = "srcs",
    srcs = [
        "src/md5.c",
        "src/mschapv2.c",
        "src/pam_radius_auth.c",
        "src/pam_radius_stats.c",
        "src/pam_radius_trace.c",
        "src/radpeapclient.c",
    ],
)

filegroup(
    name = "hdrs",
    srcs = glob(
        ["src/*.h"],
        allow_empty = False,
    ),
)

exports_files([
    "src/config.h.in",
    # Added by 0003-nas-ip-address-config.patch (the logrotate config for
    # /var/log/pam_radius_trace.log).
    "pam_radius",
    "pam_radius_auth.conf",
    "USAGE",
    "README.rst",
])
