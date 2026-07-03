# Bazel build for isc-dhcp 4.4.3-P1-2 (SONiC patched), dhcrelay-only profile.
#
# Fetches the upstream Debian orig tarball via sonic_http_archive (see
# MODULE.bazel) and applies the 14 SONiC patches from patch/series. Patch
# 0005 and 0014 modify debian/rules only — their effects are folded into the
# Bazel copts. Patch 0013 is omitted because the cumulative effect of 0001-
# 0012 already covers it (the upstream stg flow detects the no-op; bazel's
# repository_ctx.patch is stricter).
#
# BIND 9.11.36 sublibs (libisc, libdns, libisccfg, libirs) are fetched as a
# separate http_archive (@isc_dhcp_bind_src), built per bind.BUILD, and
# linked statically into dhcrelay. The deb produced by :sonic_deb is wired
# into //dockers/docker-dhcp-relay.

package(default_visibility = ["//visibility:public"])

# =============================================================================
# Generated config.h (autoconf-style header)
# =============================================================================
#
# Mirrors src/libnl3/libnl3.BUILD's :defs_h pattern. The set of #undef tokens
# below is the union of:
#   - configure.ac AC_DEFINEs that fire for Linux x86_64 with the Debian
#     SONiC configure flags (--prefix=/usr --enable-log-pid --enable-paranoia
#     --enable-use-sockets, see debian/rules + patch 0005)
#   - autotools header-existence probes (HAVE_*_H) that pass on a Bookworm
#     glibc system
# Items NOT defined here (intentionally, they keep their #undef state):
#   - HAVE_BPF / HAVE_DLPI: BSD/Solaris-only.
#   - HAVE_LDAP_H, HAVE_ATF, HAVE_MICASA_MGMD_H: optional features.
#   - DEBUG, EARLY_CHROOT, RELAY_PORT, BINARY_LEASES, DHCP4o6, USE_V4_PKTINFO,
#     USE_DEV_NET, VLAN_TCI_PRESENT, ISC_PLATFORM_HAVELIFNUM,
#     ISC_PLATFORM_HAVEIF_LADDRCONF, ISC_PLATFORM_HAVEIF_LADDRREQ,
#     NEED_INET_ATON, HAVE_NET_IF_DL_H, HAVE_NET_IF6_H, HAVE_SA_LEN: not set
#     by Debian's configure invocation on Linux.
#   - HAVE_INET_NTOP / HAVE_INET_PTON: configure.ac only probes these inside
#     the LDAP-enabled branch; the dhcp source treats them as optional.
#   - The _PATH_* macros: Debian's debian/rules sets them via -D in CFLAGS
#     (see patch 0005), so they belong in cc_binary copts, not in config.h.
genrule(
    name = "config_h",
    srcs = ["includes/config.h.in"],
    outs = ["includes/config.h"],
    cmd = """
        sed \\
            -e 's|#undef DELAYED_ACK|#define DELAYED_ACK 1|' \\
            -e 's|#undef DHCPv6|#define DHCPv6 1|' \\
            -e 's|#undef DHCP_BYTE_ORDER|#define DHCP_BYTE_ORDER LITTLE_ENDIAN|' \\
            -e 's|#undef ENABLE_EXECUTE|#define ENABLE_EXECUTE 1|' \\
            -e 's|#undef FAILOVER_PROTOCOL|#define FAILOVER_PROTOCOL 1|' \\
            -e 's|#undef FLEXIBLE_ARRAY_MEMBER|#define FLEXIBLE_ARRAY_MEMBER /**/|' \\
            -e 's|#undef HAVE_IFADDRS_H|#define HAVE_IFADDRS_H 1|' \\
            -e 's|#undef HAVE_INTTYPES_H|#define HAVE_INTTYPES_H 1|' \\
            -e 's|#undef HAVE_LINUX_TYPES_H|#define HAVE_LINUX_TYPES_H 1|' \\
            -e 's|#undef HAVE_LPF|#define HAVE_LPF 1|' \\
            -e 's|#undef HAVE_REGEX_H|#define HAVE_REGEX_H 1|' \\
            -e 's|#undef HAVE_STDINT_H|#define HAVE_STDINT_H 1|' \\
            -e 's|#undef HAVE_STDIO_H|#define HAVE_STDIO_H 1|' \\
            -e 's|#undef HAVE_STDLIB_H|#define HAVE_STDLIB_H 1|' \\
            -e 's|#undef HAVE_STRINGS_H|#define HAVE_STRINGS_H 1|' \\
            -e 's|#undef HAVE_STRING_H|#define HAVE_STRING_H 1|' \\
            -e 's|#undef HAVE_STRLCAT|#define HAVE_STRLCAT 1|' \\
            -e 's|#undef HAVE_SYS_SOCKET_H|#define HAVE_SYS_SOCKET_H 1|' \\
            -e 's|#undef HAVE_SYS_STAT_H|#define HAVE_SYS_STAT_H 1|' \\
            -e 's|#undef HAVE_SYS_TYPES_H|#define HAVE_SYS_TYPES_H 1|' \\
            -e 's|#undef HAVE_UNISTD_H|#define HAVE_UNISTD_H 1|' \\
            -e 's|#undef HAVE_WCHAR_H|#define HAVE_WCHAR_H 1|' \\
            -e 's|#undef ISC_DHCP_NORETURN|#define ISC_DHCP_NORETURN __attribute__((noreturn))|' \\
            -e 's|#undef ISC_PATH_RANDOMDEV|#define ISC_PATH_RANDOMDEV "/dev/random"|' \\
            -e 's|#undef PACKAGE\\b|#define PACKAGE "dhcp"|' \\
            -e 's|#undef PACKAGE_BUGREPORT|#define PACKAGE_BUGREPORT "dhcp-users@isc.org"|' \\
            -e 's|#undef PACKAGE_NAME|#define PACKAGE_NAME "DHCP"|' \\
            -e 's|#undef PACKAGE_STRING|#define PACKAGE_STRING "DHCP 4.4.3-P1"|' \\
            -e 's|#undef PACKAGE_TARNAME|#define PACKAGE_TARNAME "dhcp"|' \\
            -e 's|#undef PACKAGE_URL|#define PACKAGE_URL ""|' \\
            -e 's|#undef PACKAGE_VERSION|#define PACKAGE_VERSION "4.4.3-P1"|' \\
            -e 's|#undef PARANOIA|#define PARANOIA 1|' \\
            -e 's|#undef SIZEOF_STRUCT_IADDR_P|#define SIZEOF_STRUCT_IADDR_P 8|' \\
            -e 's|#undef STDC_HEADERS|#define STDC_HEADERS 1|' \\
            -e 's|#undef TRACING|#define TRACING 1|' \\
            -e 's|#undef USE_LOG_PID|#define USE_LOG_PID 1|' \\
            -e 's|#undef USE_SOCKETS|#define USE_SOCKETS 1|' \\
            -e 's|#undef VERSION|#define VERSION "4.4.3-P1"|' \\
            -e 's|^# undef _GNU_SOURCE|# define _GNU_SOURCE 1|' \\
            -e 's|^# undef __EXTENSIONS__|# define __EXTENSIONS__ 1|' \\
            -e 's|^# undef _ALL_SOURCE|# define _ALL_SOURCE 1|' \\
            -e 's|^# undef _POSIX_PTHREAD_SEMANTICS|# define _POSIX_PTHREAD_SEMANTICS 1|' \\
            -e 's|^# undef __STDC_WANT_IEC_60559_ATTRIBS_EXT__|# define __STDC_WANT_IEC_60559_ATTRIBS_EXT__ 1|' \\
            -e 's|^# undef __STDC_WANT_IEC_60559_BFP_EXT__|# define __STDC_WANT_IEC_60559_BFP_EXT__ 1|' \\
            -e 's|^# undef __STDC_WANT_IEC_60559_DFP_EXT__|# define __STDC_WANT_IEC_60559_DFP_EXT__ 1|' \\
            -e 's|^# undef __STDC_WANT_IEC_60559_FUNCS_EXT__|# define __STDC_WANT_IEC_60559_FUNCS_EXT__ 1|' \\
            -e 's|^# undef __STDC_WANT_IEC_60559_TYPES_EXT__|# define __STDC_WANT_IEC_60559_TYPES_EXT__ 1|' \\
            -e 's|^# undef __STDC_WANT_LIB_EXT2__|# define __STDC_WANT_LIB_EXT2__ 1|' \\
            -e 's|^# undef __STDC_WANT_MATH_SPEC_FUNCS__|# define __STDC_WANT_MATH_SPEC_FUNCS__ 1|' \\
            $(SRCS) > $(OUTS)
    """,
)

# Expose the patched source tree as a filegroup so the next agent can
# reference it without rewriting the fetch wiring.
filegroup(
    name = "all_sources",
    srcs = glob(
        [
            "common/*.c",
            "common/*.h",
            "omapip/*.c",
            "omapip/*.h",
            "relay/*.c",
            "relay/*.h",
            "includes/**/*.h",
        ],
        allow_empty = True,
    ),
)

# =============================================================================
# Native isc-dhcp build: libomapi, libdhcp, dhcrelay, isc-dhcp-relay deb.
# =============================================================================

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@sonic_build_infra//sonic_deb:sonic_deb.bzl", "sonic_deb")

ISC_DHCP_COPTS = [
    "-w",
    "-D_GNU_SOURCE",
    "-DHAVE_CONFIG_H",
    "-DLOCALSTATEDIR=\\\"/var\\\"",
    "-DNSUPDATE",
    # Ensure the source uses the includes/config.h we built, not its own copy.
    # USE_SOCKETS (set in :config_h) selects the BSD-socket dispatch path;
    # HAVE_LPF (also in :config_h) is what osdep.h chains through to derive
    # USE_LPF_HWADDR for SIOCGIFHWADDR-based MAC lookup, mirroring upstream
    # Debian's autoconf result.
    "-Iincludes",
]

cc_library(
    name = "libomapi",
    srcs = glob(
        ["omapip/*.c"],
        exclude = [
            "omapip/test.c",
            "omapip/svtest.c",
        ],
    ),
    hdrs = glob(["includes/**/*.h"]) + [":config_h"],
    includes = ["includes"],
    copts = ISC_DHCP_COPTS,
    deps = [
        "@isc_dhcp_bind_src//:libdns",
        "@isc_dhcp_bind_src//:libisccfg",
        "@isc_dhcp_bind_src//:libirs",
        "@isc_dhcp_bind_src//:libisc",
    ],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "libdhcp",
    srcs = glob(["common/*.c"]),
    hdrs = glob(["includes/**/*.h"]) + [":config_h"],
    includes = ["includes"],
    copts = ISC_DHCP_COPTS,
    deps = [
        ":libomapi",
        "@isc_dhcp_bind_src//:libdns",
        "@isc_dhcp_bind_src//:libisccfg",
        "@isc_dhcp_bind_src//:libirs",
        "@isc_dhcp_bind_src//:libisc",
    ],
    visibility = ["//visibility:public"],
)

cc_binary(
    name = "dhcrelay",
    srcs = ["relay/dhcrelay.c"],
    copts = ISC_DHCP_COPTS + [
        # Hardening (matches debian/rules hardening=+all).
        "-fPIE",
        "-fstack-protector-strong",
        "-D_FORTIFY_SOURCE=2",
        "-Wformat",
    ],
    linkopts = [
        "-pthread",
        "-Wl,-z,relro,-z,now",
        "-pie",
    ],
    deps = [
        ":libdhcp",
        ":libomapi",
        "@isc_dhcp_bind_src//:libdns",
        "@isc_dhcp_bind_src//:libisccfg",
        "@isc_dhcp_bind_src//:libirs",
        "@isc_dhcp_bind_src//:libisc",
    ],
    visibility = ["//visibility:public"],
)

sonic_deb(
    name = "isc-dhcp-relay_4.4.3-P1-2.deb",
    package = "isc-dhcp-relay",
    version = "4.4.3-P1-2",
    content = {"/usr/sbin:*:0755": [":dhcrelay"]},
    maintainer = "SONiC Team <linuxnetdev@microsoft.com>",
    description = "ISC DHCP relay agent (SONiC patched build)",
    section = "net",
    homepage = "https://github.com/Azure/sonic-buildimage",
    gen_dbg = True,
    visibility = ["//visibility:public"],
)
