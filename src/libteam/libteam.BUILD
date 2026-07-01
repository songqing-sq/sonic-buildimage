# Bazel build for libteam 1.31-1 (SONiC patched), Linux/amd64+arm64.
#
# Upstream tarball fetched via sonic_http_archive (see ../MODULE.bazel).
# SONiC StGit patches from src/libteam/patch/series applied at fetch time
# via sonic_http_archive's patch_tool="patch".
#
# Configure-equivalent feature set (matches what Debian's debian/rules + the
# Debian build would produce on trixie):
#   --user=root --group=root --enable-dbus --disable-zmq
#
# Library versions derived from configure.ac:
#   libteam:    CURRENT=11 REVISION=1 AGE=6
#               -> soname.so.5, full .so.5.6.1
#   libteamdctl:CURRENT=1  REVISION=5 AGE=1
#               -> soname.so.0, full .so.0.1.5

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@bazel_skylib//rules:expand_template.bzl", "expand_template")
load("@sonic_build_infra//shared_library:shared_library.bzl", "sonic_shared_library_versioned")

package(default_visibility = ["//visibility:public"])

LIBTEAM_SOVERSION = "5"
LIBTEAM_FULL_SOVERSION = "5.6.1"

LIBTEAMDCTL_SOVERSION = "0"
LIBTEAMDCTL_FULL_SOVERSION = "0.1.5"

# =============================================================================
# Compiler flags. Mirrors Makefile.am AM_CFLAGS for the library targets and
# the documented build env (-D_GNU_SOURCE for *.c + JANSSON / DBUS / LIBDAEMON
# headers).
# =============================================================================
COPTS_LIB = [
    "-fvisibility=hidden",
    "-ffunction-sections",
    "-fdata-sections",
    "-D_GNU_SOURCE",
    "-Wall",
]

COPTS_BIN = [
    "-D_GNU_SOURCE",
    "-Wall",
]

# =============================================================================
# Generated config.h (replaces autoheader-generated header). Hand-written
# template is symlinked in by sonic_http_archive extra_files.
# =============================================================================
expand_template(
    name = "config_h",
    template = "config.h.tpl",
    out = "config.h",
    substitutions = {},
)

# Provide config.h via a cc_library so dependents pull both the header and its
# include path (sources do `#include "config.h"`).
cc_library(
    name = "config_h_hdr",
    hdrs = [":config_h"],
    includes = ["."],
)

# pkgconfig + dbus policy files shipped by libteam-dev / libteam-utils.
expand_template(
    name = "libteam_pc",
    template = "libteam/libteam.pc.in",
    out = "libteam.pc",
    substitutions = {
        "@prefix@": "/usr",
        "@exec_prefix@": "/usr",
        "@libdir@": "${LIBDIR}",
        "@includedir@": "/usr/include",
        "@PACKAGE_VERSION@": "1.31",
    },
)

expand_template(
    name = "libteamdctl_pc",
    template = "libteamdctl/libteamdctl.pc.in",
    out = "libteamdctl.pc",
    substitutions = {
        "@prefix@": "/usr",
        "@exec_prefix@": "/usr",
        "@libdir@": "${LIBDIR}",
        "@includedir@": "/usr/include",
        "@PACKAGE_VERSION@": "1.31",
    },
)

expand_template(
    name = "teamd_conf",
    template = "teamd/teamd.conf.in",
    out = "teamd.conf",
    substitutions = {
        "@teamd_user@": "root",
    },
)

# =============================================================================
# libteam.so.5.6.1
# =============================================================================
LIBTEAM_SRCS = [
    "libteam/libteam.c",
    "libteam/ports.c",
    "libteam/options.c",
    "libteam/ifinfo.c",
    "libteam/stringify.c",
]

LIBTEAM_PRIVATE_HDRS = [
    "libteam/team_private.h",
    "libteam/nl_updates.h",
]

LIBTEAM_PUBLIC_HDRS = [
    "include/team.h",
]

LIBTEAM_VENDORED_HDRS = [
    "include/linux/if_team.h",
    "include/linux/filter.h",
    "include/linux/tipc.h",
    "include/private/list.h",
    "include/private/misc.h",
]

sonic_shared_library_versioned(
    name = "libteam",
    srcs = LIBTEAM_SRCS,
    hdrs = LIBTEAM_PRIVATE_HDRS + LIBTEAM_PUBLIC_HDRS + LIBTEAM_VENDORED_HDRS,
    includes = ["include", "libteam"],
    copts = COPTS_LIB,
    deps = [
        ":config_h_hdr",
        "@libnl3//:libnl_3",
        "@libnl3//:libnl_genl_3",
        "@libnl3//:libnl_route_3",
        "@libnl3//:libnl_cli_3",
        "@libteam_deps//libdaemon-dev:libdaemon",
    ],
    dynamic_deps = [
        "@libnl3//:libnl_3_shared",
        "@libnl3//:libnl_genl_3_shared",
        "@libnl3//:libnl_route_3_shared",
        "@libnl3//:libnl_cli_3_shared",
    ],
    soversion = LIBTEAM_SOVERSION,
    version = LIBTEAM_FULL_SOVERSION,
    output_name = "libteam",
    visibility = ["//visibility:public"],
)

# =============================================================================
# libteamdctl.so.0.1.5
# =============================================================================
LIBTEAMDCTL_SRCS = [
    "libteamdctl/libteamdctl.c",
    "libteamdctl/cli_usock.c",
    "libteamdctl/cli_dbus.c",
    "libteamdctl/cli_zmq.c",
]

LIBTEAMDCTL_PRIVATE_HDRS = [
    "libteamdctl/teamdctl_private.h",
    # cli_usock.c / cli_dbus.c / cli_zmq.c include `../teamd/teamd_*_common.h`
    # plus teamd_usock_common.h transitively pulls teamd.h, teamd_utldll.h,
    # teamd_utlhash.h.
    "teamd/teamd_usock_common.h",
    "teamd/teamd_dbus_common.h",
    "teamd/teamd_zmq_common.h",
    "teamd/teamd.h",
]

LIBTEAMDCTL_PUBLIC_HDRS = [
    "include/teamdctl.h",
]

sonic_shared_library_versioned(
    name = "libteamdctl",
    srcs = LIBTEAMDCTL_SRCS,
    hdrs = LIBTEAMDCTL_PRIVATE_HDRS + LIBTEAMDCTL_PUBLIC_HDRS + LIBTEAM_PUBLIC_HDRS + LIBTEAM_VENDORED_HDRS,
    includes = ["include"],
    copts = COPTS_LIB,
    deps = [
        ":config_h_hdr",
        "@libteam_deps//libdbus-1-dev:libdbus-1",
        "@libteam_deps//libdaemon-dev:libdaemon",
        "@libteam_deps//libjansson-dev:libjansson",
    ],
    soversion = LIBTEAMDCTL_SOVERSION,
    version = LIBTEAMDCTL_FULL_SOVERSION,
    output_name = "libteamdctl",
    visibility = ["//visibility:public"],
)

# =============================================================================
# teamnl binary
# =============================================================================
cc_binary(
    name = "teamnl",
    srcs = ["utils/teamnl.c"],
    copts = COPTS_BIN,
    dynamic_deps = [
        ":libteam_shared",
        "@libnl3//:libnl_3_shared",
        "@libnl3//:libnl_genl_3_shared",
        "@libnl3//:libnl_route_3_shared",
        "@libnl3//:libnl_nf_3_shared",
        "@libnl3//:libnl_cli_3_shared",
    ],
    deps = [
        ":libteam_hdrs",
    ],
)

# =============================================================================
# teamdctl binary
# =============================================================================
cc_binary(
    name = "teamdctl",
    srcs = ["utils/teamdctl.c"],
    copts = COPTS_BIN,
    dynamic_deps = [
        ":libteamdctl_shared",
    ],
    deps = [
        ":config_h_hdr",
        ":libteamdctl_hdrs",
        "@libteam_deps//libjansson-dev:libjansson",
        "@libteam_deps//libdbus-1-dev:libdbus-1",
    ],
)

# =============================================================================
# teamd binary
# =============================================================================
TEAMD_SRCS = [
    "teamd/teamd.c",
    "teamd/teamd_common.c",
    "teamd/teamd_json.c",
    "teamd/teamd_config.c",
    "teamd/teamd_state.c",
    "teamd/teamd_workq.c",
    "teamd/teamd_events.c",
    "teamd/teamd_per_port.c",
    "teamd/teamd_option_watch.c",
    "teamd/teamd_ifinfo_watch.c",
    "teamd/teamd_lw_ethtool.c",
    "teamd/teamd_lw_psr.c",
    "teamd/teamd_lw_arp_ping.c",
    "teamd/teamd_lw_nsna_ping.c",
    "teamd/teamd_lw_tipc.c",
    "teamd/teamd_link_watch.c",
    "teamd/teamd_ctl.c",
    "teamd/teamd_dbus.c",
    "teamd/teamd_zmq.c",
    "teamd/teamd_usock.c",
    "teamd/teamd_phys_port_check.c",
    "teamd/teamd_bpf_chef.c",
    "teamd/teamd_hash_func.c",
    "teamd/teamd_balancer.c",
    "teamd/teamd_runner_basic_ones.c",
    "teamd/teamd_runner_activebackup.c",
    "teamd/teamd_runner_loadbalance.c",
    "teamd/teamd_runner_lacp.c",
]

TEAMD_HDRS = [
    "teamd/teamd.h",
    "teamd/teamd_workq.h",
    "teamd/teamd_bpf_chef.h",
    "teamd/teamd_ctl.h",
    "teamd/teamd_json.h",
    "teamd/teamd_dbus.h",
    "teamd/teamd_zmq.h",
    "teamd/teamd_usock.h",
    "teamd/teamd_dbus_common.h",
    "teamd/teamd_usock_common.h",
    "teamd/teamd_config.h",
    "teamd/teamd_state.h",
    "teamd/teamd_phys_port_check.h",
    "teamd/teamd_link_watch.h",
    "teamd/teamd_zmq_common.h",
]

cc_binary(
    name = "teamd",
    srcs = TEAMD_SRCS + TEAMD_HDRS,
    copts = COPTS_BIN + [
        "-DLOCALSTATEDIR=\\\"/var\\\"",
    ],
    includes = ["teamd"],
    dynamic_deps = [
        ":libteam_shared",
        "@libnl3//:libnl_3_shared",
        "@libnl3//:libnl_genl_3_shared",
        "@libnl3//:libnl_route_3_shared",
        "@libnl3//:libnl_nf_3_shared",
        "@libnl3//:libnl_cli_3_shared",
    ],
    deps = [
        ":config_h_hdr",
        ":libteam_hdrs",
        "@libteam_deps//libdaemon-dev:libdaemon",
        "@libteam_deps//libjansson-dev:libjansson",
        "@libteam_deps//libdbus-1-dev:libdbus-1",
    ],
)

# =============================================================================
# Expose the upstream bond2team script and pc.in templates for the wrapper
# //src/libteam:BUILD.bazel to pick up.
# =============================================================================
filegroup(
    name = "bond2team_script",
    srcs = ["utils/bond2team"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "public_team_h",
    srcs = ["include/team.h"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "public_teamdctl_h",
    srcs = ["include/teamdctl.h"],
    visibility = ["//visibility:public"],
)
