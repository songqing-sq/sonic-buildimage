package(default_visibility = ["//visibility:public"])
load("@com_github_grpc_grpc//bazel:python_rules.bzl", "py_proto_library")

proto_library(name = "code_proto", srcs = ["code.proto"], strip_import_prefix = "/", import_prefix = "google/rpc")
proto_library(name = "status_proto", srcs = ["status.proto"], strip_import_prefix = "/", import_prefix = "google/rpc", deps = ["@protobuf//:any_proto"])
cc_proto_library(name = "code_cc_proto", deps = [":code_proto"])
cc_proto_library(name = "status_cc_proto", deps = [":status_proto"])
py_proto_library(name = "code_py_proto", deps = [":code_proto"])
py_proto_library(name = "status_py_proto", deps = [":status_proto"])
