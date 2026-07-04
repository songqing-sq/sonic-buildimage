# Bazel build for lldpd 1.0.16-1+deb12u1 (SONiC patched), Linux/amd64+arm64.
#
# Upstream tarball fetched via sonic_http_archive (see ../MODULE.bazel).
# SONiC-relevant patches applied:
#   - patch/0001-return-error-when-port-does-not-exist.patch (StGIT, series)
#   - patch/0002-use-a-different-socket-for-changes-and-queries.patch (StGIT, series)
#
# Configure-equivalent feature set (Linux, matches what Debian's debian/
# rules + lldpd defaults would produce on trixie):
#   --with-snmp --with-xml --enable-pie
#   --enable-cdp --enable-fdp --enable-edp --enable-sonmp
#   --enable-lldpmed --enable-dot1 --enable-dot3 --enable-custom
#   --enable-privsep --with-privsep-user=_lldpd --with-privsep-group=_lldpd
#   --with-privsep-chroot=/var/run/lldpd
#   --without-libbsd
#   --without-seccomp (USE_SECCOMP=0; we drop priv-seccomp.c)
#   --without-systemdsystemunitdir --without-sysusersdir --without-apparmordir
#       (no service/sysusers/apparmor data files)
#
# The SONiC build env sets `with_netlink_receive_bufsize=2*1024*1024` and
# `with_netlink_max_receive_bufsize=4*1024*1024` (lldpd.mk's $(LLDPD)_BUILD_ENV
# equivalent in src/lldpd/Makefile); reflected in NETLINK_RECEIVE_BUFSIZE below.

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@sonic_build_infra//shared_library:shared_library.bzl", "sonic_shared_library_versioned")

package(default_visibility = ["//visibility:public"])

LLDPD_VERSION = "1.0.16"

LIBLLDPCTL_SOVERSION = "4"
LIBLLDPCTL_FULL_SOVERSION = "4.9.1"

# =============================================================================
# Generated config.h (mirrors what ./configure produces on Linux with the flag
# set documented above). config.h.in is a Debian-style autoheader template
# using `#undef NAME` lines that we sed to `#define NAME 1` (or a value).
# =============================================================================
genrule(
    name = "config_h",
    srcs = ["config.h.in"],
    outs = ["config.h"],
    cmd = """
        sed \\
            -e 's|#undef ENABLE_CDP|#define ENABLE_CDP 1|' \\
            -e 's|#undef ENABLE_CUSTOM|#define ENABLE_CUSTOM 1|' \\
            -e 's|#undef ENABLE_DOT1|#define ENABLE_DOT1 1|' \\
            -e 's|#undef ENABLE_DOT3|#define ENABLE_DOT3 1|' \\
            -e 's|#undef ENABLE_EDP|#define ENABLE_EDP 1|' \\
            -e 's|#undef ENABLE_FDP|#define ENABLE_FDP 1|' \\
            -e 's|#undef ENABLE_LLDPMED|#define ENABLE_LLDPMED 1|' \\
            -e 's|#undef ENABLE_PRIVSEP|#define ENABLE_PRIVSEP 1|' \\
            -e 's|#undef ENABLE_SONMP|#define ENABLE_SONMP 1|' \\
            -e 's|#undef HAVE_ALIGNOF|#define HAVE_ALIGNOF 1|' \\
            -e 's|#undef HAVE_ARPA_NAMESER_H|#define HAVE_ARPA_NAMESER_H 1|' \\
            -e 's|#undef HAVE_ASPRINTF|#define HAVE_ASPRINTF 1|' \\
            -e 's|#undef HAVE_DAEMON|#define HAVE_DAEMON 1|' \\
            -e 's|#undef HAVE_DLFCN_H|#define HAVE_DLFCN_H 1|' \\
            -e 's|#undef HAVE_FORK|#define HAVE_FORK 1|' \\
            -e 's|#undef HAVE_GETLINE|#define HAVE_GETLINE 1|' \\
            -e 's|#undef HAVE_INTTYPES_H|#define HAVE_INTTYPES_H 1|' \\
            -e 's|#undef HAVE_LIBREADLINE|#define HAVE_LIBREADLINE 1|' \\
            -e 's|#undef HAVE_LINUX_CAPABILITIES|#define HAVE_LINUX_CAPABILITIES 1|' \\
            -e 's|#undef HAVE_NETDB_H|#define HAVE_NETDB_H 1|' \\
            -e 's|#undef HAVE_NETINET_IN_H|#define HAVE_NETINET_IN_H 1|' \\
            -e 's|#undef HAVE_NETSNMP_ENABLE_SUBAGENT|#define HAVE_NETSNMP_ENABLE_SUBAGENT 1|' \\
            -e 's|#undef HAVE_NETSNMP_TDOMAIN_F_CREATE_FROM_TSTRING_NEW|#define HAVE_NETSNMP_TDOMAIN_F_CREATE_FROM_TSTRING_NEW 1|' \\
            -e 's|#undef HAVE_NET_SNMP_AGENT_UTIL_FUNCS_H|#define HAVE_NET_SNMP_AGENT_UTIL_FUNCS_H 1|' \\
            -e 's|#undef HAVE_READLINE_H\\b|#define HAVE_READLINE_H 1|' \\
            -e 's|#undef HAVE_READLINE_HISTORY\\b|#define HAVE_READLINE_HISTORY 1|' \\
            -e 's|#undef HAVE_READLINE_HISTORY_H|#define HAVE_READLINE_HISTORY_H 1|' \\
            -e 's|#undef HAVE_READLINE_READLINE_H|#define HAVE_READLINE_READLINE_H 1|' \\
            -e 's|#undef HAVE_RESOLV_H|#define HAVE_RESOLV_H 1|' \\
            -e 's|#undef HAVE_RES_INIT|#define HAVE_RES_INIT 1|' \\
            -e 's|#undef HAVE_SETPROCTITLE\\b|#define HAVE_SETPROCTITLE 0|' \\
            -e 's|#undef HAVE_SETPROCTITLE_INIT\\b|#define HAVE_SETPROCTITLE_INIT 0|' \\
            -e 's|#undef HAVE_SETRESGID|#define HAVE_SETRESGID 1|' \\
            -e 's|#undef HAVE_SETRESUID|#define HAVE_SETRESUID 1|' \\
            -e 's|#undef HAVE_SNMP_SELECT_INFO2|#define HAVE_SNMP_SELECT_INFO2 1|' \\
            -e 's|#undef HAVE_STDINT_H|#define HAVE_STDINT_H 1|' \\
            -e 's|#undef HAVE_STDIO_H|#define HAVE_STDIO_H 1|' \\
            -e 's|#undef HAVE_STDLIB_H|#define HAVE_STDLIB_H 1|' \\
            -e 's|#undef HAVE_STRINGS_H|#define HAVE_STRINGS_H 1|' \\
            -e 's|#undef HAVE_STRING_H|#define HAVE_STRING_H 1|' \\
            -e 's|#undef HAVE_STRLCPY|/* HAVE_STRLCPY: not in glibc */|' \\
            -e 's|#undef HAVE_STRNDUP|#define HAVE_STRNDUP 1|' \\
            -e 's|#undef HAVE_STRNLEN|#define HAVE_STRNLEN 1|' \\
            -e 's|#undef HAVE_STRTONUM|/* HAVE_STRTONUM: not in glibc */|' \\
            -e 's|#undef HAVE_SYS_STAT_H|#define HAVE_SYS_STAT_H 1|' \\
            -e 's|#undef HAVE_SYS_TYPES_H|#define HAVE_SYS_TYPES_H 1|' \\
            -e 's|#undef HAVE_TYPEOF|#define HAVE_TYPEOF 1|' \\
            -e 's|#undef HAVE_UINT32_T|#define HAVE_UINT32_T 1|' \\
            -e 's|#undef HAVE_UNISTD_H|#define HAVE_UNISTD_H 1|' \\
            -e 's|#undef HAVE_U_INT32_T|#define HAVE_U_INT32_T 1|' \\
            -e 's|#undef HAVE_VFORK\\b|#define HAVE_VFORK 1|' \\
            -e 's|#undef HAVE_VSYSLOG|#define HAVE_VSYSLOG 1|' \\
            -e 's|#undef HAVE_WORKING_FORK|#define HAVE_WORKING_FORK 1|' \\
            -e 's|#undef HAVE_WORKING_VFORK|#define HAVE_WORKING_VFORK 1|' \\
            -e 's|#undef HAVE___PROGNAME|#define HAVE___PROGNAME 1|' \\
            -e 's|#undef HOST_OS_LINUX|#define HOST_OS_LINUX 1|' \\
            -e 's|#undef LLDPD_CTL_SOCKET|#define LLDPD_CTL_SOCKET "/var/run/lldpd.socket"|' \\
            -e 's|#undef LLDPD_PID_FILE|#define LLDPD_PID_FILE "/var/run/lldpd.pid"|' \\
            -e 's|#undef LLDP_CC|#define LLDP_CC "C compiler command is not available for reproducible builds"|' \\
            -e 's|#undef LLDP_LD|#define LLDP_LD "Linker compiler command is not available for reproducible builds"|' \\
            -e 's|#undef LT_OBJDIR|#define LT_OBJDIR ".libs/"|' \\
            -e 's|#undef MIN_LINUX_KERNEL_VERSION|#define MIN_LINUX_KERNEL_VERSION "2.6.39"|' \\
            -e 's|#undef NETLINK_MAX_RECEIVE_BUFSIZE|#define NETLINK_MAX_RECEIVE_BUFSIZE 4*1024*1024|' \\
            -e 's|#undef NETLINK_RECEIVE_BUFSIZE|#define NETLINK_RECEIVE_BUFSIZE 2*1024*1024|' \\
            -e 's|#undef NETLINK_SEND_BUFSIZE|#define NETLINK_SEND_BUFSIZE 0|' \\
            -e 's|#undef PACKAGE_BUGREPORT|#define PACKAGE_BUGREPORT "https://github.com/lldpd/lldpd/issues"|' \\
            -e 's|#undef PACKAGE_NAME|#define PACKAGE_NAME "lldpd"|' \\
            -e 's|#undef PACKAGE_STRING|#define PACKAGE_STRING "lldpd 1.0.16"|' \\
            -e 's|#undef PACKAGE_TARNAME|#define PACKAGE_TARNAME "lldpd"|' \\
            -e 's|#undef PACKAGE_URL|#define PACKAGE_URL "https://lldpd.github.io/"|' \\
            -e 's|#undef PACKAGE_VERSION|#define PACKAGE_VERSION "1.0.16"|' \\
            -e 's|#undef PACKAGE\\b|#define PACKAGE "lldpd"|' \\
            -e 's|#undef PRIVSEP_CHROOT|#define PRIVSEP_CHROOT "/var/run/lldpd"|' \\
            -e 's|#undef PRIVSEP_GROUP|#define PRIVSEP_GROUP "_lldpd"|' \\
            -e 's|#undef PRIVSEP_USER|#define PRIVSEP_USER "_lldpd"|' \\
            -e 's|#undef STDC_HEADERS|#define STDC_HEADERS 1|' \\
            -e 's|#undef USE_SNMP|#define USE_SNMP 1|' \\
            -e 's|#undef USE_XML|#define USE_XML 1|' \\
            -e 's|#undef VERSION|#define VERSION "1.0.16"|' \\
            -e 's|#undef BUILD_DATE|#define BUILD_DATE "(unknown)"|' \\
            $< > $@
    """,
)

# =============================================================================
# Generated atom-glue.c. Upstream uses CPP+SED+AWK to harvest
# init_atom_builder_NAME / init_atom_map_NAME calls from src/lib/atoms/*.c.
# We bypass CPP and grep the raw `ATOM_*_REGISTER(NAME, PRIO);` macro calls
# directly (verified unconditional across all atoms/*.c files).
# =============================================================================
genrule(
    name = "atom_glue_c",
    srcs = glob(["src/lib/atoms/*.c"]),
    outs = ["src/lib/atom-glue.c"],
    cmd = """
        {
            echo '/* Auto-generated atom-glue.c for Bazel build of liblldpctl. */'
            grep -h '^ATOM_BUILDER_REGISTER\\|^ATOM_MAP_REGISTER' $(SRCS) | \\
                sed -n 's/^\\(ATOM_BUILDER_REGISTER\\|ATOM_MAP_REGISTER\\)(\\([^,]*\\),.*/\\1 \\2/p' | \\
                sort -u | \\
                awk '
                    /^ATOM_BUILDER_REGISTER/ { builders[$$2] = 1 }
                    /^ATOM_MAP_REGISTER/     { maps[$$2]     = 1 }
                    END {
                        for (b in builders) print "void init_atom_builder_" b "(void);"
                        print "void init_atom_builder() {"
                        print "    static int init = 0; if (init) return; init++;"
                        for (b in builders) print "    init_atom_builder_" b "();"
                        print "}"
                        for (m in maps) print "void init_atom_map_" m "(void);"
                        print "void init_atom_map() {"
                        print "    static int init = 0; if (init) return; init++;"
                        for (m in maps) print "    init_atom_map_" m "();"
                        print "}"
                    }
                '
        } > $@
    """,
)

# =============================================================================
# Common compiler flags
# =============================================================================
LLDPD_COPTS = [
    "-std=gnu99",
    "-D_GNU_SOURCE",
    "-DHAVE_CONFIG_H",
    "-DSYSCONFDIR=\\\"/etc\\\"",
    "-Iinclude",
    "-Isrc",
    "-Wno-unused-parameter",
    "-Wno-unused-but-set-variable",
    "-Wno-unused-variable",
    "-Wno-deprecated-declarations",
    "-fPIC",
]

# =============================================================================
# Internal headers (config.h, src/*.h, src/lib/*.h, etc.)
# =============================================================================
cc_library(
    name = "lldpd_private_headers",
    hdrs = glob([
        "include/**/*.h",
        "src/*.h",
        "src/compat/*.h",
        "src/daemon/*.h",
        "src/client/*.h",
        "src/lib/*.h",
    ]) + [
        ":config_h",
    ],
    includes = [
        ".",
        "include",
        "src",
        "src/lib",
    ],
)

# =============================================================================
# libcompat: compat library. On glibc Linux, asprintf/daemon/fork/vfork/
# getline/vsyslog/strndup/strnlen/setresuid/setresgid are present so
# @LTLIBOBJS@ skips them, but glibc lacks `strlcpy` and `strtonum`, so the
# corresponding compat .c files are still linked in.
# =============================================================================
cc_library(
    name = "libcompat",
    srcs = [
        "src/compat/empty.c",
        "src/compat/setproctitle.c",
        "src/compat/strlcpy.c",
        "src/compat/strtonum.c",
    ],
    deps = [":lldpd_private_headers"],
    copts = LLDPD_COPTS,
    # Force the compat .a into every dependent link, even when Bazel's
    # cc_binary + dynamic_deps machinery would otherwise elide it because a
    # shared library on dynamic_deps has libcompat in its exports_filter.
    # We need strtonum in the lldpcli binary directly (glibc doesn't ship
    # it, the daemon and CLI both reference it, and liblldpctl.so's version
    # script hides it), so alwayslink is the correct posture here.
    alwayslink = True,
)

# =============================================================================
# libcommon-daemon-lib: shared between liblldpctl and the daemon.
# =============================================================================
cc_library(
    name = "libcommon_daemon_lib",
    srcs = [
        "src/log.c",
        "src/version.c",
        "src/marshal.c",
        "src/ctl.c",
        "src/lldpd-structs.c",
    ],
    deps = [
        ":lldpd_private_headers",
        ":libcompat",
    ],
    copts = LLDPD_COPTS,
)

# =============================================================================
# libcommon-daemon-client: shared between lldpcli and liblldpctl. Only log/
# version, no marshalling or ctl socket helpers.
# =============================================================================
cc_library(
    name = "libcommon_daemon_client",
    srcs = [
        "src/log.c",
        "src/version.c",
    ],
    deps = [
        ":lldpd_private_headers",
        ":libcompat",
    ],
    copts = LLDPD_COPTS,
)

# =============================================================================
# libfixedpoint: tiny static helper used by liblldpctl.
# =============================================================================
cc_library(
    name = "libfixedpoint",
    srcs = ["src/lib/fixedpoint.c"],
    hdrs = ["src/lib/fixedpoint.h"],
    deps = [":lldpd_private_headers"],
    copts = LLDPD_COPTS,
    alwayslink = True,
)

# =============================================================================
# liblldpctl: public, ABI-versioned shared library. soname = liblldpctl.so.4,
# full = liblldpctl.so.4.9.1 (matches upstream `-version-info 13:1:9`).
# =============================================================================
LIBLLDPCTL_PUBLIC_HDRS = [
    "src/lib/lldpctl.h",
    "src/lldp-const.h",
]

sonic_shared_library_versioned(
    name = "lldpctl",
    srcs = [
        "src/lib/errors.c",
        "src/lib/connection.c",
        "src/lib/atom.c",
        "src/lib/helpers.c",
        "src/lib/atoms/chassis.c",
        "src/lib/atoms/config.c",
        "src/lib/atoms/custom.c",
        "src/lib/atoms/dot1.c",
        "src/lib/atoms/dot3.c",
        "src/lib/atoms/interface.c",
        "src/lib/atoms/med.c",
        "src/lib/atoms/mgmt.c",
        "src/lib/atoms/port.c",
        ":atom_glue_c",
    ],
    hdrs = LIBLLDPCTL_PUBLIC_HDRS + [
        "src/lib/atom.h",
        "src/lib/helpers.h",
    ],
    deps = [
        ":lldpd_private_headers",
        ":libcommon_daemon_lib",
        ":libfixedpoint",
        ":libcompat",
    ],
    # No exports_filter needed: no downstream cc_binary uses dynamic_deps on
    # this cc_shared_library. lldpcli links :lldpctl via `deps` (static), so
    # Bazel's "linked-but-not-exported" check is not triggered. See comment
    # on the lldpcli cc_binary for the trade-off vs. Make's dynamic linkage.
    copts = LLDPD_COPTS,
    linkopts = [
        "-Wl,--version-script=$(location src/lib/lldpctl.map)",
    ],
    additional_linker_inputs = ["src/lib/lldpctl.map"],
    soversion = LIBLLDPCTL_SOVERSION,
    version = LIBLLDPCTL_FULL_SOVERSION,
    output_name = "liblldpctl",
    visibility = ["//visibility:public"],
)

# =============================================================================
# Public headers filegroup for the -dev deb.
# =============================================================================
filegroup(
    name = "public_headers",
    srcs = LIBLLDPCTL_PUBLIC_HDRS,
)

# =============================================================================
# liblldpd: daemon helper library (Linux-only path, with SNMP).
# =============================================================================
cc_library(
    name = "liblldpd",
    srcs = [
        # core daemon
        "src/daemon/frame.c",
        "src/daemon/client.c",
        "src/daemon/priv.c",
        "src/daemon/privsep.c",
        "src/daemon/privsep_io.c",
        "src/daemon/privsep_fd.c",
        "src/daemon/interfaces.c",
        "src/daemon/event.c",
        "src/daemon/lldpd.c",
        "src/daemon/pattern.c",
        "src/daemon/bitmap.c",
        # protocols
        "src/daemon/protocols/lldp.c",
        "src/daemon/protocols/cdp.c",
        "src/daemon/protocols/sonmp.c",
        "src/daemon/protocols/edp.c",
        # Linux-specific
        "src/daemon/forward-linux.c",
        "src/daemon/interfaces-linux.c",
        "src/daemon/netlink.c",
        "src/daemon/dmi-linux.c",
        "src/daemon/priv-linux.c",
        # SNMP subagent (USE_SNMP=1)
        "src/daemon/agent.c",
        "src/daemon/agent_priv.c",
    ],
    hdrs = glob([
        "src/daemon/*.h",
        "src/daemon/protocols/*.h",
    ]),
    deps = [
        ":lldpd_private_headers",
        ":libcommon_daemon_lib",
        ":libcommon_daemon_client",
        ":libcompat",
        "@lldpd_deps//libsnmp-dev:libsnmp",
        "@lldpd_deps//libevent-dev:libevent",
        "@lldpd_deps//libcap-dev:libcap",
    ],
    copts = LLDPD_COPTS + [
        "-DLLDPCLI_PATH=\\\"/usr/sbin/lldpcli\\\"",
        "-Isrc/daemon",
    ],
    linkopts = [
        "-lrt",
    ],
)

# =============================================================================
# lldpd binary
#
# features/-runtime_library_search_directories: disable the Bazel cc toolchain
# feature that appends `$ORIGIN/../../_solib_k8/...` RPATH entries pointing
# into the runfiles tree. Those paths do NOT exist on the target /usr/sbin/
# install layout, and the Make baseline lldpd ships with no RPATH/RUNPATH at
# all -- so dropping the feature yields a clean binary that matches upstream.
#
# -Wl,--as-needed: pkg-config Libs.private on trixie's libsnmp-dev pulls in
# the full net-snmp private link line (libmariadb, libperl, libwrap, libssl,
# libcrypto, libz, libselinux, libpcre2, libsensors, libpci, libudev,
# libevent_core/extra/openssl/pthreads, ...). With --as-needed, ld only emits
# DT_NEEDED for shared libraries that resolve at least one referenced symbol,
# stripping the transitive junk and matching Make's compact NEEDED list of
# libnetsnmp*/libevent/libcap/libbsd/libc.
#
# -lbsd: Make's lldpd links against libbsd (privsep chroot uses BSD-only
# helpers: strtonum/setproctitle wrappers via compat/). Force the direct
# NEEDED entry so runtime resolution matches; the apt libbsd-dev package is
# already in @lldpd_deps.
# =============================================================================
cc_binary(
    name = "lldpd",
    srcs = ["src/daemon/main.c"],
    deps = [
        ":liblldpd",
        "@lldpd_deps//libsnmp-dev:libsnmp",
        "@lldpd_deps//libevent-dev:libevent",
        "@lldpd_deps//libcap-dev:libcap",
        # rules_distroless-generated @lldpd_deps//libbsd-dev:libbsd is unusable
        # here (its cc_import lists a raw file label from a sibling apt repo in
        # `deps`, which Bazel rejects as misplaced). Bypass the -dev wrapper
        # and depend on the runtime libbsd0's cc_import directly (per-arch).
    ] + select({
        "@platforms//cpu:x86_64":  ["@trixie_libbsd0-amd64_0.12.2-2//:libbsd.so.0"],
        "@platforms//cpu:aarch64": ["@trixie_libbsd0-arm64_0.12.2-2//:libbsd.so.0"],
    }),
    copts = LLDPD_COPTS + ["-Isrc/daemon"],
    features = ["-runtime_library_search_directories"],
    linkopts = [
        "-pie",
        "-lrt",
        "-Wl,--as-needed",
        "-Wl,--no-copy-dt-needed-entries",
    ],
    visibility = ["//visibility:public"],
)

# =============================================================================
# lldpcli binary
# =============================================================================
cc_binary(
    name = "lldpcli",
    srcs = [
        "src/client/lldpcli.c",
        "src/client/display.c",
        "src/client/conf.c",
        "src/client/conf-med.c",
        "src/client/conf-inv.c",
        "src/client/conf-dot3.c",
        "src/client/conf-power.c",
        "src/client/conf-lldp.c",
        "src/client/conf-system.c",
        "src/client/commands.c",
        "src/client/show.c",
        "src/client/misc.c",
        "src/client/tokenizer.c",
        "src/client/utf8.c",
        "src/client/text_writer.c",
        "src/client/kv_writer.c",
        "src/client/json_writer.c",
        "src/client/xml_writer.c",
    ],
    deps = [
        ":lldpd_private_headers",
        ":libcommon_daemon_client",
        ":libcompat",
        ":libfixedpoint",
        ":lldpctl",
        "@lldpd_deps//libxml2-dev:libxml2",
        "@lldpd_deps//libreadline-dev:libreadline",
    ],
    copts = LLDPD_COPTS,
    features = ["-runtime_library_search_directories"],
    # libxml2 transitively pulls libicuuc.so.NN, which DT_NEEDEDs libicudata.so.NN.
    # rules_distroless does not declare libicudata as a cc_import dep of libicuuc,
    # so the link step cannot find icudt_dat. --allow-shlib-undefined tells ld
    # to ignore unresolved shared-lib symbols; ld.so resolves them at runtime
    # because libicu is the apt runtime dep of libxml2 inside the docker image.
    linkopts = [
        "-pie",
        "-Wl,--allow-shlib-undefined",
    ],
    visibility = ["//visibility:public"],
)

# =============================================================================
# Generated lldpctl.pc — multiarch-aware libdir via select().
# `expand_template` doesn't accept select() in `substitutions`, so we use
# a genrule with a per-CPU sed command instead.
# =============================================================================
genrule(
    name = "lldpctl_pc",
    srcs = ["src/lib/lldpctl.pc.in"],
    outs = ["lldpctl.pc"],
    cmd = select({
        "@platforms//cpu:x86_64": (
            "sed " +
            "-e 's|@VERSION@|" + LLDPD_VERSION + "|g' " +
            "-e 's|@PACKAGE_URL@|https://lldpd.github.io/|g' " +
            "-e 's|@libdir@|/usr/lib/x86_64-linux-gnu|g' " +
            "-e 's|@includedir@|/usr/include|g' " +
            "$< > $@"
        ),
        "@platforms//cpu:aarch64": (
            "sed " +
            "-e 's|@VERSION@|" + LLDPD_VERSION + "|g' " +
            "-e 's|@PACKAGE_URL@|https://lldpd.github.io/|g' " +
            "-e 's|@libdir@|/usr/lib/aarch64-linux-gnu|g' " +
            "-e 's|@includedir@|/usr/include|g' " +
            "$< > $@"
        ),
    }),
)
