"""Root BUILD for the DASH source tarball (sonic-net/DASH @ d5c003dd), fetched
as @dash_src. Drives the dash-sai (libsai / libsai-dev) build:

  Stage 1  p4_compile   bmv2/dash_pipeline.p4 --p4c-bm2-ss--> etc/dash/*.json,txt
  Stage 2  sai_gen      sai_api_gen.py -> DASH SAI headers + impl (.cpp)
  Stage 3  saimetadata  OCP SAI meta -> libdashsaimetadata.so
  Stage 4  libsai       DASH SAI lib -> libsai.so
  Stage 5  sonic_deb    libsai_1.0.0.deb + libsai-dev_1.0.0.deb

Mirrors src/dash-sai/Makefile + DASH/dash-pipeline/SAI/{Makefile,src,debian}.
"""

load("@rules_python//python:defs.bzl", "py_binary")

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
# Stage 3/4 (TODO) — libsai.so + libdashsaimetadata.so, then the main
# libsai_1.0.0.deb (Make: src/dash-sai/Makefile L37-54).
#
# Stage 3 — libdashsaimetadata.so (OCP SAI meta). Make runs, in the SAI
# submodule meta/ dir (after sed-removing the checkenumlock/checkancestry/
# checkstructs/saimetadatatest steps):
#     CFLAGS=-Wdangling-pointer=1 make all libsaimetadata.so
# This is the same doxygen(1.9.5)+parse.pl->saimetadata.c pipeline already
# implemented for OCP SAI v1.18.1 in src/sonic-sairedis/SAI-bazel/sai.BUILD
# (targets :saimetadata_sources + :saimetadata). Port those targets here but
# feed the STAGE-2 codegen-modified headers (saiextensions.h /
# saitypesextensions.h / saiportextensions.h / saiobject.h + saiexperimentaldash*.h
# from :sai_gen's inc.tar/experimental.tar) into the doxygen `srcs`, so the
# metadata reflects the DASH SAI extensions. Output renamed to
# libdashsaimetadata.so. @doxygen (1.9.5) is already wired in MODULE.bazel.
#
# Stage 4 — libsai.so (DASH SAI lib; Make: DASH/dash-pipeline/SAI/src/Makefile).
#     g++ -fPIC -std=c++14 <strict -Werror warnings> -I meta -I inc -I experimental
#         -shared -o libsai.so lib/*.cpp <meta objs saimetadatautils.o
#         saimetadata.o saiserialize.o>
# Implement as a cc_library/sonic_shared_library over @dash_src//:sai_gen's
# lib.tar (extract to named srcs) + the SAI headers (inc/experimental/meta),
# linking the stage-3 metadata objects. Mind the strict warning set in
# src/Makefile (-Werror -Wconversion -Wcast-qual ...): the hermetic GCC 14.3
# may surface warnings the trixie-slave GCC 14.2 tolerated; fix with targeted
# copts, NOT by disabling the sandbox.
#
# Stage 5b — main deb (Make: DASH/dash-pipeline/SAI/debian/Makefile `libsai`):
#     sonic_deb(
#         name = "libsai_1.0.0.deb", package = "libsai", version = VERSION,
#         section = "libs", maintainer = "Kamil Cudnik <kcudnik@microsoft.com>",
#         description = "This package contains DASH libsai",
#         triggers = <"activate-noawait ldconfig">, gen_dbg = ...,
#         content = {
#             "/etc/dash:*:0755": [":etc_dash_files"],
#             "${LIBDIR}:*:0755": [":libsai_so", ":libdashsaimetadata_so"],
#         },
#     )
# Baseline control (target/debs/trixie/libsai_1.0.0_amd64.deb) has NO Depends
# and a `triggers` file with `activate-noawait ldconfig` + shlibs `libsai 0 libsai`.
# =============================================================================
