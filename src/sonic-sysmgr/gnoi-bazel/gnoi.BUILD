load("@protobuf//bazel:proto_library.bzl", "proto_library")
load("@protobuf//bazel:cc_proto_library.bzl", "cc_proto_library")

package(default_visibility = ["//visibility:public"])

proto_library(
    name = "types_proto",
    srcs = ["types/types.proto"],
    import_prefix = "github.com/openconfig/gnoi",
    strip_import_prefix = "",
    deps = ["@protobuf//:descriptor_proto"],
)

proto_library(
    name = "common_proto",
    srcs = ["common/common.proto"],
    import_prefix = "github.com/openconfig/gnoi",
    strip_import_prefix = "",
    deps = [":types_proto"],
)

proto_library(
    name = "system_proto",
    srcs = ["system/system.proto"],
    import_prefix = "github.com/openconfig/gnoi",
    strip_import_prefix = "",
    deps = [
        ":common_proto",
        ":types_proto",
    ],
)

cc_proto_library(
    name = "gnoi_cc_proto",
    deps = [":system_proto"],
)
