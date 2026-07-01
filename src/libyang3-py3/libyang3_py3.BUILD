load("@rules_python//python:defs.bzl", "py_binary")

package(default_visibility = ["//visibility:public"])

# All extracted source files - mainly so other targets can reference them.
filegroup(
    name = "srcs",
    srcs = glob(["**/*"]),
)

# Pure Python package files (libyang/*.py) that get installed to
# /usr/lib/python3/dist-packages/libyang/ in the .deb.
filegroup(
    name = "libyang_py_sources",
    srcs = glob(["libyang/*.py", "libyang/*.typed"]),
)

# cffi build script and inputs. Used by the consumer module to emit
# _libyang.c (the C extension source) via `python3 cffi/build.py`.
exports_files([
    "cffi/build.py",
    "cffi/cdefs.h",
    "cffi/source.c",
    "README.rst",
])

filegroup(
    name = "cffi_inputs",
    srcs = [
        "cffi/build.py",
        "cffi/cdefs.h",
        "cffi/source.c",
    ],
)
