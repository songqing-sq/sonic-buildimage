# Bazel build for sflowtool 5.04 (commit 6c2963b).
#
# Upstream is autotools (SUBDIRS=src) building a single translation unit
# src/sflowtool.c. Approach B pragmatic rebuild: a cc_binary over sflowtool.c
# plus a genrule that materialises config.h from config.h.in (the ./configure
# output). The only config.h macro actually consumed by sflowtool.c is VERSION;
# the HAVE_* header/function probes are all satisfied on a Linux/glibc sysroot.

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

genrule(
    name = "config_h",
    srcs = ["config.h.in"],
    outs = ["config.h"],
    cmd = """
        sed \\
            -e 's|#undef HAVE_FCNTL_H|#define HAVE_FCNTL_H 1|' \\
            -e 's|#undef HAVE_GETADDRINFO|#define HAVE_GETADDRINFO 1|' \\
            -e 's|#undef HAVE_INTTYPES_H|#define HAVE_INTTYPES_H 1|' \\
            -e 's|#undef HAVE_MEMORY_H|#define HAVE_MEMORY_H 1|' \\
            -e 's|#undef HAVE_MEMSET|#define HAVE_MEMSET 1|' \\
            -e 's|#undef HAVE_NETDB_H|#define HAVE_NETDB_H 1|' \\
            -e 's|#undef HAVE_NETINET_IN_H|#define HAVE_NETINET_IN_H 1|' \\
            -e 's|#undef HAVE_SELECT|#define HAVE_SELECT 1|' \\
            -e 's|#undef HAVE_SOCKET|#define HAVE_SOCKET 1|' \\
            -e 's|#undef HAVE_STDINT_H|#define HAVE_STDINT_H 1|' \\
            -e 's|#undef HAVE_STDLIB_H|#define HAVE_STDLIB_H 1|' \\
            -e 's|#undef HAVE_STRDUP|#define HAVE_STRDUP 1|' \\
            -e 's|#undef HAVE_STRERROR|#define HAVE_STRERROR 1|' \\
            -e 's|#undef HAVE_STRFTIME|#define HAVE_STRFTIME 1|' \\
            -e 's|#undef HAVE_STRINGS_H|#define HAVE_STRINGS_H 1|' \\
            -e 's|#undef HAVE_STRING_H|#define HAVE_STRING_H 1|' \\
            -e 's|#undef HAVE_STRSPN|#define HAVE_STRSPN 1|' \\
            -e 's|#undef HAVE_STRTOL|#define HAVE_STRTOL 1|' \\
            -e 's|#undef HAVE_SYS_SELECT_H|#define HAVE_SYS_SELECT_H 1|' \\
            -e 's|#undef HAVE_SYS_SOCKET_H|#define HAVE_SYS_SOCKET_H 1|' \\
            -e 's|#undef HAVE_SYS_STAT_H|#define HAVE_SYS_STAT_H 1|' \\
            -e 's|#undef HAVE_SYS_TIME_H|#define HAVE_SYS_TIME_H 1|' \\
            -e 's|#undef HAVE_SYS_TYPES_H|#define HAVE_SYS_TYPES_H 1|' \\
            -e 's|#undef HAVE_UNISTD_H|#define HAVE_UNISTD_H 1|' \\
            -e 's|#undef HAVE_VPRINTF|#define HAVE_VPRINTF 1|' \\
            -e 's|#undef STDC_HEADERS|#define STDC_HEADERS 1|' \\
            -e 's|#undef TIME_WITH_SYS_TIME|#define TIME_WITH_SYS_TIME 1|' \\
            -e 's|#undef SELECT_TYPE_ARG1|#define SELECT_TYPE_ARG1 int|' \\
            -e 's|#undef SELECT_TYPE_ARG234|#define SELECT_TYPE_ARG234 (fd_set *)|' \\
            -e 's|#undef SELECT_TYPE_ARG5|#define SELECT_TYPE_ARG5 (struct timeval *)|' \\
            -e 's|#undef PACKAGE_BUGREPORT|#define PACKAGE_BUGREPORT ""|' \\
            -e 's|#undef PACKAGE_NAME|#define PACKAGE_NAME "sflowtool"|' \\
            -e 's|#undef PACKAGE_STRING|#define PACKAGE_STRING "sflowtool 5.04"|' \\
            -e 's|#undef PACKAGE_TARNAME|#define PACKAGE_TARNAME "sflowtool"|' \\
            -e 's|#undef PACKAGE_URL|#define PACKAGE_URL ""|' \\
            -e 's|#undef PACKAGE_VERSION|#define PACKAGE_VERSION "5.04"|' \\
            -e 's|#undef PACKAGE\\b|#define PACKAGE "sflowtool"|' \\
            -e 's|#undef VERSION|#define VERSION "5.04"|' \\
            $< > $@
    """,
)

# Header library carrying config.h + the in-tree sFlow headers, with include
# search paths for the external repo root (config.h) and src/ (sflow*.h).
cc_library(
    name = "sflowtool_headers",
    hdrs = [
        "src/sflow.h",
        "src/sflow_v2v4.h",
        ":config_h",
    ],
    includes = [
        ".",
        "src",
    ],
)

cc_binary(
    name = "sflowtool",
    srcs = ["src/sflowtool.c"],
    copts = [
        "-D_GNU_SOURCE",
        "-Wno-unused-parameter",
        "-Wno-unused-but-set-variable",
        "-Wno-deprecated-declarations",
    ],
    deps = [":sflowtool_headers"],
)
