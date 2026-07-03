# Bazel build for BIND 9.11.36 sublibs used by isc-dhcp's dhcrelay.
# Produces libisc, libdns, libisccfg, libirs as cc_library targets,
# matching the OBJS lists in upstream BIND's Makefile.in for Linux x86_64
# with --enable-paranoia --enable-log-pid --enable-use-sockets and no
# OpenSSL/PKCS11/GSSAPI/GeoIP/dnstap (the dhcrelay-only build profile from
# isc-dhcp's debian/rules).

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "all_sources",
    srcs = glob(
        [
            "lib/isc/**/*.c",
            "lib/isc/**/*.h",
            "lib/dns/**/*.c",
            "lib/dns/**/*.h",
            "lib/isccfg/**/*.c",
            "lib/isccfg/**/*.h",
            "lib/irs/**/*.c",
            "lib/irs/**/*.h",
        ],
        allow_empty = True,
    ),
)

# =============================================================================
# Generated lib/isc/include/isc/platform.h
# =============================================================================
#
# platform.h.in has 61 @TOKEN@ substitutions. For Linux x86_64 with pthreads,
# IPv6, epoll, and GCC atomics, the substitutions below mirror what BIND's
# configure script would produce. Tokens that should remain "not defined" are
# replaced with an empty C comment so the resulting file still compiles.

genrule(
    name = "platform_h",
    srcs = ["lib/isc/include/isc/platform.h.in"],
    outs = ["lib/isc/include/isc/platform.h"],
    cmd = """
        sed \\
            -e 's|@ISC_PLATFORM_HAVELONGLONG@|#define ISC_PLATFORM_HAVELONGLONG 1|' \\
            -e 's|@ISC_PLATFORM_HAVEIPV6@|#define ISC_PLATFORM_HAVEIPV6 1|' \\
            -e 's|@ISC_PLATFORM_HAVEIN6PKTINFO@|#define ISC_PLATFORM_HAVEIN6PKTINFO 1|' \\
            -e 's|@ISC_PLATFORM_HAVESCOPEID@|#define ISC_PLATFORM_HAVESCOPEID 1|' \\
            -e 's|@ISC_PLATFORM_HAVEIFNAMETOINDEX@|#define ISC_PLATFORM_HAVEIFNAMETOINDEX 1|' \\
            -e 's|@ISC_PLATFORM_HAVESOCKADDRSTORAGE@|#define ISC_PLATFORM_HAVESOCKADDRSTORAGE 1|' \\
            -e 's|@ISC_PLATFORM_HAVEEPOLL@|#define ISC_PLATFORM_HAVEEPOLL 1|' \\
            -e 's|@ISC_PLATFORM_HAVELIFCONF@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_HAVEIF_LADDRCONF@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_HAVEIF_LADDRREQ@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_HAVEKQUEUE@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_HAVEDEVPOLL@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_HAVESALEN@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_HAVESYSUNH@|#define ISC_PLATFORM_HAVESYSUNH 1|' \\
            -e 's|@ISC_PLATFORM_HAVESTATNSEC@|#define ISC_PLATFORM_HAVESTATNSEC 1|' \\
            -e 's|@ISC_PLATFORM_HAVEINADDR6@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_HAVETFO@|#define ISC_PLATFORM_HAVETFO 1|' \\
            -e 's|@ISC_PLATFORM_USETHREADS@|#define ISC_PLATFORM_USETHREADS 1|' \\
            -e 's|@ISC_PLATFORM_USEGCCASM@|#define ISC_PLATFORM_USEGCCASM 1|' \\
            -e 's|@ISC_PLATFORM_USESTDASM@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_USEMACASM@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_USEOSFASM@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_USEDECLSPEC@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_HAVECMPXCHG@|#define ISC_PLATFORM_HAVECMPXCHG 1|' \\
            -e 's|@ISC_PLATFORM_HAVEXADD@|#define ISC_PLATFORM_HAVEXADD 1|' \\
            -e 's|@ISC_PLATFORM_HAVEXADDQ@|#define ISC_PLATFORM_HAVEXADDQ 1|' \\
            -e 's|@ISC_PLATFORM_HAVEATOMICSTORE@|#define ISC_PLATFORM_HAVEATOMICSTORE 1|' \\
            -e 's|@ISC_PLATFORM_HAVEATOMICSTOREQ@|#define ISC_PLATFORM_HAVEATOMICSTOREQ 1|' \\
            -e 's|@ISC_PLATFORM_HAVESTDATOMIC@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_BUSYWAITNOP@|#define ISC_PLATFORM_BUSYWAITNOP do { __asm__ volatile("rep; nop"); } while(0)|' \\
            -e 's|@ISC_PLATFORM_BRACEPTHREADONCEINIT@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_FIXIN6ISADDR@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_MSGHDRFLAVOR@|#define ISC_NET_BSD44MSGHDR 1|' \\
            -e 's|@ISC_PLATFORM_NEEDNETINETIN6H@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_NEEDNETINET6IN6H@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_NEEDIN6ADDRANY@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_NEEDIN6ADDRLOOPBACK@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_NEEDPORTT@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_NEEDNTOP@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_NEEDPTON@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_NEEDVSNPRINTF@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_NEEDPRINTF@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_NEEDFPRINTF@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_NEEDSPRINTF@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_NEEDMEMMOVE@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_NEEDSTRSEP@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_NEEDSTRLCPY@|#define ISC_PLATFORM_NEEDSTRLCPY 1|' \\
            -e 's|@ISC_PLATFORM_NEEDSTRLCAT@|#define ISC_PLATFORM_NEEDSTRLCAT 1|' \\
            -e 's|@ISC_PLATFORM_NEEDSTRTOUL@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_NEEDSYSSELECTH@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_NEEDSTRCASESTR@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_HAVESTRINGSH@|#define ISC_PLATFORM_HAVESTRINGSH 1|' \\
            -e 's|@ISC_PLATFORM_NORETURN_PRE@|#define ISC_PLATFORM_NORETURN_PRE|' \\
            -e 's|@ISC_PLATFORM_NORETURN_POST@|#define ISC_PLATFORM_NORETURN_POST __attribute__((noreturn))|' \\
            -e 's|@ISC_PLATFORM_RLIMITTYPE@|#define ISC_PLATFORM_RLIMITTYPE rlim_t|' \\
            -e 's|@ISC_PLATFORM_USEBACKTRACE@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_OPENSSLHASH@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_WANTAES@|#define ISC_PLATFORM_WANTAES 1|' \\
            -e 's|@ISC_PLATFORM_GSSAPIHEADER@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_GSSAPI_KRB5_HEADER@|/* not defined */|' \\
            -e 's|@ISC_PLATFORM_KRB5HEADER@|/* not defined */|' \\
            $(SRCS) > $(OUTS)
    """ + select({
        "@platforms//cpu:aarch64": """
        sed -i \\
            -e 's|#define ISC_PLATFORM_USEGCCASM 1|/* not defined */|' \\
            -e 's|#define ISC_PLATFORM_HAVECMPXCHG 1|/* not defined */|' \\
            -e 's|#define ISC_PLATFORM_HAVEXADD 1|/* not defined */|' \\
            -e 's|#define ISC_PLATFORM_HAVEXADDQ 1|/* not defined */|' \\
            -e 's|#define ISC_PLATFORM_HAVEATOMICSTORE 1|/* not defined */|' \\
            -e 's|#define ISC_PLATFORM_HAVEATOMICSTOREQ 1|/* not defined */|' \\
            -e '/not defined.*ISC_PLATFORM_HAVESTDATOMIC/c\\#define ISC_PLATFORM_HAVESTDATOMIC 1' \\
            -e 's|__asm__ volatile("rep; nop")|__asm__ volatile("yield")|' \\
            $(OUTS)
    """,
        "//conditions:default": "",
    }),
)

# =============================================================================
# Generated config.h
# =============================================================================
#
# Mirrors libnl3's defs_h pattern. Tokens kept as #undef remain undefined
# (BIND code uses #ifdef checks throughout).

genrule(
    name = "bind_config_h",
    srcs = ["config.h.in"],
    outs = ["config.h"],
    cmd = """
        sed \\
            -e 's|#undef HAVE_GETIFADDRS|#define HAVE_GETIFADDRS 1|' \\
            -e 's|#undef HAVE_GETADDRINFO|#define HAVE_GETADDRINFO 1|' \\
            -e 's|#undef HAVE_GETPASSPHRASE|#define HAVE_GETPASSPHRASE 1|' \\
            -e 's|#undef HAVE_IF_NAMETOINDEX|#define HAVE_IF_NAMETOINDEX 1|' \\
            -e 's|#undef HAVE_NANOSLEEP|#define HAVE_NANOSLEEP 1|' \\
            -e 's|#undef HAVE_PTHREAD_SETNAME_NP|#define HAVE_PTHREAD_SETNAME_NP 1|' \\
            -e 's|#undef HAVE_SETLOCALE|#define HAVE_SETLOCALE 1|' \\
            -e 's|#undef HAVE_USLEEP|#define HAVE_USLEEP 1|' \\
            -e 's|#undef HAVE_UNAME|#define HAVE_UNAME 1|' \\
            -e 's|#undef HAVE_LIBPTHREAD|#define HAVE_LIBPTHREAD 1|' \\
            -e 's|#undef HAVE_LINUX_NETLINK_H|#define HAVE_LINUX_NETLINK_H 1|' \\
            -e 's|#undef HAVE_LINUX_RTNETLINK_H|#define HAVE_LINUX_RTNETLINK_H 1|' \\
            -e 's|#undef HAVE_LINUX_TYPES_H|#define HAVE_LINUX_TYPES_H 1|' \\
            -e 's|#undef HAVE_PTHREAD_ATTR_GETSTACKSIZE|#define HAVE_PTHREAD_ATTR_GETSTACKSIZE 1|' \\
            -e 's|#undef HAVE_PTHREAD_ATTR_SETSTACKSIZE|#define HAVE_PTHREAD_ATTR_SETSTACKSIZE 1|' \\
            -e 's|#undef HAVE_PTHREAD_MUTEX_ADAPTIVE_NP|#define HAVE_PTHREAD_MUTEX_ADAPTIVE_NP 1|' \\
            -e 's|#undef HAVE_PTHREAD_YIELD|#define HAVE_PTHREAD_YIELD 1|' \\
            -e 's|#undef HAVE_SCHED_H|#define HAVE_SCHED_H 1|' \\
            -e 's|#undef HAVE_SCHED_YIELD|#define HAVE_SCHED_YIELD 1|' \\
            -e 's|#undef HAVE_SETEGID|#define HAVE_SETEGID 1|' \\
            -e 's|#undef HAVE_SETEUID|#define HAVE_SETEUID 1|' \\
            -e 's|#undef HAVE_SETRESGID|#define HAVE_SETRESGID 1|' \\
            -e 's|#undef HAVE_SETRESUID|#define HAVE_SETRESUID 1|' \\
            -e 's|#undef HAVE_SIGWAIT|#define HAVE_SIGWAIT 1|' \\
            -e 's|#undef HAVE_SYSCONF|#define HAVE_SYSCONF 1|' \\
            -e 's|#undef HAVE_CLOCK_GETTIME|#define HAVE_CLOCK_GETTIME 1|' \\
            -e 's|#undef HAVE_FCNTL_H|#define HAVE_FCNTL_H 1|' \\
            -e 's|#undef HAVE_FLOCKFILE|#define HAVE_FLOCKFILE 1|' \\
            -e 's|#undef HAVE_FSEEKO|#define HAVE_FSEEKO 1|' \\
            -e 's|#undef HAVE_FTELLO|#define HAVE_FTELLO 1|' \\
            -e 's|#undef HAVE_GETCUNLOCKED|#define HAVE_GETCUNLOCKED 1|' \\
            -e 's|#undef HAVE_DLFCN_H|#define HAVE_DLFCN_H 1|' \\
            -e 's|#undef HAVE_DLOPEN|#define HAVE_DLOPEN 1|' \\
            -e 's|#undef HAVE_DLCLOSE|#define HAVE_DLCLOSE 1|' \\
            -e 's|#undef HAVE_DLSYM|#define HAVE_DLSYM 1|' \\
            -e 's|#undef HAVE_INTTYPES_H|#define HAVE_INTTYPES_H 1|' \\
            -e 's|#undef HAVE_LOCALE_H|#define HAVE_LOCALE_H 1|' \\
            -e 's|#undef HAVE_MEMORY_H|#define HAVE_MEMORY_H 1|' \\
            -e 's|#undef HAVE_MMAP|#define HAVE_MMAP 1|' \\
            -e 's|#undef HAVE_REGEX_H|#define HAVE_REGEX_H 1|' \\
            -e 's|#undef HAVE_STDINT_H|#define HAVE_STDINT_H 1|' \\
            -e 's|#undef HAVE_STDLIB_H|#define HAVE_STDLIB_H 1|' \\
            -e 's|#undef HAVE_STRERROR|#define HAVE_STRERROR 1|' \\
            -e 's|#undef HAVE_STRINGS_H|#define HAVE_STRINGS_H 1|' \\
            -e 's|#undef HAVE_STRING_H|#define HAVE_STRING_H 1|' \\
            -e 's|#undef HAVE_SYS_MMAN_H|#define HAVE_SYS_MMAN_H 1|' \\
            -e 's|#undef HAVE_SYS_PARAM_H|#define HAVE_SYS_PARAM_H 1|' \\
            -e 's|#undef HAVE_SYS_PRCTL_H|#define HAVE_SYS_PRCTL_H 1|' \\
            -e 's|#undef HAVE_SYS_SELECT_H|#define HAVE_SYS_SELECT_H 1|' \\
            -e 's|#undef HAVE_SYS_SOCKET_H|#define HAVE_SYS_SOCKET_H 1|' \\
            -e 's|#undef HAVE_SYS_STAT_H|#define HAVE_SYS_STAT_H 1|' \\
            -e 's|#undef HAVE_SYS_TIME_H|#define HAVE_SYS_TIME_H 1|' \\
            -e 's|#undef HAVE_SYS_TYPES_H|#define HAVE_SYS_TYPES_H 1|' \\
            -e 's|#undef HAVE_SYS_UN_H|#define HAVE_SYS_UN_H 1|' \\
            -e 's|#undef HAVE_TZSET|#define HAVE_TZSET 1|' \\
            -e 's|#undef HAVE_UINTPTR_T|#define HAVE_UINTPTR_T 1|' \\
            -e 's|#undef HAVE_UNISTD_H|#define HAVE_UNISTD_H 1|' \\
            -e 's|#undef HAVE_BUILTIN_CLZ|#define HAVE_BUILTIN_CLZ 1|' \\
            -e 's|#undef HAVE_BUILTIN_EXPECT|#define HAVE_BUILTIN_EXPECT 1|' \\
            -e 's|#undef HAVE_BUILTIN_UNREACHABLE|#define HAVE_BUILTIN_UNREACHABLE 1|' \\
            -e 's|#undef HAVE_EXPLICIT_BZERO|#define HAVE_EXPLICIT_BZERO 1|' \\
            -e 's|#undef HAVE_GETRANDOM|#define HAVE_GETRANDOM 1|' \\
            -e 's|#undef HAVE_CHROOT|#define HAVE_CHROOT 1|' \\
            -e 's|#undef ISC_BUFFER_USEINLINE|#define ISC_BUFFER_USEINLINE 1|' \\
            -e 's|#undef ISC_SOCKADDR_LEN_T|#define ISC_SOCKADDR_LEN_T socklen_t|' \\
            -e 's|#undef IRS_GETNAMEINFO_BUFLEN_T|#define IRS_GETNAMEINFO_BUFLEN_T socklen_t|' \\
            -e 's|#undef IRS_GETNAMEINFO_FLAGS_T|#define IRS_GETNAMEINFO_FLAGS_T int|' \\
            -e 's|#undef IRS_GETNAMEINFO_SOCKLEN_T|#define IRS_GETNAMEINFO_SOCKLEN_T socklen_t|' \\
            -e 's|#undef IRS_GAISTRERROR_RETURN_T|#define IRS_GAISTRERROR_RETURN_T const char *|' \\
            -e 's|#undef SIZEOF_VOID_P|#define SIZEOF_VOID_P 8|' \\
            -e 's|#undef STDC_HEADERS|#define STDC_HEADERS 1|' \\
            -e 's|#undef TIME_WITH_SYS_TIME|#define TIME_WITH_SYS_TIME 1|' \\
            -e 's|#undef WANT_IPV6|#define WANT_IPV6 1|' \\
            -e 's|#undef PACKAGE_NAME|#define PACKAGE_NAME "BIND"|' \\
            -e 's|#undef PACKAGE_TARNAME|#define PACKAGE_TARNAME "bind"|' \\
            -e 's|#undef PACKAGE_VERSION|#define PACKAGE_VERSION "9.11.36"|' \\
            -e 's|#undef PACKAGE_STRING|#define PACKAGE_STRING "BIND 9.11.36"|' \\
            -e 's|#undef PACKAGE_BUGREPORT|#define PACKAGE_BUGREPORT "bind9-bugs@isc.org"|' \\
            -e 's|#undef PACKAGE_URL|#define PACKAGE_URL ""|' \\
            -e 's|#undef LT_OBJDIR|#define LT_OBJDIR ".libs/"|' \\
            -e 's|#undef FLEXIBLE_ARRAY_MEMBER|#define FLEXIBLE_ARRAY_MEMBER /**/|' \\
            -e 's|#undef PATH_RANDOMDEV|#define PATH_RANDOMDEV "/dev/random"|' \\
            -e 's|#undef PORT_NONBLOCK|#define PORT_NONBLOCK O_NONBLOCK|' \\
            $(SRCS) > $(OUTS)
    """,
)

# =============================================================================
# libisc
# =============================================================================

cc_library(
    name = "libisc",
    srcs = glob(
        [
            "lib/isc/*.c",
            "lib/isc/unix/*.c",
            "lib/isc/pthreads/*.c",
            "lib/isc/nls/*.c",
        ],
        allow_empty = True,
        exclude = [
            "lib/isc/win32/**",
            "lib/isc/**/test*.c",
            "lib/isc/**/t_*.c",
            # Not in OBJS (stub *_api.c are replaced by unix/<name>.c)
            "lib/isc/app_api.c",
            "lib/isc/socket_api.c",
            "lib/isc/entropy.c",
            "lib/isc/fsaccess.c",
            # PKCS11 - not enabled
            "lib/isc/pk11.c",
            "lib/isc/pk11_result.c",
            "lib/isc/unix/pk11_api.c",
            # IPv6 stubs - only used when system lacks IPv6
            "lib/isc/unix/ipv6.c",
            # Included via #include from interfaceiter.c, not built standalone
            "lib/isc/unix/ifiter_getifaddrs.c",
            "lib/isc/unix/ifiter_sysctl.c",
            "lib/isc/unix/ifiter_ioctl.c",
            # glibc has inet_pton/ntop; only inet_aton is bundled in OBJS
            "lib/isc/inet_ntop.c",
            "lib/isc/inet_pton.c",
            # not in OBJS
            "lib/isc/print.c",
        ],
    ) + [
        ":platform_h",
        ":bind_config_h",
    ],
    hdrs = glob(
        [
            "lib/isc/*.h",
            "lib/isc/include/**/*.h",
            "lib/isc/unix/*.h",
            "lib/isc/unix/include/**/*.h",
            "lib/isc/pthreads/include/**/*.h",
            "lib/isc/x86_32/include/**/*.h",
            "lib/isc/noatomic/include/**/*.h",
        ],
        allow_empty = True,
    ),
    textual_hdrs = [
        # Included via #include "..." from interfaceiter.c
        "lib/isc/unix/ifiter_getifaddrs.c",
        "lib/isc/unix/ifiter_sysctl.c",
        "lib/isc/unix/ifiter_ioctl.c",
        # #included from unix/<name>.c (top-level *_api / stub C is template body)
        "lib/isc/app_api.c",
        "lib/isc/socket_api.c",
        "lib/isc/entropy.c",
        "lib/isc/fsaccess.c",
    ],
    includes = [
        ".",
        "lib/isc",
        "lib/isc/include",
        "lib/isc/pthreads/include",
        "lib/isc/unix",
        "lib/isc/unix/include",
        ] + select({
        "@platforms//cpu:x86_64": ["lib/isc/x86_32/include"],
        "@platforms//cpu:aarch64": ["lib/isc/noatomic/include"],
    }) + [
    ],
    copts = [
        "-D_GNU_SOURCE",
        "-D_REENTRANT",
        "-DSYSCONFDIR=\\\"/etc/bind\\\"",
        "-DVERSION=\\\"9.11.36\\\"",
        "-DLIBINTERFACE=1107",
        "-DLIBREVISION=7",
        "-DLIBAGE=0",
        "-w",
    ] + select({
        "@platforms//cpu:aarch64": ["-DUSE_STDATOMIC"],
        "//conditions:default": [],
    }),
    linkopts = ["-pthread"],
    visibility = ["//visibility:public"],
)

# =============================================================================
# libdns code generation: gen.c host tool + 4 generated headers
# =============================================================================

cc_binary(
    name = "dns_gen",
    srcs = [
        "lib/dns/gen.c",
        "lib/dns/gen-unix.h",
        ":platform_h",
        ":bind_config_h",
    ] + glob(["lib/isc/include/**/*.h"]),
    includes = [
        ".",
        "lib/isc/include",
        "lib/isc/unix/include",
        "lib/isc/pthreads/include",
        ] + select({
        "@platforms//cpu:x86_64": ["lib/isc/x86_32/include"],
        "@platforms//cpu:aarch64": ["lib/isc/noatomic/include"],
    }) + [
    ],
    copts = ["-w"],
)

# rdata files needed by gen.c at codegen time. Glob keeps the list in sync
# with whatever rdata/<class>/<type>_<num>.[hc] files BIND ships.
filegroup(
    name = "dns_rdata_files",
    srcs = glob([
        "lib/dns/rdata/**/*.h",
        "lib/dns/rdata/**/*.c",
    ]),
)

# gen.c expects -s <dir-containing-rdata>. We pass lib/dns; the cmd extracts
# that prefix from any one rdata file location to be hermetic against bazel
# execroot relocation.
genrule(
    name = "dns_enumtype_h",
    srcs = [":dns_rdata_files"] + ["lib/dns/rdata/rdatastructpre.h"],
    outs = ["lib/dns/include/dns/enumtype.h"],
    tools = [":dns_gen"],
    cmd = "DIR=$$(dirname $(location lib/dns/rdata/rdatastructpre.h))/..; $(location :dns_gen) -s $$DIR -t | sed \"s|$$DIR/||g\" > $@",
)

genrule(
    name = "dns_enumclass_h",
    srcs = [":dns_rdata_files"] + ["lib/dns/rdata/rdatastructpre.h"],
    outs = ["lib/dns/include/dns/enumclass.h"],
    tools = [":dns_gen"],
    cmd = "DIR=$$(dirname $(location lib/dns/rdata/rdatastructpre.h))/..; $(location :dns_gen) -s $$DIR -c | sed \"s|$$DIR/||g\" > $@",
)

genrule(
    name = "dns_rdatastruct_h",
    srcs = [":dns_rdata_files"] + [
        "lib/dns/rdata/rdatastructpre.h",
        "lib/dns/rdata/rdatastructsuf.h",
    ],
    outs = ["lib/dns/include/dns/rdatastruct.h"],
    tools = [":dns_gen"],
    cmd = "DIR=$$(dirname $(location lib/dns/rdata/rdatastructpre.h))/..; $(location :dns_gen) -s $$DIR -i -P $(location lib/dns/rdata/rdatastructpre.h) -S $(location lib/dns/rdata/rdatastructsuf.h) | sed \"s|$$DIR/||g\" > $@",
)

genrule(
    name = "dns_code_h",
    srcs = [":dns_rdata_files"] + ["lib/dns/rdata/rdatastructpre.h"],
    outs = ["lib/dns/code.h"],
    tools = [":dns_gen"],
    cmd = "DIR=$$(dirname $(location lib/dns/rdata/rdatastructpre.h))/..; $(location :dns_gen) -s $$DIR | sed \"s|$$DIR/||g\" > $@",
)

# =============================================================================
# libdns
# =============================================================================

cc_library(
    name = "libdns",
    srcs = glob(
        ["lib/dns/*.c"],
        allow_empty = True,
        exclude = [
            "lib/dns/win32/**",
            "lib/dns/**/test*.c",
            "lib/dns/**/t_*.c",
            "lib/dns/gen.c",
            # OpenSSL-backed crypto (we use bundled MD5/SHA from libisc)
            "lib/dns/dst_openssl.c",
            "lib/dns/openssl_link.c",
            "lib/dns/openssldh_link.c",
            "lib/dns/openssldsa_link.c",
            "lib/dns/opensslecdsa_link.c",
            "lib/dns/openssleddsa_link.c",
            "lib/dns/opensslgost_link.c",
            "lib/dns/opensslrsa_link.c",
            # GSSAPI/Kerberos: gssapi_link.c and gssapictx.c are both in the
            # unconditional DSTOBJS list upstream — they compile fully under
            # !GSSAPI (gssapi_link.c becomes an empty .o; gssapictx.c emits
            # the #else stub branch). Keep both. spnego.c and spnego_asn1.c
            # don't exist in BIND 9.11.36 (no-op excludes).
            "lib/dns/spnego.c",
            "lib/dns/spnego_asn1.c",
            # PKCS11
            "lib/dns/dst_pkcs11.c",
            "lib/dns/pkcs11.c",
            "lib/dns/pkcs11dh_link.c",
            "lib/dns/pkcs11dsa_link.c",
            "lib/dns/pkcs11ecdsa_link.c",
            "lib/dns/pkcs11eddsa_link.c",
            "lib/dns/pkcs11gost_link.c",
            "lib/dns/pkcs11rsa_link.c",
            # dnstap (needs protobuf-c)
            "lib/dns/dnstap.c",
            # GeoIP
            "lib/dns/geoip.c",
            "lib/dns/geoip2.c",
        ],
    ) + [
        ":dns_code_h",
        ":dns_enumtype_h",
        ":dns_enumclass_h",
        ":dns_rdatastruct_h",
    ],
    hdrs = glob(
        [
            "lib/dns/*.h",
            "lib/dns/include/**/*.h",
            "lib/dns/rdata/**/*.h",
            "lib/dns/rdata/**/*.c",
        ],
        allow_empty = True,
    ),
    textual_hdrs = [
        # rbtdb64.c is itself compiled but does #include "rbtdb.c"
        "lib/dns/rbtdb.c",
    ],
    includes = [
        "lib/dns",
        "lib/dns/include",
    ],
    copts = [
        "-D_GNU_SOURCE",
        "-D_REENTRANT",
        "-DUSE_MD5",
        "-DVERSION=\\\"9.11.36\\\"",
        "-DMAJOR=\\\"9.11\\\"",
        "-DMAPAPI=\\\"1.0\\\"",
        "-DLIBINTERFACE=1115",
        "-DLIBREVISION=3",
        "-DLIBAGE=0",
        "-DSYSCONFDIR=\\\"/etc/bind\\\"",
        "-w",
    ],
    deps = [":libisc"],
    visibility = ["//visibility:public"],
)

# =============================================================================
# libisccfg
# =============================================================================

cc_library(
    name = "libisccfg",
    srcs = glob(
        ["lib/isccfg/*.c"],
        allow_empty = True,
        exclude = [
            "lib/isccfg/win32/**",
            "lib/isccfg/**/test*.c",
            "lib/isccfg/**/t_*.c",
        ],
    ),
    hdrs = glob(
        ["lib/isccfg/include/**/*.h"],
        allow_empty = True,
    ),
    includes = ["lib/isccfg/include"],
    copts = [
        "-D_GNU_SOURCE",
        "-D_REENTRANT",
        "-DVERSION=\\\"9.11.36\\\"",
        "-DLIBINTERFACE=163",
        "-DLIBREVISION=8",
        "-DLIBAGE=0",
        "-w",
    ],
    deps = [
        ":libisc",
        ":libdns",
    ],
    visibility = ["//visibility:public"],
)

# =============================================================================
# Generated lib/irs/include/irs/platform.h
# =============================================================================
#
# irs/platform.h.in has no @TOKEN@ substitutions; just strip the .in suffix.

genrule(
    name = "irs_platform_h",
    srcs = ["lib/irs/include/irs/platform.h.in"],
    outs = ["lib/irs/include/irs/platform.h"],
    cmd = "cp $(SRCS) $(OUTS)",
)

# =============================================================================
# Generated lib/irs/include/irs/netdb.h
# =============================================================================
#
# Single token: @ISC_IRS_NEEDADDRINFO@. On Linux glibc, struct addrinfo is
# provided by <netdb.h>, so emit "#undef ISC_IRS_NEEDADDRINFO".

genrule(
    name = "irs_netdb_h",
    srcs = ["lib/irs/include/irs/netdb.h.in"],
    outs = ["lib/irs/include/irs/netdb.h"],
    cmd = """
        sed \\
            -e 's|@ISC_IRS_NEEDADDRINFO@|#undef ISC_IRS_NEEDADDRINFO|' \\
            $(SRCS) > $(OUTS)
    """,
)

# =============================================================================
# libirs
# =============================================================================

cc_library(
    name = "libirs",
    srcs = glob(
        ["lib/irs/*.c"],
        allow_empty = True,
        exclude = [
            "lib/irs/win32/**",
            "lib/irs/**/test*.c",
            "lib/irs/**/t_*.c",
        ],
    ) + [
        ":irs_platform_h",
        ":irs_netdb_h",
    ],
    hdrs = glob(
        ["lib/irs/include/**/*.h"],
        allow_empty = True,
    ),
    includes = ["lib/irs/include"],
    copts = [
        "-D_GNU_SOURCE",
        "-D_REENTRANT",
        "-DVERSION=\\\"9.11.36\\\"",
        "-DLIBINTERFACE=161",
        "-DLIBREVISION=1",
        "-DLIBAGE=0",
        "-w",
    ],
    deps = [
        ":libisc",
        ":libdns",
        ":libisccfg",
    ],
    visibility = ["//visibility:public"],
)
