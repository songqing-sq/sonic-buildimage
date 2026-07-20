"""Root BUILD for the OCP SAI submodule (opencomputeproject/SAI @ 8dd59e5),
fetched as @dash_sai_src. Exposes the header/meta trees that the DASH SAI
codegen mutates and that the meta + libsai builds consume."""

package(default_visibility = ["//visibility:public"])

# SAI public headers (inc/) and experimental headers (experimental/). The DASH
# codegen (sai_api_gen.py) edits saiextensions.h / saitypesextensions.h /
# saiportextensions.h / saiobject.h in place and drops new saiexperimentaldash*.h
# files under experimental/.
filegroup(
    name = "inc_files",
    srcs = glob(["inc/*.h"]),
)

filegroup(
    name = "experimental_files",
    srcs = glob(["experimental/*.h"]),
)

filegroup(
    name = "custom_files",
    srcs = glob(["custom/**"], allow_empty = True),
)

# Everything under meta/ (parse.pl + perl modules + Doxyfile + hand-written
# saimetadata*.c/h + Makefile). Consumed by the libsaimetadata build.
filegroup(
    name = "meta_files",
    srcs = glob(["meta/**"], allow_empty = True),
)

# The whole submodule tree, for codegen staging that needs the full layout.
filegroup(
    name = "all_files",
    srcs = glob(["**"], allow_empty = True),
)
