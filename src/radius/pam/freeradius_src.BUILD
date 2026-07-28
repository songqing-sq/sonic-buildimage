"""Source exposure for FreeRADIUS 1.1.8's libradius and libeap.

pam_radius_auth.so links both (confirmed in its DT_NEEDED), so they are built
here rather than taken from Debian — trixie has no freeradius 1.1.8.

Only file groups live here; compilation is in the libpam-radius-auth module.
The upstream build runs ./configure + libtool; this compiles the two libraries
directly, so the generated autoconf.h is supplied by the caller.
"""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

# Declared HERE rather than in the libpam-radius-auth module: `includes` paths
# are resolved relative to the package declaring them, so a cc_library in the
# module would put the -I on the module's root, where these headers do not live.
cc_library(
    name = "hdrs_lib",
    hdrs = glob(
        [
            "src/include/*.h",
            "src/lib/*.h",
            "src/modules/rlm_eap/*.h",
            "src/modules/rlm_eap/libeap/*.h",
        ],
        allow_empty = False,
    ),
    includes = [
        "src/include",
        "src/modules/rlm_eap",
        "src/modules/rlm_eap/libeap",
    ],
)

# src/lib/*.c — libradius. Matches the .o set of Make's build exactly.
filegroup(
    name = "libradius_srcs",
    srcs = [
        "src/lib/crypt.c",
        "src/lib/dict.c",
        "src/lib/filters.c",
        "src/lib/hash.c",
        "src/lib/hmac.c",
        "src/lib/hmacsha1.c",
        "src/lib/isaac.c",
        "src/lib/log.c",
        "src/lib/md4.c",
        "src/lib/md5.c",
        "src/lib/misc.c",
        "src/lib/missing.c",
        "src/lib/print.c",
        "src/lib/radius.c",
        "src/lib/rbtree.c",
        "src/lib/sha1.c",
        "src/lib/snprintf.c",
        "src/lib/token.c",
        "src/lib/udpfromto.c",
        "src/lib/valuepair.c",
    ],
)

# src/modules/rlm_eap/libeap/*.c — libeap. Matches the .o set of Make's build.
filegroup(
    name = "libeap_srcs",
    srcs = [
        "src/modules/rlm_eap/libeap/cb.c",
        "src/modules/rlm_eap/libeap/eap_tls.c",
        "src/modules/rlm_eap/libeap/eapcommon.c",
        "src/modules/rlm_eap/libeap/eapcrypto.c",
        "src/modules/rlm_eap/libeap/eapsimlib.c",
        "src/modules/rlm_eap/libeap/fips186prf.c",
        "src/modules/rlm_eap/libeap/mppe_keys.c",
        "src/modules/rlm_eap/libeap/tls.c",
    ],
)

filegroup(
    name = "hdrs",
    srcs = glob(
        [
            "src/include/*.h",
            "src/lib/*.h",
            "src/modules/rlm_eap/*.h",
            "src/modules/rlm_eap/libeap/*.h",
        ],
        allow_empty = False,
    ),
)

# The RADIUS attribute dictionaries libradius' dict.c reads at runtime.
filegroup(
    name = "dictionaries",
    srcs = glob(
        ["share/dictionary*"],
        allow_empty = True,
    ),
)

exports_files(["src/include/autoconf.h.in"])
