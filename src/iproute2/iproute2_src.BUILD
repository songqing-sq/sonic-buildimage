"""Source exposure for the patched iproute2 6.15.0 tree.

debian_source lays the Debian 6.15.0-1 packaging over the orig tarball, applies
debian/patches/series (upstream's single `0001-Add-moo-feature.patch`) the way
`dpkg-source -x` does, then applies SONiC's
patch/0001-bridge-fdb-Add-protocol-field-support.patch on top — the same order
`dget -u` + `stg import -s ../patch/series` produces in src/iproute2/Makefile.

Only the file groups and the header cc_library live here; `includes` paths
resolve against the package that declares them, so they have to be in this repo.
Compilation happens in the iproute2 module.
"""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

# Every quoted include in lib/ and bridge/ resolves either to a sibling file or
# to include/, so those two -I paths are the whole story.
#
# include/uapi is load-bearing rather than incidental: debian/rules exports
# KERNEL_INCLUDE=./include, so the build reads the bundled uapi headers instead
# of the sysroot's. That is where the patch's `#define RTPROT_HW 193` lands, and
# lib/rt_names.c's rtnl_rtprot_tab[RTPROT_HW] would not compile without it.
cc_library(
    name = "hdrs_lib",
    hdrs = glob(
        [
            "include/*.h",
            "include/netinet/*.h",
            "include/uapi/**/*.h",
            "bridge/*.h",
        ],
        allow_empty = False,
    ),
    includes = [
        "include",
        "include/uapi",
    ],
)

# bridge/Makefile: BROBJ.
filegroup(
    name = "bridge_srcs",
    srcs = [
        "bridge/bridge.c",
        "bridge/fdb.c",
        "bridge/link.c",
        "bridge/mdb.c",
        "bridge/monitor.c",
        "bridge/mst.c",
        "bridge/vlan.c",
        "bridge/vni.c",
    ],
)

# lib/Makefile: NLOBJ, with mnl_utils.o included because HAVE_MNL=y in the
# Debian build (libmnl0 is in the archive package's Depends).
filegroup(
    name = "libnetlink_srcs",
    srcs = [
        "lib/libgenl.c",
        "lib/libnetlink.c",
        "lib/mnl_utils.c",
    ],
)

# lib/Makefile: UTILOBJ + ADDLIB, minus the members no object in bridge's
# closure can reach:
#   bpf_legacy.c, bpf_glue.c, bpf_libbpf.c  only tc/ and ip/ call into these
#   selinux.c                               a stub for !HAVE_SELINUX, and the
#                                           only caller is ip/ipvrf.c anyway
# Dropping them keeps libelf/libbpf/libselinux out of this module's dep graph.
filegroup(
    name = "libutil_srcs",
    srcs = [
        "lib/ax25_ntop.c",
        "lib/cg_map.c",
        "lib/color.c",
        "lib/exec.c",
        "lib/fs.c",
        "lib/inet_proto.c",
        "lib/json_print.c",
        "lib/json_print_math.c",
        "lib/json_writer.c",
        "lib/ll_addr.c",
        "lib/ll_map.c",
        "lib/ll_proto.c",
        "lib/ll_types.c",
        "lib/mpls_ntop.c",
        "lib/mpls_pton.c",
        "lib/names.c",
        "lib/namespace.c",
        "lib/netrom_ntop.c",
        "lib/ppp_proto.c",
        "lib/rose_ntop.c",
        "lib/rt_names.c",
        "lib/utils.c",
        "lib/utils_math.c",
    ],
)

# The patched protocol-name database. The top-level Makefile's install target
# copies etc/iproute2/* into CONF_USR_DIR (/usr/share/iproute2), and
# debian/iproute2.maintscript has already removed /etc/iproute2/rt_protos as a
# conffile, so this is the file rtnl_rtprot_initialize() actually reads.
exports_files(["etc/iproute2/rt_protos"])
