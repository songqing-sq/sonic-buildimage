# BUILD file expanded into the @protobuf_c repo by sonic_http_archive.
# Exposes two targets sourced from the protobuf-c v1.5.0 upstream tarball:
#
#   :protoc-gen-c  -- the protoc plugin that emits C bindings.  Built as a
#                     normal cc_binary; rules_proto_grpc's `proto_plugin.tool`
#                     attribute is cfg=exec, so Bazel builds this for the
#                     exec platform and runs it during proto_compile actions.
#                     Never ships in any deb.
#
#   :libprotobuf_c -- the runtime library that the generated bindings link
#                     against.  Built with -fPIC + linkstatic so it can be
#                     statically pulled into consumer .so files (zebra_fpm.so,
#                     dplane_fpm_nl.so, libmlag_pb.so), eliminating the
#                     libprotobuf-c1 runtime dep on the frr deb.
#
# Header path rewriting: FRR consumers do
#   #include <google/protobuf-c/protobuf-c.h>
# (matching what Debian's libprotobuf-c-dev installs at
# /usr/include/google/protobuf-c/protobuf-c.h).  The tarball ships the header
# at `protobuf-c/protobuf-c.h`, so we strip the `protobuf-c/` prefix and
# prepend `google/protobuf-c/` so callers compile unchanged.

load("@protobuf//bazel:cc_proto_library.bzl", "cc_proto_library")
load("@protobuf//bazel:proto_library.bzl", "proto_library")
load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library")
load("@rules_proto_grpc//:defs.bzl", "proto_plugin")

package(default_visibility = ["//visibility:public"])

# protobuf-c.proto declares the `pb_c_*` FieldOptions / FileOptions custom
# options that protoc-gen-c reads while generating C bindings.  It is a
# normal protobuf descriptor extension -- compile it with the standard
# protobuf toolchain (NOT with our own protoc-gen-c plugin) so c_file.cc /
# c_message.cc can do `#include <protobuf-c/protobuf-c.pb.h>`.
proto_library(
    name = "protobuf_c_proto",
    srcs = ["protobuf-c/protobuf-c.proto"],
    deps = ["@protobuf//:descriptor_proto"],
)

cc_proto_library(
    name = "protobuf_c_cc_proto",
    deps = [":protobuf_c_proto"],
)

# Wrapper that re-exports the generated `protobuf-c/protobuf-c.pb.h` so that
# `#include <protobuf-c/protobuf-c.pb.h>` (angle brackets, as used by the
# protoc-gen-c sources) resolves.  `includes = ["."]` adds the repo's source
# root and bin-out root to the -I path, making the generated header reachable
# under its `protobuf-c/` package prefix.  Plain :protobuf_c_cc_proto exposes
# the header only via -iquote, which doesn't satisfy angle-bracket includes.
cc_library(
    name = "_protobuf_c_cc_proto_isystem",
    includes = ["."],
    deps = [":protobuf_c_cc_proto"],
)

# Header view used INSIDE the protoc-gen-c plugin sources.  c_file.cc has
# `#include "protobuf-c.h"` (relative quote include); `includes = ["protobuf-c"]`
# adds the directory to the search path so the quoted lookup succeeds.
# The plugin's own headers (c_*.h, compat.h) are co-located with the .cc
# files in protoc-gen-c/ and resolved as quoted includes from the same dir,
# so cc_binary picks them up via the implicit `-iquote .` for srcs.
cc_library(
    name = "_protoc_c_internal_hdrs",
    hdrs = ["protobuf-c/protobuf-c.h"],
    includes = ["protobuf-c"],
)

# Tarball layout note: v1.5.2 renamed the plugin source dir from `protoc-c/`
# (v1.5.0) to `protoc-gen-c/`.  The C++ source files inside that dir use
# unqualified quoted includes for their own headers (`#include "c_*.h"`,
# `#include "compat.h"`), so cc_binary just needs the dir on the quoted
# include path -- which Bazel adds automatically for the srcs' own dir.
cc_binary(
    name = "protoc-gen-c",
    srcs = glob([
        "protoc-gen-c/*.cc",
        "protoc-gen-c/*.h",
    ]),
    # protoc-gen-c/main.cc passes PACKAGE_STRING to CommandLineInterface::
    # SetVersionInfo().  Autoconf would normally emit it into config.h from
    # AC_INIT; we're skipping ./configure entirely, so inject the equivalent
    # via -D.  The format ("name version") matches what autoconf produces.
    copts = ['-DPACKAGE_STRING=\\"protobuf-c-1.5.2\\"'],
    deps = [
        ":_protobuf_c_cc_proto_isystem",
        ":_protoc_c_internal_hdrs",
        "@abseil-cpp//absl/strings:string_view",
        "@protobuf//:protobuf",
        "@protobuf//:protoc_lib",
    ],
)

# Re-export `protobuf-c/protobuf-c.h` at the bare path (no `google/` prefix)
# so that protoc-gen-c-emitted `.pb-c.h` files (which include
# `<protobuf-c/protobuf-c.h>` per upstream convention) compile.  `includes =
# ["."]` adds the @protobuf_c repo root to the -I path, which makes
# `protobuf-c/protobuf-c.h` (the literal layout inside the upstream tarball)
# resolvable for both quoted and angle-bracket lookups.
cc_library(
    name = "_protobuf_c_h_bare",
    hdrs = ["protobuf-c/protobuf-c.h"],
    includes = ["."],
)

# Public runtime library.  Statically linked into consumer .so files
# (zebra_fpm.so, dplane_fpm_nl.so, libmlag_pb.so) via linkstatic=True so the
# frr deb no longer needs libprotobuf-c1 at runtime.  Two header views are
# exposed via deps:
#   - `:_protobuf_c_h_bare` for `<protobuf-c/protobuf-c.h>` (generated
#     .pb-c.h files use this path).
#   - `include_prefix = "google/protobuf-c"` here, for FRR's handwritten
#     code (`alibgp/qpb/qpb_allocator.h` uses
#     `<google/protobuf-c/protobuf-c.h>`).
cc_library(
    name = "libprotobuf_c",
    srcs = ["protobuf-c/protobuf-c.c"],
    hdrs = ["protobuf-c/protobuf-c.h"],
    copts = ["-fPIC"],
    include_prefix = "google/protobuf-c",
    linkstatic = True,
    strip_include_prefix = "protobuf-c",
    deps = [":_protobuf_c_h_bare"],
)

# rules_proto_grpc proto_plugin descriptor for protoc-gen-c.  Consumers wire
# this into a proto_compile-style rule (see clippy_helpers.bzl's
# `protoc_c_compile`).  The plugin emits one .pb-c.c and one .pb-c.h per
# input .proto -- the `{protopath}` template expands to the proto's path
# relative to its import root, e.g. `qpb/qpb` for `qpb/qpb.proto`.
proto_plugin(
    name = "protoc_gen_c_plugin",
    tool = ":protoc-gen-c",
    outputs = [
        "{protopath}.pb-c.c",
        "{protopath}.pb-c.h",
    ],
)
