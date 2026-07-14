load("@rules_flex//flex:flex.bzl", "flex")
load("@rules_bison//bison:bison.bzl", "bison")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@sonic_build_infra//shared_library:shared_library.bzl", "sonic_shared_library", "sonic_shared_library_versioned", "static_archive")
load("@sonic_build_infra//sonic_deb:sonic_deb.bzl", "sonic_deb")

LIBNL_VERSION = "3.7.0-0.2+b1sonic1"
LIBNL_SOVERSION = "200.26.0"
LIBNL_COPTS = [
    "-std=gnu11",
    "-Wall",
    "-D_GNU_SOURCE",
#    "-I{REPO_DIR}/include/linux-private",
    "-Wno-unused-parameter",
    "-Wno-sign-compare",
    "-Wno-format-truncation",
    "-Wno-maybe-uninitialized",
    "-Wno-return-type",
]

# =============================================================================
# Generated headers
# =============================================================================

genrule(
    name = "defs_h",
    srcs = ["lib/defs.h.in"],
    outs = ["lib/defs.h"],
    cmd = """
        sed \\
            -e 's|#undef DISABLE_PTHREADS|/* #undef DISABLE_PTHREADS */|' \\
            -e 's|#undef HAVE_DLFCN_H|#define HAVE_DLFCN_H 1|' \\
            -e 's|#undef HAVE_INTTYPES_H|#define HAVE_INTTYPES_H 1|' \\
            -e 's|#undef HAVE_LIBPTHREAD|#define HAVE_LIBPTHREAD 1|' \\
            -e 's|#undef HAVE_STDINT_H|#define HAVE_STDINT_H 1|' \\
            -e 's|#undef HAVE_STDIO_H|#define HAVE_STDIO_H 1|' \\
            -e 's|#undef HAVE_STDLIB_H|#define HAVE_STDLIB_H 1|' \\
            -e 's|#undef HAVE_STRERROR_L|#define HAVE_STRERROR_L 1|' \\
            -e 's|#undef HAVE_STRINGS_H|#define HAVE_STRINGS_H 1|' \\
            -e 's|#undef HAVE_STRING_H|#define HAVE_STRING_H 1|' \\
            -e 's|#undef HAVE_SYS_STAT_H|#define HAVE_SYS_STAT_H 1|' \\
            -e 's|#undef HAVE_SYS_TYPES_H|#define HAVE_SYS_TYPES_H 1|' \\
            -e 's|#undef HAVE_UNISTD_H|#define HAVE_UNISTD_H 1|' \\
            -e 's|#undef LT_OBJDIR|#define LT_OBJDIR ".libs/"|' \\
            -e 's|#undef NL_DEBUG|/* #undef NL_DEBUG */|' \\
            -e 's/#undef PACKAGE$$/#define PACKAGE "libnl"/' \\
            -e 's|#undef PACKAGE_BUGREPORT|#define PACKAGE_BUGREPORT "http://www.infradead.org/~tgr/libnl/"|' \\
            -e 's|#undef PACKAGE_NAME|#define PACKAGE_NAME "libnl"|' \\
            -e 's|#undef PACKAGE_STRING|#define PACKAGE_STRING "libnl 3.7.0"|' \\
            -e 's|#undef PACKAGE_TARNAME|#define PACKAGE_TARNAME "libnl"|' \\
            -e 's|#undef PACKAGE_URL|#define PACKAGE_URL "http://www.infradead.org/~tgr/libnl/"|' \\
            -e 's|#undef PACKAGE_VERSION|#define PACKAGE_VERSION "3.7.0"|' \\
            -e 's|#undef STDC_HEADERS|#define STDC_HEADERS 1|' \\
            -e 's|#undef VERSION|#define VERSION "3.7.0"|' \\
            $(SRCS) > $(OUTS) && \\
        echo '#define SYSCONFDIR "/etc/libnl"' >> $(OUTS)
    """,
)

# =============================================================================
# Flex/Bison generated sources for libnl-route-3
# =============================================================================

flex(
    name = "pktloc_grammar",
    src = "lib/route/pktloc_grammar.l",
)

bison(
    name = "pktloc_syntax",
    src = "lib/route/pktloc_syntax.y",
)

flex(
    name = "ematch_grammar",
    src = "lib/route/cls/ematch_grammar.l",
)

bison(
    name = "ematch_syntax",
    src = "lib/route/cls/ematch_syntax.y",
)

# =============================================================================
# Header libraries
# =============================================================================

filegroup(
    name = "etc_files",
    srcs = [
        "etc/classid",
        "etc/pktloc",
    ],
)

cc_library(
    name = "private_headers",
    hdrs = glob([
        "include/netlink-private/**/*.h",
        "include/linux-private/**/*.h"
    ]) + [":defs_h"],
    includes = ["include", "include/linux-private", "lib"],
    #strip_include_prefix = "include",
)

# =============================================================================
# Core library: libnl-3
# =============================================================================

sonic_shared_library_versioned(
    name = "libnl_3",
    srcs = glob(["lib/*.c"]),
    hdrs = glob(["include/netlink/**/*.h"]),
    strip_include_prefix = "include",
    copts = LIBNL_COPTS,
    implementation_deps = [
        ":private_headers",
    ],
    soversion = "200",
    version = LIBNL_SOVERSION,
    output_name = "libnl-3",
    version_script = "libnl-3.sym",
    visibility = ["//visibility:public"],
)

# =============================================================================
# Generic Netlink library: libnl-genl-3
# =============================================================================

sonic_shared_library_versioned(
    name = "libnl_genl_3",
    srcs = glob(["lib/genl/*.c"]),
    copts = LIBNL_COPTS,
    deps = [
        ":libnl_3",
    ],
    implementation_deps = [
        ":private_headers",
    ],
    soversion = "200",
    version = LIBNL_SOVERSION,
    output_name = "libnl-genl-3",
    dynamic_deps = [":libnl_3_shared"],
    version_script = "libnl-genl-3.sym",
    visibility = ["//visibility:public"],
)

# =============================================================================
# Route library: libnl-route-3
# =============================================================================

sonic_shared_library_versioned(
    name = "libnl_route_3",
    srcs = glob([
        "lib/route/*.c",
        "lib/route/**/*.c",
        "lib/fib_lookup/*.c",
    ]) + [
        ":pktloc_grammar",
        ":ematch_grammar",
        ":pktloc_syntax",
        ":ematch_syntax",
    ],
    copts = LIBNL_COPTS,
    deps = [
        ":libnl_3",
    ],
    implementation_deps = [
        ":private_headers",
    ],
    soversion = "200",
    version = LIBNL_SOVERSION,
    output_name = "libnl-route-3",
    dynamic_deps = [":libnl_3_shared"],
    version_script = "libnl-route-3.sym",
    visibility = ["//visibility:public"],
)

# =============================================================================
# Netfilter library: libnl-nf-3
# =============================================================================

sonic_shared_library_versioned(
    name = "libnl_nf_3",
    srcs = glob(["lib/netfilter/*.c"]),
    copts = LIBNL_COPTS + [ "-Wno-pedantic",],
    deps = [
        ":libnl_3",
        ":libnl_route_3",
    ],
    implementation_deps = [
        ":private_headers",
    ],
    soversion = "200",
    version = LIBNL_SOVERSION,
    output_name = "libnl-nf-3",
    dynamic_deps = [
        ":libnl_3_shared",
        ":libnl_route_3_shared",
    ],
    version_script = "libnl-nf-3.sym",
    visibility = ["//visibility:public"],
)

# =============================================================================
# CLI library: libnl-cli-3
# =============================================================================

sonic_shared_library_versioned(
    name = "libnl_cli_3",
    srcs = glob(["src/lib/*.c"]),
    copts = LIBNL_COPTS,
    defines = select({
        "@platforms//cpu:x86_64": ['PKGLIBDIR=\\"/usr/lib/x86_64-linux-gnu/libnl\\"'],
        "@platforms//cpu:aarch64": ['PKGLIBDIR=\\"/usr/lib/aarch64-linux-gnu/libnl\\"'],
    }),
    deps = [
        ":libnl_3",
        ":libnl_genl_3",
        ":libnl_nf_3",
        ":libnl_route_3",
    ],
    implementation_deps = [
        ":private_headers",
    ],
    soversion = "200",
    version = LIBNL_SOVERSION,
    output_name = "libnl-cli-3",
    dynamic_deps = [
        ":libnl_3_shared",
        ":libnl_genl_3_shared",
        ":libnl_nf_3_shared",
        ":libnl_route_3_shared",
    ],
    version_script = "libnl-cli-3.sym",
    visibility = ["//visibility:public"],
)

# =============================================================================
# CLI plugin shared objects
# =============================================================================

CLI_PLUGIN_COPTS = LIBNL_COPTS
CLI_PLUGIN_DEPS = [":libnl_3", ":libnl_cli_3", ":libnl_route_3"]
CLI_PLUGIN_DYNAMIC_DEPS = [":libnl_3_shared", ":libnl_cli_3_shared", ":libnl_route_3_shared"]

sonic_shared_library(
    name = "libnl_cli_cls_basic",
    srcs = ["lib/cli/cls/basic.c"],
    copts = CLI_PLUGIN_COPTS,
    deps = CLI_PLUGIN_DEPS,
    dynamic_deps = CLI_PLUGIN_DYNAMIC_DEPS,
    output_name = "basic",
)

sonic_shared_library(
    name = "libnl_cli_cls_cgroup",
    srcs = ["lib/cli/cls/cgroup.c"],
    copts = CLI_PLUGIN_COPTS,
    deps = CLI_PLUGIN_DEPS,
    dynamic_deps = CLI_PLUGIN_DYNAMIC_DEPS,
    output_name = "cgroup",
)

sonic_shared_library(
    name = "libnl_cli_qdisc_bfifo",
    srcs = ["lib/cli/qdisc/bfifo.c"],
    copts = CLI_PLUGIN_COPTS,
    deps = CLI_PLUGIN_DEPS,
    dynamic_deps = CLI_PLUGIN_DYNAMIC_DEPS,
    output_name = "bfifo",
)

sonic_shared_library(
    name = "libnl_cli_qdisc_blackhole",
    srcs = ["lib/cli/qdisc/blackhole.c"],
    copts = CLI_PLUGIN_COPTS,
    deps = CLI_PLUGIN_DEPS,
    dynamic_deps = CLI_PLUGIN_DYNAMIC_DEPS,
    output_name = "blackhole",
)

sonic_shared_library(
    name = "libnl_cli_qdisc_fq_codel",
    srcs = ["lib/cli/qdisc/fq_codel.c"],
    copts = CLI_PLUGIN_COPTS,
    deps = CLI_PLUGIN_DEPS,
    dynamic_deps = CLI_PLUGIN_DYNAMIC_DEPS,
    output_name = "fq_codel",
)

sonic_shared_library(
    name = "libnl_cli_qdisc_hfsc",
    srcs = ["lib/cli/qdisc/hfsc.c"],
    copts = CLI_PLUGIN_COPTS,
    deps = CLI_PLUGIN_DEPS,
    dynamic_deps = CLI_PLUGIN_DYNAMIC_DEPS,
    output_name = "hfsc",
)

sonic_shared_library(
    name = "libnl_cli_qdisc_htb",
    srcs = ["lib/cli/qdisc/htb.c"],
    copts = CLI_PLUGIN_COPTS,
    deps = CLI_PLUGIN_DEPS,
    dynamic_deps = CLI_PLUGIN_DYNAMIC_DEPS,
    output_name = "htb",
)

sonic_shared_library(
    name = "libnl_cli_qdisc_ingress",
    srcs = ["lib/cli/qdisc/ingress.c"],
    copts = CLI_PLUGIN_COPTS,
    deps = CLI_PLUGIN_DEPS,
    dynamic_deps = CLI_PLUGIN_DYNAMIC_DEPS,
    output_name = "ingress",
)

sonic_shared_library(
    name = "libnl_cli_qdisc_pfifo",
    srcs = ["lib/cli/qdisc/pfifo.c"],
    copts = CLI_PLUGIN_COPTS,
    deps = CLI_PLUGIN_DEPS,
    dynamic_deps = CLI_PLUGIN_DYNAMIC_DEPS,
    output_name = "pfifo",
)

sonic_shared_library(
    name = "libnl_cli_qdisc_plug",
    srcs = ["lib/cli/qdisc/plug.c"],
    copts = CLI_PLUGIN_COPTS,
    deps = CLI_PLUGIN_DEPS,
    dynamic_deps = CLI_PLUGIN_DYNAMIC_DEPS,
    output_name = "plug",
)

# =============================================================================
# Static archives — extract the libtool-style `.a` static libraries for the
# -dev binary packages. Debian's libnl-3-dev (and friends) ships these
# alongside the .so symlinks; without them, downstream code that statically
# links against libnl will fail to find the `.a`.
# =============================================================================
static_archive(name = "libnl_3_static", lib = ":libnl_3", output_name = "libnl-3")
static_archive(name = "libnl_genl_3_static", lib = ":libnl_genl_3", output_name = "libnl-genl-3")
static_archive(name = "libnl_route_3_static", lib = ":libnl_route_3", output_name = "libnl-route-3")
static_archive(name = "libnl_nf_3_static", lib = ":libnl_nf_3", output_name = "libnl-nf-3")
static_archive(name = "libnl_cli_3_static", lib = ":libnl_cli_3", output_name = "libnl-cli-3")

# CLI plugin static archives (mirrors debian/libnl-cli-3-dev.install).
static_archive(name = "libnl_cli_cls_basic_static", lib = ":libnl_cli_cls_basic", output_name = "basic")
static_archive(name = "libnl_cli_cls_cgroup_static", lib = ":libnl_cli_cls_cgroup", output_name = "cgroup")
static_archive(name = "libnl_cli_qdisc_bfifo_static", lib = ":libnl_cli_qdisc_bfifo", output_name = "bfifo")
static_archive(name = "libnl_cli_qdisc_blackhole_static", lib = ":libnl_cli_qdisc_blackhole", output_name = "blackhole")
static_archive(name = "libnl_cli_qdisc_fq_codel_static", lib = ":libnl_cli_qdisc_fq_codel", output_name = "fq_codel")
static_archive(name = "libnl_cli_qdisc_hfsc_static", lib = ":libnl_cli_qdisc_hfsc", output_name = "hfsc")
static_archive(name = "libnl_cli_qdisc_htb_static", lib = ":libnl_cli_qdisc_htb", output_name = "htb")
static_archive(name = "libnl_cli_qdisc_ingress_static", lib = ":libnl_cli_qdisc_ingress", output_name = "ingress")
static_archive(name = "libnl_cli_qdisc_pfifo_static", lib = ":libnl_cli_qdisc_pfifo", output_name = "pfifo")
static_archive(name = "libnl_cli_qdisc_plug_static", lib = ":libnl_cli_qdisc_plug", output_name = "plug")

# =============================================================================
# .deb Packages
# =============================================================================

# libnl-3-200 (main runtime library)
sonic_deb(
    name = "libnl-3-200_3.7.0-0.2+b1sonic1.deb",
    package = "libnl-3-200",
    version = LIBNL_VERSION,
    maintainer = "SONiC Maintainers",
    multi_arch = "same",
    section = "libs",
    description = "libnl generic netlink library",
    content = {
        # Debian's libnl-3-200.install targets /lib/<multiarch>/, but on a
        # usrmerge system dpkg redirects that to /usr/lib/<multiarch>/ (where
        # the file actually ends up in Make's image). Bazel's tar layer writes
        # literal paths and would create a real /lib dir shadowing the base
        # image's /lib->usr/lib symlink, so we write to /usr/lib (${LIBDIR})
        # directly — matching Make's final on-disk location and keeping usrmerge.
        "${LIBDIR}:*:0644": [":libnl_3_files"],
        "/etc/libnl-3/*:*:0644": [":etc_files"],
    },
    #content_targets = [":libnl_3_shared"],
    depends = ["libc6 (>= 2.38)"],
    gen_dbg = True,
    homepage = "https://www.infradead.org/~tgr/libnl/",
    visibility = ["//visibility:public"],
)

# libnl-3-dev (development files for core library)
sonic_deb(
    name = "libnl-3-dev_3.7.0-0.2+b1sonic1.deb",
    package = "libnl-3-dev",
    version = LIBNL_VERSION,
    maintainer = "SONiC Maintainers",
    multi_arch = "same",
    breaks = ["libnl3-dev"],
    conflicts = ["libnl-dev", "libnl2-dev"],
    replaces = ["libnl3-dev"],
    section = "libdevel",
    description = "development library and header files for libnl-3",
    content = {
        "/usr/include/libnl3:include/:0644": [":libnl_3_hdr_files"],
        # debian/libnl-3-dev.install moves the .so symlink + .a static
        # archive to /lib/<multiarch>/.
        "${LIBDIR_BASE}:*:0644": [
            ":libnl_3_dev_link_direct",
            ":libnl_3_static",
        ],
        "${LIBDIR}/pkgconfig:0644": [
            ":libnl3_pc_generated",
        ],
    },
    depends = ["libnl-3-200 (= {})".format(LIBNL_VERSION)],
    visibility = ["//visibility:public"],
)

# libnl-genl-3-200 (generic netlink runtime library)
sonic_deb(
    name = "libnl-genl-3-200_3.7.0-0.2+b1sonic1.deb",
    package = "libnl-genl-3-200",
    version = LIBNL_VERSION,
    maintainer = "SONiC Maintainers",
    multi_arch = "same",
    section = "libs",
    description = "libnl generic netlink library",
    content = {
        # /lib target redirected to /usr/lib on usrmerge; write to ${LIBDIR}
        # directly to match Make's final location and keep the /lib symlink.
        "${LIBDIR}:*:0644": [":libnl_genl_3_files"],
    },
    content_targets = [":libnl_genl_3_shared"],
    depends = [
        "libnl-3-200 (= {})".format(LIBNL_VERSION),
        "libc6 (>= 2.4)",
    ],
    gen_dbg = True,
    homepage = "https://www.infradead.org/~tgr/libnl/",
    visibility = ["//visibility:public"],
)

# libnl-genl-3-dev (development files for genl library)
sonic_deb(
    name = "libnl-genl-3-dev_3.7.0-0.2+b1sonic1.deb",
    package = "libnl-genl-3-dev",
    version = LIBNL_VERSION,
    maintainer = "SONiC Maintainers",
    multi_arch = "same",
    section = "libdevel",
    description = "development library and header files for libnl-genl-3",
    content = {
        "${LIBDIR}/pkgconfig:0644": [
            ":libnl3_genl_pc_generated",
        ],
        # debian/libnl-genl-3-dev.install moves .so + .a to /lib/<multiarch>/.
        "${LIBDIR_BASE}:*:0644": [
            ":libnl_genl_3_dev_link_direct",
            ":libnl_genl_3_static",
        ],
    },
    depends = [
        "libnl-3-dev (= {})".format(LIBNL_VERSION),
        "libnl-genl-3-200 (= {})".format(LIBNL_VERSION),
    ],
    visibility = ["//visibility:public"],
)

# libnl-route-3-200 (route runtime library)
sonic_deb(
    name = "libnl-route-3-200_3.7.0-0.2+b1sonic1.deb",
    package = "libnl-route-3-200",
    version = LIBNL_VERSION,
    maintainer = "SONiC Maintainers",
    multi_arch = "same",
    section = "libs",
    description = "libnl route library",
    content = {
        "${LIBDIR}:*:0644": [":libnl_route_3_files"],
    },
    content_targets = [":libnl_route_3_shared"],
    depends = [
        "libnl-3-200 (= {})".format(LIBNL_VERSION),
        "libc6 (>= 2.38)",
    ],
    gen_dbg = True,
    homepage = "https://www.infradead.org/~tgr/libnl/",
    visibility = ["//visibility:public"],
)

# libnl-route-3-dev (development files for route library)
sonic_deb(
    name = "libnl-route-3-dev_3.7.0-0.2+b1sonic1.deb",
    package = "libnl-route-3-dev",
    version = LIBNL_VERSION,
    maintainer = "SONiC Maintainers",
    multi_arch = "same",
    section = "libdevel",
    description = "development library and header files for libnl-route-3",
    content = {
        "${LIBDIR}/pkgconfig:0644": [
            ":libnl3_route_pc_generated",
        ],
        "${LIBDIR}:*:0644": [
            ":libnl_route_3_dev_link_direct",
            ":libnl_route_3_static",
        ],
    },
    depends = [
        "libnl-3-dev (= {})".format(LIBNL_VERSION),
        "libnl-route-3-200 (= {})".format(LIBNL_VERSION),
    ],
    visibility = ["//visibility:public"],
)

# libnl-nf-3-200 (netfilter runtime library)
sonic_deb(
    name = "libnl-nf-3-200_3.7.0-0.2+b1sonic1.deb",
    package = "libnl-nf-3-200",
    version = LIBNL_VERSION,
    maintainer = "SONiC Maintainers",
    multi_arch = "same",
    description = "libnl netfilter library",
    section = "libs",
    content = {
        "${LIBDIR}:*:0644": [":libnl_nf_3_files"],
    },
    depends = [
        "libnl-3-200 (= {})".format(LIBNL_VERSION),
        "libnl-route-3-200 (= {})".format(LIBNL_VERSION),
        "libc6 (>= 2.14)",
    ],
    gen_dbg = True,
    homepage = "https://www.infradead.org/~tgr/libnl/",
    visibility = ["//visibility:public"],
)

# libnl-nf-3-dev (development files for netfilter library)
sonic_deb(
    name = "libnl-nf-3-dev_3.7.0-0.2+b1sonic1.deb",
    package = "libnl-nf-3-dev",
    version = LIBNL_VERSION,
    maintainer = "SONiC Maintainers",
    multi_arch = "same",
    section = "libdevel",
    description = "development library and header files for libnl-nf-3",
    content = {
        "${LIBDIR}/pkgconfig:0644": [
            ":libnl3_nf_pc_generated",
        ],
        "${LIBDIR}:*:0644": [
            ":libnl_nf_3_dev_link_direct",
            ":libnl_nf_3_static",
        ],
    },
    depends = [
        "libnl-3-dev (= {})".format(LIBNL_VERSION),
        "libnl-route-3-dev (= {})".format(LIBNL_VERSION),
        "libnl-nf-3-200 (= {})".format(LIBNL_VERSION),
    ],
    visibility = ["//visibility:public"],
)

# libnl-cli-3-200 (CLI runtime library + plugins)
sonic_deb(
    name = "libnl-cli-3-200_3.7.0-0.2+b1sonic1.deb",
    package = "libnl-cli-3-200",
    version = LIBNL_VERSION,
    maintainer = "SONiC Maintainers",
    multi_arch = "same",
    section = "libs",
    description = "libnl CLI library",
    content = {
        "${LIBDIR}:*:0644": [":libnl_cli_3_files"],
        "${LIBDIR}/libnl-3/cli/cls:*:0644": [
            ":libnl_cli_cls_basic_shared",
            ":libnl_cli_cls_cgroup_shared",
        ],
        "${LIBDIR}/libnl-3/cli/qdisc:*:0644": [
            ":libnl_cli_qdisc_bfifo_shared",
            ":libnl_cli_qdisc_blackhole_shared",
            ":libnl_cli_qdisc_fq_codel_shared",
            ":libnl_cli_qdisc_hfsc_shared",
            ":libnl_cli_qdisc_htb_shared",
            ":libnl_cli_qdisc_ingress_shared",
            ":libnl_cli_qdisc_pfifo_shared",
            ":libnl_cli_qdisc_plug_shared",
        ],
    },
    depends = [
        "libnl-3-200 (= {})".format(LIBNL_VERSION),
        "libnl-genl-3-200 (= {})".format(LIBNL_VERSION),
        "libnl-nf-3-200 (= {})".format(LIBNL_VERSION),
        "libnl-route-3-200 (= {})".format(LIBNL_VERSION),
        "libc6 (>= 2.38)",
    ],
    gen_dbg = True,
    homepage = "https://www.infradead.org/~tgr/libnl/",
    visibility = ["//visibility:public"],
)

# libnl-cli-3-dev (development files for CLI library)
sonic_deb(
    name = "libnl-cli-3-dev_3.7.0-0.2+b1sonic1.deb",
    package = "libnl-cli-3-dev",
    version = LIBNL_VERSION,
    maintainer = "SONiC Maintainers",
    multi_arch = "same",
    description = "development library and header files for libnl-cli-3",
    section = "libdevel",
    content = {
        "${LIBDIR}/pkgconfig:0644": [
            ":libnl3_cli_pc_generated",
        ],
        "${LIBDIR}:*:0644": [
            ":libnl_cli_3_dev_link_direct",
            ":libnl_cli_3_static",
        ],
        # cls/qdisc plugin static archives. Note Debian uses libnl/cli/ here
        # (NOT libnl-3/cli/ like the shared .so plugins do).
        "${LIBDIR}/libnl/cli/cls:*:0644": [
            ":libnl_cli_cls_basic_static",
            ":libnl_cli_cls_cgroup_static",
        ],
        "${LIBDIR}/libnl/cli/qdisc:*:0644": [
            ":libnl_cli_qdisc_bfifo_static",
            ":libnl_cli_qdisc_blackhole_static",
            ":libnl_cli_qdisc_fq_codel_static",
            ":libnl_cli_qdisc_hfsc_static",
            ":libnl_cli_qdisc_htb_static",
            ":libnl_cli_qdisc_ingress_static",
            ":libnl_cli_qdisc_pfifo_static",
            ":libnl_cli_qdisc_plug_static",
        ],
    },
    depends = [
        "libnl-3-dev (= {})".format(LIBNL_VERSION),
        "libnl-genl-3-dev (= {})".format(LIBNL_VERSION),
        "libnl-nf-3-dev (= {})".format(LIBNL_VERSION),
        "libnl-route-3-dev (= {})".format(LIBNL_VERSION),
        "libnl-cli-3-200 (= {})".format(LIBNL_VERSION),
    ],
    visibility = ["//visibility:public"],
)

# =============================================================================
# pkgconfig files
# =============================================================================

# Platform-aware "libdir=" line shared by all .pc files. write_file.content
# accepts list concatenation, so we splice this single-element select() into
# each content list to pick the right multiarch dir per target arch.
_LIBDIR_LINE_SELECT = select({
    "@platforms//cpu:x86_64": ["libdir=${prefix}/lib/x86_64-linux-gnu"],
    "@platforms//cpu:aarch64": ["libdir=${prefix}/lib/aarch64-linux-gnu"],
})

write_file(
    name = "libnl3_pc_generated",
    out = "libnl-3.0.pc",
    content = [
        "prefix=/usr",
        "exec_prefix=${prefix}",
    ] + _LIBDIR_LINE_SELECT + [
        "includedir=${prefix}/include",
        "",
        "Name: libnl",
        "Description: Convenience library for netlink sockets",
        "Version: 3.7.0",
        "Libs: -L${libdir} -lnl-3",
        "Libs.private: -lpthread ",
        "Cflags: -I${includedir}/libnl3",
        "",
    ],
)

write_file(
    name = "libnl3_genl_pc_generated",
    out = "libnl-genl-3.0.pc",
    content = [
        "prefix=/usr",
        "exec_prefix=${prefix}",
    ] + _LIBDIR_LINE_SELECT + [
        "includedir=${prefix}/include",
        "",
        "Name: libnl-genl",
        "Description: Generic Netlink Library",
        "Version: 3.7.0",
        "Requires: libnl-3.0",
        "Libs: -L${libdir} -lnl-genl-3",
        "Cflags: -I${includedir}/libnl3",
        "",
    ],
)

write_file(
    name = "libnl3_route_pc_generated",
    out = "libnl-route-3.0.pc",
    content = [
        "prefix=/usr",
        "exec_prefix=${prefix}",
    ] + _LIBDIR_LINE_SELECT + [
        "includedir=${prefix}/include",
        "",
        "Name: libnl-route",
        "Description: Netlink Routing Family Library",
        "Version: 3.7.0",
        "Requires: libnl-3.0",
        "Libs: -L${libdir} -lnl-route-3",
        "Cflags: -I${includedir}/libnl3",
        "",
    ],
)

write_file(
    name = "libnl3_nf_pc_generated",
    out = "libnl-nf-3.0.pc",
    content = [
        "prefix=/usr",
        "exec_prefix=${prefix}",
    ] + _LIBDIR_LINE_SELECT + [
        "includedir=${prefix}/include",
        "",
        "Name: libnl-nf",
        "Description: Netfilter Netlink Library",
        "Version: 3.7.0",
        "Requires: libnl-route-3.0",
        "Libs: -L${libdir} -lnl-nf-3",
        "Cflags: -I${includedir}/libnl3",
        "",
    ],
)

write_file(
    name = "libnl3_cli_pc_generated",
    out = "libnl-cli-3.0.pc",
    content = [
        "prefix=/usr",
        "exec_prefix=${prefix}",
    ] + _LIBDIR_LINE_SELECT + [
        "includedir=${prefix}/include",
        "",
        "Name: libnl-cli",
        "Description: Command Line Interface library for netlink sockets",
        "Version: 3.7.0",
        "Libs: -L${libdir} -lnl-cli-3",
        "Cflags: -I${includedir}",
        "Requires: libnl-3.0 libnl-genl-3.0 libnl-nf-3.0 libnl-route-3.0",
        "",
    ],
)
