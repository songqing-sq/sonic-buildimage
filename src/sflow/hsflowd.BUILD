# Bazel build for hsflowd (host-sflow) 2.0.51-26, SONiC feature set.
#
# Upstream tarball fetched via sonic_http_archive (see ../MODULE.bazel).
# Approach B (cc-rebuild): the upstream src/Linux/Makefile is NOT invoked.
# Instead the SONiC build recipe `make hsflowd FEATURES=SONIC` is reproduced
# with native cc rules:
#   FEATURES_SONIC = SONIC PSAMPLE DOCKER DROPMON  (+ always-built json,dnssd)
#   => 6 loadable modules under /etc/hsflowd/modules/.
#
# The common CFLAGS below are the SONIC branch of the upstream Makefile:
#   CFLAGS = -I. -I../json -I../sflow -DHSP_LOAD_SONIC -fPIC $(OPT)
#            -D_GNU_SOURCE -DHSP_VERSION=2.0.51
#            -DPROCFS=/proc -DSYSFS=/sys -DETCFS=/etc -DVARFS=/var
#            -DUTHEAP -DHSP_OPTICAL_STATS -DHSP_MOD_DIR=/etc/hsflowd/modules
# Include dirs are provided via the `includes` attribute of :hsflowd_headers
# (relative to the external repo root -- copts -I would not resolve for an
# external repo).

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

# Common compile flags shared by the daemon and every module (SONIC branch).
HSFLOWD_COPTS = [
    "-std=gnu99",
    "-fPIC",
    "-D_GNU_SOURCE",
    "-DHSP_VERSION=2.0.51",
    "-DPROCFS=/proc",
    "-DSYSFS=/sys",
    "-DETCFS=/etc",
    "-DVARFS=/var",
    "-DUTHEAP",
    "-DHSP_OPTICAL_STATS",
    "-DHSP_MOD_DIR=/etc/hsflowd/modules",
    "-DHSP_LOAD_SONIC",
    # Upstream source triggers these warnings heavily; they are non-fatal.
    "-Wno-unused-parameter",
    "-Wno-unused-variable",
    "-Wno-unused-but-set-variable",
    "-Wno-deprecated-declarations",
]

# All headers + include search paths (src/Linux, src/json, src/sflow). The
# `includes` attribute makes these resolve correctly for the external repo.
cc_library(
    name = "hsflowd_headers",
    hdrs = glob([
        "src/Linux/*.h",
        "src/Linux/linux/*.h",
        "src/json/*.h",
        "src/sflow/*.h",
    ]),
    includes = [
        "src/Linux",
        "src/json",
        "src/sflow",
    ],
)

# libsflow.a -- the sFlow protocol library (src/sflow/*.c), built -O3 -DNDEBUG
# per the upstream src/sflow/Makefile.
cc_library(
    name = "libsflow",
    srcs = glob(["src/sflow/*.c"]),
    copts = [
        "-D_GNU_SOURCE",
        "-DSTDC_HEADERS",
        "-O3",
        "-DNDEBUG",
        "-Wno-unused-parameter",
        "-Wno-unused-variable",
    ],
    deps = [":hsflowd_headers"],
)

# libcjson.a -- only cJSON.o (cJSON_Utils is not used by hsflowd).
cc_library(
    name = "libcjson",
    srcs = ["src/json/cJSON.c"],
    copts = [
        "-D_GNU_SOURCE",
        "-Wno-unused-parameter",
    ],
    deps = [":hsflowd_headers"],
)

# =============================================================================
# hsflowd daemon -> /usr/sbin/hsflowd
# LIBS_HSFLOWD = libcjson.a libsflow.a -lm -pthread -ldl -lrt ; LDFLAGS -rdynamic
# =============================================================================
cc_binary(
    name = "hsflowd",
    srcs = [
        "src/Linux/hsflowconfig.c",
        "src/Linux/hsflowd.c",
        "src/Linux/evbus.c",
        "src/Linux/util.c",
        "src/Linux/readInterfaces.c",
        "src/Linux/readCpuCounters.c",
        "src/Linux/readMemoryCounters.c",
        "src/Linux/readDiskCounters.c",
        "src/Linux/readHidCounters.c",
        "src/Linux/readNioCounters.c",
        "src/Linux/readTcpipCounters.c",
        "src/Linux/readPackets.c",
    ],
    copts = HSFLOWD_COPTS,
    linkopts = [
        "-rdynamic",
        "-lm",
        "-pthread",
        "-ldl",
        "-lrt",
    ],
    deps = [
        ":hsflowd_headers",
        ":libsflow",
        ":libcjson",
    ],
)

# =============================================================================
# Loadable modules -> /etc/hsflowd/modules/*.so
# Each is a shared object (dlopen'd by the daemon). Symbols provided by the
# daemon (exported via -rdynamic) are left undefined at link time, which is the
# default for cc_binary(linkshared=True) -- no -Wl,-z,defs is added.
# =============================================================================
cc_binary(
    name = "mod_json.so",
    srcs = ["src/Linux/mod_json.c"],
    copts = HSFLOWD_COPTS,
    linkshared = True,
    deps = [":hsflowd_headers"],
)

cc_binary(
    name = "mod_dnssd.so",
    srcs = ["src/Linux/mod_dnssd.c"],
    copts = HSFLOWD_COPTS,
    linkopts = ["-lresolv"],
    linkshared = True,
    deps = [":hsflowd_headers"],
)

cc_binary(
    name = "mod_docker.so",
    srcs = ["src/Linux/mod_docker.c"],
    copts = HSFLOWD_COPTS,
    linkopts = ["-lm"],
    linkshared = True,
    deps = [":hsflowd_headers"],
)

cc_binary(
    name = "mod_dropmon.so",
    srcs = [
        "src/Linux/mod_dropmon.c",
        "src/Linux/util_netlink.c",
    ],
    copts = HSFLOWD_COPTS,
    linkshared = True,
    deps = [":hsflowd_headers"],
)

cc_binary(
    name = "mod_psample.so",
    srcs = [
        "src/Linux/mod_psample.c",
        "src/Linux/util_netlink.c",
    ],
    copts = HSFLOWD_COPTS,
    linkshared = True,
    deps = [":hsflowd_headers"],
)

cc_binary(
    name = "mod_sonic.so",
    srcs = ["src/Linux/mod_sonic.c"],
    copts = HSFLOWD_COPTS,
    linkshared = True,
    deps = [
        ":hsflowd_headers",
        "@sflow_deps//libhiredis-dev:libhiredis",
    ],
)

# =============================================================================
# Data files (from src/Linux/scripts/, after patches applied).
#   - /etc/hsflowd.conf              <- scripts/hsflowd.conf.sonic (SONIC)
#   - /etc/init.d/hsflowd            <- scripts/hsflowd.deb  (DEBIAN init script)
#   - /lib/systemd/system/...service <- scripts/hsflowd.service
#   - /etc/dbus-1/.../...conf        <- scripts/net.sflow.hsflowd.conf
# =============================================================================
genrule(
    name = "etc_hsflowd_conf",
    srcs = ["src/Linux/scripts/hsflowd.conf.sonic"],
    outs = ["hsflowd.conf"],
    cmd = "cp $< $@",
)

genrule(
    name = "etc_initd_hsflowd",
    srcs = ["src/Linux/scripts/hsflowd.deb"],
    outs = ["initd/hsflowd"],
    cmd = "cp $< $@",
)

filegroup(
    name = "hsflowd_service",
    srcs = ["src/Linux/scripts/hsflowd.service"],
)

filegroup(
    name = "dbus_conf",
    srcs = ["src/Linux/scripts/net.sflow.hsflowd.conf"],
)
