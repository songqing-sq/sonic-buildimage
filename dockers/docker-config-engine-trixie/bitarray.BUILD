# Build file for the bitarray sdist (fetched via http_archive as @bitarray_src
# in the root MODULE.bazel). bitarray==2.8.1 ships no cp313 wheel on PyPI (only
# up to cp311), so on trixie's Python 3.13 the C extensions must be compiled
# from source. We compile them with the project's hermetic GCC 14.3 cc rules
# (mirroring what libyang3-py3 does) instead of aspect_rules_py's sdist_build,
# which relies on the interpreter's sysconfig CC (=clang) and a non-hermetic
# host compiler.
#
# The upstream setup.py declares two independent extensions with no special
# compile flags or macros:
#   Extension("bitarray._bitarray", sources=["bitarray/_bitarray.c"])
#   Extension("bitarray._util",     sources=["bitarray/_util.c"])
# Both #include only "Python.h" + the local bitarray.h / pythoncapi_compat.h.

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_shared_library.bzl", "cc_shared_library")
load("@tar.bzl", "tar")

package(default_visibility = ["//visibility:public"])

# Compile flags mirroring what setuptools uses on the Make path: Python's
# sysconfig CFLAGS for the hermetic 3.13.4 interpreter are
#   -fno-strict-overflow -Wsign-compare -Wunreachable-code -DNDEBUG -g -O3 -Wall -fPIC
# (CCSHARED adds -fPIC). We replicate them here so the Bazel-compiled .so
# matches Make's optimization level / macros (-O3 -DNDEBUG) rather than
# Bazel's default -O2. -std=c99 pins the C standard bitarray's sources use.
_COPTS = [
    "-fPIC",
    "-std=c99",
    "-O3",
    "-DNDEBUG",
    "-g",
    "-fno-strict-overflow",
    "-Wsign-compare",
    "-Wunreachable-code",
    "-Wall",
]

# Local headers (bitarray.h, pythoncapi_compat.h) live next to the .c sources.
cc_library(
    name = "_bitarray_obj",
    srcs = ["bitarray/_bitarray.c"],
    hdrs = [
        "bitarray/bitarray.h",
        "bitarray/pythoncapi_compat.h",
    ],
    copts = _COPTS,
    # Headers are included as `#include "bitarray.h"`, so expose bitarray/ dir.
    includes = ["bitarray"],
    deps = ["@rules_python//python/cc:current_py_cc_headers"],
)

cc_library(
    name = "_util_obj",
    srcs = ["bitarray/_util.c"],
    hdrs = [
        "bitarray/bitarray.h",
        "bitarray/pythoncapi_compat.h",
    ],
    copts = _COPTS,
    includes = ["bitarray"],
    deps = ["@rules_python//python/cc:current_py_cc_headers"],
)

# Produce the cpython-313 suffixed .so names that Python's import machinery
# expects (matching the Make image's _bitarray.cpython-313-x86_64-linux-gnu.so).
cc_shared_library(
    name = "_bitarray_so",
    shared_lib_name = select({
        "@platforms//cpu:x86_64": "_bitarray.cpython-313-x86_64-linux-gnu.so",
        "@platforms//cpu:aarch64": "_bitarray.cpython-313-aarch64-linux-gnu.so",
    }),
    deps = [":_bitarray_obj"],
)

cc_shared_library(
    name = "_util_so",
    shared_lib_name = select({
        "@platforms//cpu:x86_64": "_util.cpython-313-x86_64-linux-gnu.so",
        "@platforms//cpu:aarch64": "_util.cpython-313-aarch64-linux-gnu.so",
    }),
    deps = [":_util_obj"],
)

# Ready-to-layer tar placing the compiled extensions + python sources under
# /usr/local/lib/python3.13/dist-packages/bitarray/, matching the Make image.
# Consumed directly by docker-config-engine-trixie's python_layer.
tar(
    name = "bitarray_install",
    srcs = [
        ":_bitarray_so",
        ":_util_so",
        "bitarray/__init__.py",
        "bitarray/__init__.pyi",
        "bitarray/util.py",
        "bitarray/util.pyi",
        "bitarray/py.typed",
        "bitarray/bitarray.h",
        "bitarray/pythoncapi_compat.h",
        "bitarray/test_bitarray.py",
        "bitarray/test_util.py",
        "bitarray/test_150.pickle",
        "bitarray/test_281.pickle",
    ],
    mtree = [
        "./usr/local/lib/python3.13/dist-packages/bitarray/_bitarray.cpython-313-x86_64-linux-gnu.so uid=0 gid=0 mode=0755 type=file content=$(location :_bitarray_so)",
        "./usr/local/lib/python3.13/dist-packages/bitarray/_util.cpython-313-x86_64-linux-gnu.so uid=0 gid=0 mode=0755 type=file content=$(location :_util_so)",
        "./usr/local/lib/python3.13/dist-packages/bitarray/__init__.py uid=0 gid=0 mode=0644 type=file content=$(location bitarray/__init__.py)",
        "./usr/local/lib/python3.13/dist-packages/bitarray/__init__.pyi uid=0 gid=0 mode=0644 type=file content=$(location bitarray/__init__.pyi)",
        "./usr/local/lib/python3.13/dist-packages/bitarray/util.py uid=0 gid=0 mode=0644 type=file content=$(location bitarray/util.py)",
        "./usr/local/lib/python3.13/dist-packages/bitarray/util.pyi uid=0 gid=0 mode=0644 type=file content=$(location bitarray/util.pyi)",
        "./usr/local/lib/python3.13/dist-packages/bitarray/py.typed uid=0 gid=0 mode=0644 type=file content=$(location bitarray/py.typed)",
        "./usr/local/lib/python3.13/dist-packages/bitarray/bitarray.h uid=0 gid=0 mode=0644 type=file content=$(location bitarray/bitarray.h)",
        "./usr/local/lib/python3.13/dist-packages/bitarray/pythoncapi_compat.h uid=0 gid=0 mode=0644 type=file content=$(location bitarray/pythoncapi_compat.h)",
        "./usr/local/lib/python3.13/dist-packages/bitarray/test_bitarray.py uid=0 gid=0 mode=0644 type=file content=$(location bitarray/test_bitarray.py)",
        "./usr/local/lib/python3.13/dist-packages/bitarray/test_util.py uid=0 gid=0 mode=0644 type=file content=$(location bitarray/test_util.py)",
        "./usr/local/lib/python3.13/dist-packages/bitarray/test_150.pickle uid=0 gid=0 mode=0644 type=file content=$(location bitarray/test_150.pickle)",
        "./usr/local/lib/python3.13/dist-packages/bitarray/test_281.pickle uid=0 gid=0 mode=0644 type=file content=$(location bitarray/test_281.pickle)",
    ],
)
