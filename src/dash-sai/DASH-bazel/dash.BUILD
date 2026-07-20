"""Root BUILD for the DASH source tarball (sonic-net/DASH @ d5c003dd), fetched
as @dash_src. Drives the dash-sai (libsai / libsai-dev) build:

  Stage 1  p4_compile   bmv2/dash_pipeline.p4 --p4c-bm2-ss--> etc/dash/*.json,txt
  Stage 2  sai_gen      sai_api_gen.py -> DASH SAI headers + impl (.cpp)
  Stage 3  saimetadata  OCP SAI meta -> libdashsaimetadata.so
  Stage 4  libsai       DASH SAI lib -> libsai.so
  Stage 5  sonic_deb    libsai_1.0.0.deb + libsai-dev_1.0.0.deb

Mirrors src/dash-sai/Makefile + DASH/dash-pipeline/SAI/{Makefile,src,debian}.
"""

load("@bazel_lib//lib:expand_template.bzl", "expand_template_rule")
load("@doxygen//:doxygen.bzl", "doxygen")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_perl//perl:perl.bzl", "perl_binary", "perl_library")
load("@rules_python//python:defs.bzl", "py_binary")
load("@sonic_build_infra//shared_library:shared_library.bzl", "sonic_shared_library")
load("//:deb_headers.bzl", "deb_headers")

package(default_visibility = ["//visibility:public"])

VERSION = "1.0.0"

# =============================================================================
# Stage 1 — P4 compile (Make: src/dash-sai/Makefile L29)
#
#   p4c-bm2-ss -DTARGET_BMV2_V1MODEL bmv2/dash_pipeline.p4 \
#       -o bmv2/dash_pipeline.bmv2/dash_pipeline.json \
#       --p4runtime-files .../dash_pipeline_p4rt.json,.../dash_pipeline_p4rt.txt \
#       --toJSON .../dash_pipeline_ir.json
#
# p4c-bm2-ss is a host-built binary shipped inside @p4lang//:p4lang-p4c_*.deb
# (usr/bin/p4c-bm2-ss + usr/share/p4c/p4include). The deb ships no shared libs;
# p4c-bm2-ss dynamically links libboost_iostreams + libgc/libgccpp which are
# staged from apt (dashsai_deps) and put on LD_LIBRARY_PATH. libc/libstdc++ come
# from the sandbox's read-only host mount (same as every other genrule here).
# =============================================================================
filegroup(
    name = "p4_srcs",
    srcs = glob(["dash-pipeline/bmv2/**"]),
)

genrule(
    name = "p4_compile",
    srcs = glob(["dash-pipeline/bmv2/**"]) + [
        "@p4lang//:p4lang-p4c_1.2.4.2-2.deb",
        "@dashsai_deps//libgc1:data",
        "@dashsai_deps//libboost-iostreams1.83.0:data",
    ],
    outs = [
        "etc/dash/dash_pipeline.json",
        "etc/dash/dash_pipeline_p4rt.json",
        "etc/dash/dash_pipeline_p4rt.txt",
        "etc/dash/dash_pipeline_ir.json",
    ],
    cmd = """
set -eu
DEB=$(execpath @p4lang//:p4lang-p4c_1.2.4.2-2.deb)
GC=$(execpath @dashsai_deps//libgc1:data)
BOOST=$(execpath @dashsai_deps//libboost-iostreams1.83.0:data)
MAIN=$(execpath dash-pipeline/bmv2/dash_pipeline.p4)
PIPEDIR=$$(cd "$$(dirname "$$MAIN")/.." && pwd)
WORK=$$(mktemp -d)
trap 'rm -rf "$$WORK"' EXIT
mkdir -p "$$WORK/p4c" "$$WORK/libs" "$$WORK/out"
dpkg-deb -x "$$DEB" "$$WORK/p4c"
tar -xf "$$GC" -C "$$WORK/libs"
tar -xf "$$BOOST" -C "$$WORK/libs"
P4C="$$WORK/p4c/usr/bin/p4c-bm2-ss"
P4INC="$$WORK/p4c/usr/share/p4c/p4include"
LIBDIR=$$(dirname "$$(find "$$WORK/libs" -name 'libgc.so.1' | head -1)")
( cd "$$PIPEDIR" && LD_LIBRARY_PATH="$$LIBDIR" "$$P4C" \
    -I"$$P4INC" -DTARGET_BMV2_V1MODEL bmv2/dash_pipeline.p4 \
    -o "$$WORK/out/dash_pipeline.json" \
    --p4runtime-files "$$WORK/out/dash_pipeline_p4rt.json,$$WORK/out/dash_pipeline_p4rt.txt" \
    --toJSON "$$WORK/out/dash_pipeline_ir.json" )
cp "$$WORK/out/dash_pipeline.json"      $(execpath etc/dash/dash_pipeline.json)
cp "$$WORK/out/dash_pipeline_p4rt.json" $(execpath etc/dash/dash_pipeline_p4rt.json)
cp "$$WORK/out/dash_pipeline_p4rt.txt"  $(execpath etc/dash/dash_pipeline_p4rt.txt)
cp "$$WORK/out/dash_pipeline_ir.json"   $(execpath etc/dash/dash_pipeline_ir.json)
""",
)

filegroup(
    name = "etc_dash_files",
    srcs = [
        "etc/dash/dash_pipeline.json",
        "etc/dash/dash_pipeline_ir.json",
        "etc/dash/dash_pipeline_p4rt.json",
        "etc/dash/dash_pipeline_p4rt.txt",
    ],
)

# =============================================================================
# Stage 2 — DASH SAI codegen (Make: DASH/dash-pipeline/SAI/Makefile `all`)
#
#   ./sai_api_gen.py <p4rt.json> --ir <ir.json> \
#       --ignore-tables=underlay_mac,eni_meter,slb_decap \
#       --sai-spec-dir=specs dash
#
# Reads the p4c-produced p4rt.json + ir.json (stage 1) plus templates/ + specs/,
# and (a) edits the OCP SAI headers saiextensions.h / saitypesextensions.h /
# saiportextensions.h / saiobject.h in place, (b) emits new
# saiexperimentaldash*.h under experimental/, (c) emits DASH SAI impl .cpp +
# saiimpl.h into lib/. The upstream `copysrc` step (install src/* into lib/) is
# reproduced in the genrule so lib/ ends up with hand-written src + generated
# impl, ready for the libsai.so build.
#
# run_sai_gen.py stages a writable copy of SAI/ (+ the OCP SAI submodule at
# SAI/SAI) and runs the upstream script there via runpy — see run_sai_gen.py.
# =============================================================================
py_binary(
    name = "sai_gen_runner",
    srcs = ["run_sai_gen.py"],
    main = "run_sai_gen.py",
    deps = [
        "@wheel_jinja2//:lib",
        "@wheel_pyyaml//:lib",
        "@wheel_pyyaml_include//:lib",
        "@wheel_jsonpath_ng//:lib",
        "@wheel_ply//:lib",
    ],
)

genrule(
    name = "sai_gen",
    srcs = glob(["dash-pipeline/SAI/**"]) + [
        ":p4_compile",
        "@dash_sai_src//:all_files",
    ],
    outs = [
        "gen/experimental.tar",
        "gen/inc.tar",
        "gen/lib.tar",
    ],
    tools = [":sai_gen_runner"],
    cmd = """
set -eu
RUNNER=$$(realpath $(execpath :sai_gen_runner))
SAI_GEN_PY=$(execpath dash-pipeline/SAI/sai_api_gen.py)
SAIDIR=$$(cd "$$(dirname "$$SAI_GEN_PY")" && pwd)
# OCP SAI submodule root (dir containing inc/sai.h).
SAI_SUB_H=$$(echo $(execpaths @dash_sai_src//:all_files) | tr ' ' '\\n' | grep '/inc/sai.h$$' | head -1)
SAISUB=$$(cd "$$(dirname "$$SAI_SUB_H")/.." && pwd)
# p4c outputs.
P4RT=$$(echo $(execpaths :p4_compile) | tr ' ' '\\n' | grep '/dash_pipeline_p4rt.json$$' | head -1)
IR=$$(echo $(execpaths :p4_compile) | tr ' ' '\\n' | grep '/dash_pipeline_ir.json$$' | head -1)
P4RT=$$(realpath "$$P4RT"); IR=$$(realpath "$$IR")

STAGE=$$(mktemp -d)
trap 'rm -rf "$$STAGE"' EXIT
cp -RL "$$SAIDIR/." "$$STAGE/"
rm -rf "$$STAGE/SAI"
mkdir -p "$$STAGE/SAI"
cp -RL "$$SAISUB/." "$$STAGE/SAI/"
chmod -R u+w "$$STAGE"
mkdir -p "$$STAGE/lib"
# copysrc: install -CDv src/Makefile src/*h src/*cpp lib/
cp "$$STAGE/src/Makefile" "$$STAGE"/src/*.h "$$STAGE"/src/*.cpp "$$STAGE/lib/"

"$$RUNNER" "$$STAGE" "$$P4RT" "$$IR" 1>&2

tar -cf $(execpath gen/experimental.tar) -C "$$STAGE/SAI/experimental" .
tar -cf $(execpath gen/inc.tar)          -C "$$STAGE/SAI/inc" .
tar -cf $(execpath gen/lib.tar)          -C "$$STAGE/lib" .
""",
)

# =============================================================================
# Stage 5a — libsai-dev_1.0.0.deb (Make: DASH/dash-pipeline/SAI/debian/Makefile
# `libsai-dev` target). Ships every generated SAI header flattened under
# /usr/include/sai/:  ../SAI/inc/*.h + ../SAI/experimental/*.h. Both header
# sets come from the stage-2 codegen (inc.tar + experimental.tar). Headers-only
# package — no compiled artifacts — so it is fully produced here.
# =============================================================================
load("@sonic_build_infra//sonic_deb:sonic_deb.bzl", "sonic_deb")

genrule(
    name = "libsai_dev_data",
    srcs = [":sai_gen"],
    outs = ["libsai_dev_data.tar.gz"],
    cmd = """
set -eu
INC=$$(echo $(execpaths :sai_gen) | tr ' ' '\\n' | grep '/inc.tar$$' | head -1)
EXP=$$(echo $(execpaths :sai_gen) | tr ' ' '\\n' | grep '/experimental.tar$$' | head -1)
STAGE=$$(mktemp -d); trap 'rm -rf "$$STAGE"' EXIT
mkdir -p "$$STAGE/usr/include/sai"
tar -xf "$$INC" -C "$$STAGE/usr/include/sai"
tar -xf "$$EXP" -C "$$STAGE/usr/include/sai"
chmod -R u+w "$$STAGE"
find "$$STAGE/usr/include/sai" -type f -exec chmod 0644 {} +
tar --sort=name --owner=0 --group=0 --numeric-owner -czf $(execpath libsai_dev_data.tar.gz) -C "$$STAGE" .
""",
)

sonic_deb(
    name = "libsai-dev_1.0.0.deb",
    content = {},
    data = ":libsai_dev_data",
    package = "libsai-dev",
    version = VERSION,
    architecture = "amd64",
    section = "libdevel",
    priority = "optional",
    maintainer = "Kamil Cudnik <kcudnik@microsoft.com>",
    description = "This package contains development files for DASH libsai",
    package_file_name = "libsai-dev_1.0.0_amd64.deb",
)

# =============================================================================
# Stage 2b — materialize the stage-2 codegen tarballs as individual file
# targets. :sai_gen emits inc.tar / experimental.tar / lib.tar (the codegen-
# MODIFIED SAI headers + the DASH SAI impl sources). doxygen + parse.pl + the
# cc_library rules all need real file labels, so extract each tar into a fixed,
# known set of outputs (filenames are deterministic; see `tar tf` of :sai_gen).
# =============================================================================

# inc/*.h after stage-2 in-place edits (saiextensions.h etc. live in
# experimental/, so inc/ is the pristine-name set with edited saiobject.h).
SAI_INC_HDRS = [
    "sai.h",
    "saiacl.h",
    "saiars.h",
    "saiarsprofile.h",
    "saibfd.h",
    "saibridge.h",
    "saibuffer.h",
    "saicounter.h",
    "saidebugcounter.h",
    "saidtel.h",
    "saifdb.h",
    "saigenericprogrammable.h",
    "saihash.h",
    "saihostif.h",
    "saiicmpecho.h",
    "saiipmc.h",
    "saiipmcgroup.h",
    "saiipsec.h",
    "saiisolationgroup.h",
    "sail2mc.h",
    "sail2mcgroup.h",
    "sailag.h",
    "saimacsec.h",
    "saimcastfdb.h",
    "saimirror.h",
    "saimpls.h",
    "saimymac.h",
    "sainat.h",
    "saineighbor.h",
    "sainexthop.h",
    "sainexthopgroup.h",
    "saiobject.h",
    "saipoe.h",
    "saipolicer.h",
    "saiport.h",
    "saiprefixcompression.h",
    "saiqosmap.h",
    "saiqueue.h",
    "sairoute.h",
    "sairouterinterface.h",
    "sairpfgroup.h",
    "saisamplepacket.h",
    "saischeduler.h",
    "saischedulergroup.h",
    "saisrv6.h",
    "saistatus.h",
    "saistp.h",
    "saiswitch.h",
    "saisynce.h",
    "saisystemport.h",
    "saitam.h",
    "saitunnel.h",
    "saitwamp.h",
    "saitypes.h",
    "saiudf.h",
    "saiversion.h",
    "saivirtualrouter.h",
    "saivlan.h",
    "saiwred.h",
]

# experimental/*.h after stage-2: pristine SAI experimental headers PLUS the
# codegen-generated saiexperimentaldash*.h and the in-place-edited
# sai{extensions,portextensions,switchextensions,typesextensions}.h.
SAI_EXPERIMENTAL_HDRS = [
    "saiexperimentalbmtor.h",
    "saiexperimentaldashacl.h",
    "saiexperimentaldashappliance.h",
    "saiexperimentaldashdirectionlookup.h",
    "saiexperimentaldasheni.h",
    "saiexperimentaldashflow.h",
    "saiexperimentaldashha.h",
    "saiexperimentaldashinboundrouting.h",
    "saiexperimentaldashmeter.h",
    "saiexperimentaldashoutboundcatopa.h",
    "saiexperimentaldashoutboundportmap.h",
    "saiexperimentaldashoutboundrouting.h",
    "saiexperimentaldashpavalidation.h",
    "saiexperimentaldashtrustedvni.h",
    "saiexperimentaldashtunnel.h",
    "saiexperimentaldashvip.h",
    "saiexperimentaldashvnet.h",
    "saiextensions.h",
    "saiportextensions.h",
    "saiswitchextensions.h",
    "saitypesextensions.h",
]

# DASH SAI impl sources (lib.tar): hand-written engine (dashsai/config/p4meta/
# ...) + copysrc'd src/*.cpp + codegen-generated saidash*.cpp. Compiled into
# libsai.so.
SAI_LIB_SRCS = [
    "config.cpp",
    "dashsai.cpp",
    "logger.cpp",
    "objectidmanager.cpp",
    "p4meta.cpp",
    "sai_dash_acl.cpp",
    "sai_dash_buffer.cpp",
    "sai_dash_dtel.cpp",
    "sai_dash_hostif.cpp",
    "sai_dash_neighbor.cpp",
    "sai_dash_next_hop.cpp",
    "sai_dash_policer.cpp",
    "sai_dash_port.cpp",
    "sai_dash_router_interface.cpp",
    "sai_dash_switch.cpp",
    "saidashacl.cpp",
    "saidashappliance.cpp",
    "saidashdirectionlookup.cpp",
    "saidasheni.cpp",
    "saidashflow.cpp",
    "saidashha.cpp",
    "saidashinboundrouting.cpp",
    "saidashmeter.cpp",
    "saidashoutboundcatopa.cpp",
    "saidashoutboundportmap.cpp",
    "saidashoutboundrouting.cpp",
    "saidashpavalidation.cpp",
    "saidashtrustedvni.cpp",
    "saidashtunnel.cpp",
    "saidashvip.cpp",
    "saidashvnet.cpp",
    "saifixedapis.cpp",
    "sairoute.cpp",
    "utils.cpp",
]

SAI_LIB_HDRS = [
    "config.h",
    "dashsai.h",
    "logger.h",
    "objectidmanager.h",
    "p4meta.h",
    "saidash.h",
    "saiimpl.h",
    "utils.h",
]

genrule(
    name = "sai_inc_hdrs",
    srcs = [":sai_gen"],
    outs = ["sai/inc/" + h for h in SAI_INC_HDRS],
    cmd = """
set -eu
INC=$$(echo $(execpaths :sai_gen) | tr ' ' '\\n' | grep '/inc.tar$$' | head -1)
mkdir -p $(RULEDIR)/sai/inc
tar -xf "$$INC" -C $(RULEDIR)/sai/inc
""",
)

genrule(
    name = "sai_experimental_hdrs",
    srcs = [":sai_gen"],
    outs = ["sai/experimental/" + h for h in SAI_EXPERIMENTAL_HDRS],
    cmd = """
set -eu
EXP=$$(echo $(execpaths :sai_gen) | tr ' ' '\\n' | grep '/experimental.tar$$' | head -1)
mkdir -p $(RULEDIR)/sai/experimental
tar -xf "$$EXP" -C $(RULEDIR)/sai/experimental
""",
)

genrule(
    name = "sai_lib_files",
    srcs = [":sai_gen"],
    outs = ["sai/lib/" + f for f in SAI_LIB_SRCS + SAI_LIB_HDRS],
    cmd = """
set -eu
LIB=$$(echo $(execpaths :sai_gen) | tr ' ' '\\n' | grep '/lib.tar$$' | head -1)
STAGE=$$(mktemp -d); trap 'rm -rf "$$STAGE"' EXIT
tar -xf "$$LIB" -C "$$STAGE"
mkdir -p $(RULEDIR)/sai/lib
# Copy only the declared outputs (lib.tar also carries the copysrc Makefile,
# which is not needed by the Bazel cc build).
for f in %s; do
    cp "$$STAGE/$$f" $(RULEDIR)/sai/lib/$$f
done
""" % " ".join(SAI_LIB_SRCS + SAI_LIB_HDRS),
)

# cc_library facades over the stage-2 SAI headers. `includes` exposes them on the
# quote+system search path so both `#include <sai.h>` and `#include "sai.h"`
# resolve, matching the Make build's -I../SAI/{inc,experimental}.
cc_library(
    name = "sai_inc",
    hdrs = [":sai_inc_hdrs"],
    includes = ["sai/inc"],
)

cc_library(
    name = "sai_experimental",
    hdrs = [":sai_experimental_hdrs"],
    includes = ["sai/experimental"],
)

# =============================================================================
# Stage 2c — OCP SAI meta sources (opencomputeproject/SAI @ 8dd59e5, unmodified
# by the codegen). Copy the exact files the meta pipeline needs out of the
# submodule filegroup into this package so doxygen/parse.pl/cc_library can
# reference them by stable local labels.
# =============================================================================
META_CONST_HDRS = [
    "saimetadatatypes.h",
    "saimetadatalogger.h",
    "saimetadatautils.h",
    "saiserialize.h",
]

META_C_SRCS = [
    "saimetadatautils.c",
    "saiserialize.c",
]

META_PM = [
    "cap.pm",
    "serialize.pm",
    "style.pm",
    "test.pm",
    "utils.pm",
    "xmlutils.pm",
]

META_MISC = [
    "parse.pl",
    "Doxyfile",
    "acronyms.txt",
    "aspell.en.pws",
]

genrule(
    name = "gen_meta",
    srcs = ["@dash_sai_src//:meta_files"],
    outs = ["meta/" + f for f in META_CONST_HDRS + META_C_SRCS + META_PM + META_MISC],
    cmd = """
set -eu
SRC=$$(echo $(execpaths @dash_sai_src//:meta_files) | tr ' ' '\\n' | grep '/meta/parse.pl$$' | head -1)
META=$$(dirname "$$SRC")
mkdir -p $(RULEDIR)/meta
for f in %s; do
    cp "$$META/$$f" $(RULEDIR)/meta/$$f
done
""" % " ".join(META_CONST_HDRS + META_C_SRCS + META_PM + META_MISC),
)

# =============================================================================
# Stage 3 — libdashsaimetadata.so (OCP SAI metadata).
#
# Mirrors src/sonic-sairedis/SAI-bazel/sai.BUILD :saimetadata_sources +
# :saimetadata, but feeds the STAGE-2 codegen-modified inc/experimental headers
# (so the metadata reflects the DASH SAI extensions) and renames the output to
# libdashsaimetadata.so (Make: DASH SAI/SAI/meta `make libsaimetadata.so`, with
# the checkenumlock/checkancestry/checkstructs/saimetadatatest steps sed-removed
# — we simply never invoke them).
# =============================================================================

# Patch the upstream Doxyfile so rules_doxygen can inject the sandbox INPUT dirs
# and a writable OUTPUT_DIRECTORY (identical substitution to the SAI-bazel ref;
# DASH SAI's Doxyfile INPUT block is byte-identical).
expand_template_rule(
    name = "prepare_doxyfile_for_bazel",
    out = "meta/Doxyfile.bazel",
    substitutions = {
        "OUTPUT_DIRECTORY       =": "# {{OUTPUT DIRECTORY}}",
        "\n".join([
            "INPUT                  = ../inc/",
            "INPUT                  += ../experimental/",
            "INPUT                  += ../custom/",
            "INPUT                  += saimetadatatypes.h",
            "INPUT                  += saimetadatautils.h",
            "INPUT                  += saimetadatalogger.h",
            "INPUT                  += saiserialize.h",
        ]): "# {{INPUT}}\n# {{ADDITIONAL PARAMETERS}}",
    },
    template = "meta/Doxyfile",
)

doxygen(
    name = "doxygen",
    srcs = [
        "meta/saimetadatalogger.h",
        "meta/saimetadatatypes.h",
        "meta/saimetadatautils.h",
        "meta/saiserialize.h",
        ":sai_experimental_hdrs",
        ":sai_inc_hdrs",
    ],
    outs = ["xml"],
    doxyfile_template = ":prepare_doxyfile_for_bazel",
)

perl_library(
    name = "perl_lib",
    srcs = ["meta/" + m for m in META_PM],
    includes = ["meta"],
)

perl_binary(
    name = "parse",
    srcs = ["meta/parse.pl"],
    main = "meta/parse.pl",
    deps = [":perl_lib"],
)

filegroup(
    name = "doxygen_xml",
    srcs = [":doxygen"],
    output_group = "xml",
)

# parse.pl is cwd-coupled (XMLDIR="xml", INCLUDE_DIR="../inc/",
# EXPERIMENTAL_DIR="../experimental/", CONSTHEADERS via opendir(".")). Stage a
# SAI/{meta,inc,experimental,custom}+xml layout in a tmpdir, cd meta/, run the
# hermetic :parse binary, then copy back saimetadata.{c,h}. saiattrversion.h is
# git-derived; stage an empty placeholder (parse.pl then warns per-attr but
# still emits saimetadata.c), same as the SAI-bazel reference.
genrule(
    name = "saimetadata_sources",
    srcs = [
        "meta/saimetadatatypes.h",
        "meta/saimetadatautils.h",
        "meta/saimetadatalogger.h",
        "meta/saiserialize.h",
        "meta/acronyms.txt",
        "meta/aspell.en.pws",
        ":sai_inc_hdrs",
        ":sai_experimental_hdrs",
        ":doxygen_xml",
    ],
    outs = [
        "meta/saimetadata.h",
        "meta/saimetadata.c",
    ],
    cmd = """
set -eu
PARSE=$$(realpath $(execpath :parse))
XML_DIR=$$(realpath $(execpath :doxygen_xml))

STAGE=$$(mktemp -d)
trap 'rm -rf "$$STAGE"' EXIT
mkdir -p "$$STAGE/SAI/meta" "$$STAGE/SAI/inc" \\
         "$$STAGE/SAI/experimental" "$$STAGE/SAI/custom"

for f in $(execpath meta/saimetadatatypes.h) $(execpath meta/saimetadatautils.h) \\
         $(execpath meta/saimetadatalogger.h) $(execpath meta/saiserialize.h) \\
         $(execpath meta/acronyms.txt) $(execpath meta/aspell.en.pws); do
    cp -L "$$f" "$$STAGE/SAI/meta/"
done

cp -RL "$$XML_DIR" "$$STAGE/SAI/meta/xml"

for f in $(execpaths :sai_inc_hdrs); do
    cp -L "$$f" "$$STAGE/SAI/inc/"
done
for f in $(execpaths :sai_experimental_hdrs); do
    cp -L "$$f" "$$STAGE/SAI/experimental/"
done

: > "$$STAGE/SAI/meta/saiattrversion.h"

# -S skips the aspell style check (no aspell in the hermetic sandbox).
( cd "$$STAGE/SAI/meta" && "$$PARSE" -S )

cp "$$STAGE/SAI/meta/saimetadata.h" $(execpath meta/saimetadata.h)
cp "$$STAGE/SAI/meta/saimetadata.c" $(execpath meta/saimetadata.c)
""",
    tools = [":parse"],
)

# All meta public headers (hand-written CONSTHEADERS + generated saimetadata.h).
cc_library(
    name = "saimetadata_hdrs",
    hdrs = [
        "meta/saimetadatalogger.h",
        "meta/saimetadatatypes.h",
        "meta/saimetadatautils.h",
        "meta/saiserialize.h",
        "meta/saimetadata.h",  # generated by :saimetadata_sources
    ],
    includes = ["meta"],
    deps = [
        ":sai_experimental",
        ":sai_inc",
    ],
)

# libdashsaimetadata.so: the two hand-written meta .c plus the parse.pl-generated
# saimetadata.c. alwayslink so every metadata symbol is retained — the same
# object set is also linked whole into libsai.so (Make links the 3 meta .o files
# into both libsaimetadata.so and libsai.so).
sonic_shared_library(
    name = "dashsaimetadata",
    srcs = [
        "meta/saimetadatautils.c",
        "meta/saiserialize.c",
        "meta/saimetadata.c",  # generated by :saimetadata_sources
    ],
    alwayslink = True,
    # Upstream meta Makefile compiles the metadata without -g; -g0 keeps
    # libdashsaimetadata.so lean (matches the ~4.4MB Make baseline instead of the
    # hermetic toolchain's default -g bloat).
    copts = ["-g0"],
    includes = ["meta"],
    output_name = "libdashsaimetadata",
    deps = [":saimetadata_hdrs"],
)

# =============================================================================
# Stage 4 — libsai.so (DASH SAI lib; Make: DASH/dash-pipeline/SAI/src/Makefile).
#
# g++ -fPIC -std=c++14 <strict -Werror warning set> -I meta -I inc -I experimental
#     -shared -o libsai.so lib/*.cpp <meta objs>
#
# lib/*.cpp additionally #include protobuf/grpc/P4Runtime/PI headers; these are
# supplied as -isystem via :libsai_thirdparty_hdrs (so the strict warnings do
# not fire on third-party code) and are NOT linked — the resulting .so carries
# those symbols UNDEFINED (allow_undefined = True, i.e. no -Wl,-z,defs), exactly
# like the Make `g++ -shared` output.
# =============================================================================

# protobuf 3.21.x + grpc++ + abseil headers (apt) and P4Runtime/PI headers
# (p4lang-pi.deb), merged into one -isystem root.
deb_headers(
    name = "libsai_thirdparty_hdrs",
    debs = ["@p4lang//:p4lang-pi_0.1.1-1.deb"],
    tars = [
        "@dashsai_deps//libprotobuf-dev:data",
        "@dashsai_deps//libgrpc++-dev:data",
        "@dashsai_deps//libgrpc-dev:data",
        "@dashsai_deps//libabsl-dev:data",
    ],
)

# Strict warning set from DASH SAI/src/Makefile (CXXFLAGS_COMMON), kept verbatim
# incl. -Werror. -ansi is harmless (superseded by the later -std=c++14).
DASH_SAI_COPTS = [
    "-ansi",
    "-fPIC",
    "-pipe",
    "-std=c++14",
    # Upstream's CXXFLAGS_COMMON carry no -g (only the final `g++ -shared -g`
    # link does, which adds nothing without -g objects). The hermetic toolchain
    # defaults to -g, which would balloon libsai.so to ~19MB of .debug_* vs the
    # ~5.8MB Make baseline; -g0 restores the upstream (no-debug) object flavor.
    "-g0",
    "-Wall",
    "-Wcast-align",
    "-Wcast-qual",
    "-Wconversion",
    "-Wdisabled-optimization",
    "-Werror",
    "-Wextra",
    "-Wfloat-equal",
    "-Wformat=2",
    "-Wformat-nonliteral",
    "-Wformat-security",
    "-Wformat-y2k",
    "-Wimport",
    "-Winit-self",
    "-Wno-inline",
    "-Winvalid-pch",
    "-Wmissing-field-initializers",
    "-Wmissing-format-attribute",
    "-Wmissing-include-dirs",
    "-Wmissing-noreturn",
    "-Wno-aggregate-return",
    "-Wno-padded",
    "-Wno-switch-enum",
    "-Wno-unused-parameter",
    "-Wpacked",
    "-Wpointer-arith",
    "-Wredundant-decls",
    "-Wshadow",
    "-Wstack-protector",
    "-Wstrict-aliasing=3",
    "-Wswitch",
    "-Wswitch-default",
    "-Wunreachable-code",
    "-Wunused",
    "-Wvariadic-macros",
    "-Wwrite-strings",
    "-Wno-switch-default",
    "-Wno-psabi",
    "-Wno-unused-label",
    "-Wno-unused-result",
    # Narrow, environmental relaxation (NOT a blanket -Werror drop): Bazel adds
    # -I for BOTH the source and bin roots of every `includes` dir, but the SAI
    # header/lib dirs are code-generated so they exist only under bin/; likewise
    # the hermetic GCC enumerates builtin C++ include dirs that are not all
    # materialized in the sandbox. -Wmissing-include-dirs then errors on the
    # absent source-tree/toolchain paths — a layout artifact, not a code defect
    # (upstream's Make build has these dirs on disk). Keep the warning but make
    # it non-fatal; every other warning stays a hard error.
    "-Wno-error=missing-include-dirs",
]

sonic_shared_library(
    name = "libsai_impl",
    srcs = [":sai_lib_files"],
    allow_undefined = True,
    copts = DASH_SAI_COPTS,
    features = ["external_include_paths"],
    includes = ["sai/lib"],
    output_name = "libsai",
    deps = [
        ":libsai_thirdparty_hdrs",
        ":saimetadata_hdrs",
    ],
    objects = [":dashsaimetadata"],
)

# =============================================================================
# Stage 5b — libsai_1.0.0.deb (Make: DASH SAI/debian/Makefile `libsai`).
#
# Content = /etc/dash/* (stage 1) + /usr/lib/<multiarch>/{libsai.so,
# libdashsaimetadata.so}. Control mirrors the baseline
# (target/debs/trixie/libsai_1.0.0_amd64.deb): Section libs, no Depends, a
# `shlibs` of `libsai 0 libsai`, and a `triggers` of `activate-noawait ldconfig`.
# The two .so carry no soname/version in the baseline, so plain files are shipped
# (not versioned symlinks).
# =============================================================================
genrule(
    name = "libsai_shlibs",
    outs = ["libsai.shlibs"],
    cmd = "printf 'libsai 0 libsai\\n' > $@",
)

genrule(
    name = "libsai_triggers",
    outs = ["libsai.triggers"],
    cmd = "printf 'activate-noawait ldconfig\\n' > $@",
)

sonic_deb(
    name = "libsai_1.0.0.deb",
    package = "libsai",
    version = VERSION,
    architecture = "amd64",
    section = "libs",
    priority = "optional",
    maintainer = "Kamil Cudnik <kcudnik@microsoft.com>",
    description = "This package contains DASH libsai",
    content = {
        "/etc/dash:*:0755": [":etc_dash_files"],
        "${LIBDIR}:*:0755": [
            ":libsai_impl_shared",
            ":dashsaimetadata_shared",
        ],
    },
    # gen_dbg strips the shipped .so (the hermetic toolchain's opt mode forces
    # -g -O2 *after* user copts, so -g0 cannot win; stripping is the workspace-
    # standard way — see libteam/protobuf/sysmgr — to keep the shipped libs lean,
    # ~matching the Make baseline's non-debug .so sizes). The libsai deb's own
    # content layout (two .so + /etc/dash) is unchanged; a companion
    # libsai-dbgsym deb carries the debug info.
    gen_dbg = True,
    shlibs = ":libsai_shlibs",
    triggers = ":libsai_triggers",
    package_file_name = "libsai_1.0.0_amd64.deb",
)
