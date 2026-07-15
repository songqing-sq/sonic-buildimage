# Bazel build for lldpd 1.0.16-1+deb12u1 (SONiC/dzf patched), Linux.
#
# Upstream tarball fetched via sonic_http_archive (see ../MODULE.bazel).
# Patches applied at fetch time: debian quilt 0002 (CVE-2023-41910), SONiC
# 0001 (conf-lldp) and SONiC 0002 (dual netlink socket).
#
# Configure-equivalent feature set (matches Debian's debian/rules on
# trixie + lldpd defaults): --enable-pie --with-snmp --with-xml
# --with-systemdsystemunitdir; CDP/FDP/EDP/SONMP/LLDP-MED/dot1/dot3/custom
# enabled; privsep on with user/group _lldpd and chroot /run/lldpd;
# --without-seccomp; readline linked into lldpcli.
#
# dzf-specific deltas vs the reference migration:
#   * NETLINK_RECEIVE_BUFSIZE     = 2*1024*1024  (src/lldpd/Makefile BUILD_ENV)
#   * NETLINK_MAX_RECEIVE_BUFSIZE = 4*1024*1024
#   * runstate paths under /run (debhelper compat 13 --runstatedir=/run):
#       LLDPD_CTL_SOCKET=/run/lldpd.socket, LLDPD_PID_FILE=/run/lldpd.pid,
#       PRIVSEP_CHROOT=/run/lldpd.

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@bazel_skylib//rules:expand_template.bzl", "expand_template")
load("@sonic_build_infra//shared_library:shared_library.bzl", "sonic_shared_library_versioned")

package(default_visibility = ["//visibility:public"])

LLDPD_VERSION = "1.0.16"

LIBLLDPCTL_SOVERSION = "4"

LIBLLDPCTL_FULL_SOVERSION = "4.9.1"

# =============================================================================
# Generated config.h (mirrors ./configure output for the flag set above).
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
            -e 's|#undef LLDPD_CTL_SOCKET|#define LLDPD_CTL_SOCKET "/run/lldpd.socket"|' \\
            -e 's|#undef LLDPD_PID_FILE|#define LLDPD_PID_FILE "/run/lldpd.pid"|' \\
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
            -e 's|#undef PRIVSEP_CHROOT|#define PRIVSEP_CHROOT "/run/lldpd"|' \\
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
# Generated atom-glue.c (harvest init_atom_builder_/init_atom_map_ registrations).
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

cc_library(
    name = "libcompat",
    srcs = [
        "src/compat/empty.c",
        "src/compat/setproctitle.c",
        "src/compat/strlcpy.c",
        "src/compat/strtonum.c",
    ],
    copts = LLDPD_COPTS,
    deps = [":lldpd_private_headers"],
)

cc_library(
    name = "libcommon_daemon_lib",
    srcs = [
        "src/log.c",
        "src/version.c",
        "src/marshal.c",
        "src/ctl.c",
        "src/lldpd-structs.c",
    ],
    copts = LLDPD_COPTS,
    deps = [
        ":lldpd_private_headers",
        ":libcompat",
    ],
)

cc_library(
    name = "libcommon_daemon_client",
    srcs = [
        "src/log.c",
        "src/version.c",
    ],
    copts = LLDPD_COPTS,
    deps = [
        ":lldpd_private_headers",
        ":libcompat",
    ],
)

cc_library(
    name = "libfixedpoint",
    srcs = ["src/lib/fixedpoint.c"],
    hdrs = ["src/lib/fixedpoint.h"],
    copts = LLDPD_COPTS,
    deps = [":lldpd_private_headers"],
)

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
    additional_linker_inputs = ["src/lib/lldpctl.map"],
    copts = LLDPD_COPTS,
    linkopts = [
        "-Wl,--version-script=$(location src/lib/lldpctl.map)",
    ],
    output_name = "liblldpctl",
    soversion = LIBLLDPCTL_SOVERSION,
    version = LIBLLDPCTL_FULL_SOVERSION,
    visibility = ["//visibility:public"],
    deps = [
        ":lldpd_private_headers",
        ":libcommon_daemon_lib",
        ":libfixedpoint",
        ":libcompat",
    ],
)

filegroup(
    name = "public_headers",
    srcs = LIBLLDPCTL_PUBLIC_HDRS,
)

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
    copts = LLDPD_COPTS + [
        "-DLLDPCLI_PATH=\\\"/usr/sbin/lldpcli\\\"",
        "-Isrc/daemon",
    ],
    linkopts = [
        "-lrt",
    ],
    deps = [
        ":lldpd_private_headers",
        ":libcommon_daemon_lib",
        ":libcommon_daemon_client",
        ":libcompat",
        "@lldpd_deps//libsnmp-dev:libsnmp",
        "@lldpd_deps//libevent-dev:libevent",
        "@lldpd_deps//libcap-dev:libcap",
    ],
)

cc_binary(
    name = "lldpd",
    srcs = ["src/daemon/main.c"],
    copts = LLDPD_COPTS + ["-Isrc/daemon"],
    linkopts = [
        "-pie",
        "-lrt",
        "-Wl,--export-dynamic",
    ],
    visibility = ["//visibility:public"],
    deps = [
        ":liblldpd",
        "@lldpd_deps//libsnmp-dev:libsnmp",
        "@lldpd_deps//libevent-dev:libevent",
        "@lldpd_deps//libcap-dev:libcap",
    ],
)

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
    copts = LLDPD_COPTS,
    # libxml2 -> libicuuc -> libicudata is not declared as a cc_import chain by
    # rules_distroless; ld.so resolves libicudata at runtime (libicu is the apt
    # runtime dep of libxml2 in the image). --allow-shlib-undefined lets the
    # link step ignore those transitive undefined shared-lib symbols.
    linkopts = [
        "-pie",
        "-Wl,--allow-shlib-undefined",
    ],
    visibility = ["//visibility:public"],
    deps = [
        ":lldpd_private_headers",
        ":libcommon_daemon_client",
        ":libcompat",
        ":libfixedpoint",
        ":lldpctl",
        "@lldpd_deps//libxml2-dev:libxml2",
        "@lldpd_deps//libreadline-dev:libreadline",
    ],
)

# =============================================================================
# Generated lldpctl.pc (development package pkg-config).
# NOTE: @libdir@ is baked to the amd64 multiarch triplet; on arm64 the -L path
# inside the .pc would need aarch64 (documented build limitation).
# =============================================================================
expand_template(
    name = "lldpctl_pc",
    out = "lldpctl.pc",
    substitutions = {
        "@VERSION@": LLDPD_VERSION,
        "@PACKAGE_URL@": "https://lldpd.github.io/",
        "@libdir@": "/usr/lib/x86_64-linux-gnu",
        "@includedir@": "/usr/include",
    },
    template = "src/lib/lldpctl.pc.in",
)

# =============================================================================
# Data files generated from the upstream source (autotools *.in substitution).
# =============================================================================

# systemd unit: @PRIVSEP_CHROOT@ -> /run/lldpd, @sbindir@ -> /usr/sbin.
genrule(
    name = "lldpd_service",
    srcs = ["src/daemon/lldpd.service.in"],
    outs = ["lldpd.service"],
    cmd = "sed -e 's|@PRIVSEP_CHROOT@|/run/lldpd|g' -e 's|@sbindir@|/usr/sbin|g' $< > $@",
)

# man pages: substitute runstate paths, then gzip -9n for reproducibility.
genrule(
    name = "lldpd_man",
    srcs = ["src/daemon/lldpd.8.in"],
    outs = ["lldpd.8.gz"],
    cmd = "sed -e 's|@LLDPD_CTL_SOCKET@|/run/lldpd.socket|g' -e 's|@LLDPD_PID_FILE@|/run/lldpd.pid|g' $< | gzip -9n > $@",
)

genrule(
    name = "lldpcli_man",
    srcs = ["src/client/lldpcli.8.in"],
    outs = ["lldpcli.8.gz"],
    cmd = "sed -e 's|@LLDPD_CTL_SOCKET@|/run/lldpd.socket|g' $< | gzip -9n > $@",
)

# doc files gzipped by dh_installchangelog/dh_compress in the Make build.
genrule(
    name = "news_gz",
    srcs = ["NEWS"],
    outs = ["NEWS.gz"],
    cmd = "gzip -9nc $< > $@",
)

genrule(
    name = "readme_md_gz",
    srcs = ["README.md"],
    outs = ["README.md.gz"],
    cmd = "gzip -9nc $< > $@",
)

# Static data files shipped verbatim from the upstream source.
filegroup(
    name = "readme_conf",
    srcs = ["src/client/README.conf"],
)

filegroup(
    name = "contribute_md",
    srcs = ["CONTRIBUTE.md"],
)

filegroup(
    name = "bash_completion",
    srcs = ["src/client/completion/lldpcli"],
)

filegroup(
    name = "zsh_completion",
    srcs = ["src/client/completion/_lldpcli"],
)
