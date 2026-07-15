# Build file for the thrift sdist (fetched via http_archive as @thrift_fastbinary_src
# in the root MODULE.bazel). thrift==0.13.0's pure-Python package is provided by
# the uv/pip hub (@pip_pmon9//thrift). Its optional C++ acceleration extension
# `thrift.protocol.fastbinary` is NOT built by the aspect uv extension: aspect's
# sdist_configure classified thrift as pure-Python and produced a py3-none-any
# wheel, so fastbinary.*.so was never compiled. thrift then silently falls back
# to the slower pure-Python codec (module.py's try/except BuildFailed path).
#
# To match the Make image (which compiles fastbinary via setuptools build_ext),
# we compile the extension here from the sdist sources with the project's
# hermetic GCC 14.3 cc rules — mirroring bitarray.BUILD — and lay the resulting
# .so beside the pip-installed thrift package at
#   /usr/lib/python3/dist-packages/thrift/protocol/fastbinary.cpython-313-*.so
#
# The upstream setup.py declares one extension (run_setup(with_binary=True)):
#   Extension('thrift.protocol.fastbinary',
#             sources=['src/ext/module.cpp', 'src/ext/types.cpp',
#                      'src/ext/binary.cpp', 'src/ext/compact.cpp'],
#             include_dirs=['src'])
# The sources #include both <"ext/binary.h"> (relative to src) and <"types.h">
# (relative to src/ext), so both src and src/ext are on the include path.

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_shared_library.bzl", "cc_shared_library")
load("@tar.bzl", "tar")

package(default_visibility = ["//visibility:public"])

# Compile flags mirroring setuptools build_ext on the Make path: Python's
# sysconfig CFLAGS for the hermetic 3.13.4 interpreter (-O3 -DNDEBUG -fPIC etc).
# fastbinary is C++ (build_ext uses the C++ compiler for .cpp sources), so we
# pin -std=c++11 (protocol.tcc uses templates/std features fine under c++11).
_COPTS = [
    "-fPIC",
    "-std=c++11",
    "-O3",
    "-DNDEBUG",
    "-g",
    "-fno-strict-overflow",
    "-Wall",
    # thrift's endian.h does `#ifndef __BYTE_ORDER ... #error "Cannot determine
    # endianness"`. The sysroot glibc headers don't surface __BYTE_ORDER to it,
    # so we satisfy the check by mapping the three macros it needs onto GCC's
    # always-defined builtin byte-order macros (portable across x86_64/aarch64).
    "-D__BYTE_ORDER=__BYTE_ORDER__",
    "-D__LITTLE_ENDIAN=__ORDER_LITTLE_ENDIAN__",
    "-D__BIG_ENDIAN=__ORDER_BIG_ENDIAN__",
]

cc_library(
    name = "fastbinary_obj",
    srcs = [
        "src/ext/module.cpp",
        "src/ext/types.cpp",
        "src/ext/binary.cpp",
        "src/ext/compact.cpp",
    ],
    hdrs = [
        "src/ext/binary.h",
        "src/ext/compact.h",
        "src/ext/endian.h",
        "src/ext/protocol.h",
        "src/ext/protocol.tcc",
        "src/ext/types.h",
    ],
    copts = _COPTS,
    # Sources include both "ext/binary.h" (from src) and "types.h" (from
    # src/ext) — expose both directories on the include path.
    includes = [
        "src",
        "src/ext",
    ],
    deps = ["@rules_python//python/cc:current_py_cc_headers"],
)

# Produce the cpython-313 suffixed .so name Python's import machinery expects
# (matching the Make image's fastbinary.cpython-313-x86_64-linux-gnu.so).
cc_shared_library(
    name = "fastbinary_so",
    shared_lib_name = select({
        "@platforms//cpu:x86_64": "fastbinary.cpython-313-x86_64-linux-gnu.so",
        "@platforms//cpu:aarch64": "fastbinary.cpython-313-aarch64-linux-gnu.so",
    }),
    deps = [":fastbinary_obj"],
)

# Ready-to-layer tar placing the compiled extension beside the pip-installed
# thrift package. site_packages lays @pip_pmon9//thrift at
# /usr/lib/python3/dist-packages/thrift/, so fastbinary goes into its
# protocol/ subpackage. Consumed by docker-platform-monitor's python_layer.
tar(
    name = "fastbinary_install",
    srcs = [":fastbinary_so"],
    mtree = [
        "./usr/lib/python3/dist-packages/thrift/protocol/fastbinary.cpython-313-x86_64-linux-gnu.so uid=0 gid=0 mode=0755 type=file content=$(location :fastbinary_so)",
    ],
)
