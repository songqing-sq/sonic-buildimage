package(default_visibility = ["//visibility:public"])

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@sonic_build_infra//shared_library:shared_library.bzl", "sonic_shared_library_versioned")

alias(
    name = "picjson",
    actual = "//third_party/cJSON:picjson",
)

alias(
    name = "pitoolkit",
    actual = "//lib:pitoolkit",
)

filegroup(name = "pihdrs", srcs = glob(["include/**/*.h"]))

cc_library(
    name = "piutils",
    srcs = ["src/utils/logging.c", "src/utils/serialize.c"],
    hdrs = [":pihdrs", "src/utils/logging.h", "src/utils/utils.h"],
    includes = ["include", "src/utils"],
)

cc_library(
    name = "pip4info",
    srcs = [
        "src/config_readers/bmv2_json_reader.c", "src/config_readers/native_json_reader.c",
        "src/p4info/act_profs.c", "src/p4info/actions.c", "src/p4info/counters.c",
        "src/p4info/digests.c", "src/p4info/fast_id_vector.c", "src/p4info/meters.c",
        "src/p4info/p4info.c", "src/p4info/p4info_common.c", "src/p4info/p4info_name_map.c",
        "src/p4info/p4info_struct.c", "src/p4info/tables.c",
    ],
    hdrs = glob(["include/PI/p4info/*.h"]) + [
        "src/p4info_int.h", "src/config_readers/readers.h",
        "src/p4info/act_profs_int.h", "src/p4info/actions_int.h",
        "src/p4info/counters_int.h", "src/p4info/digests_int.h",
        "src/p4info/fast_id_vector.h", "src/p4info/meters_int.h",
        "src/p4info/p4info_common.h", "src/p4info/p4info_name_map.h",
        "src/p4info/p4info_struct.h", "src/p4info/tables_int.h",
    ],
    includes = ["include", "src", "src/config_readers", "src/p4info"],
    copts = ["-DPI_LOG_ON"],
    deps = [":picjson", ":pitoolkit", ":piutils", "@pi_uthash//:uthash"],
)

cc_library(
    name = "pi",
    srcs = [
        "src/cb_mgr.c", "src/device_map.c", "src/pi.c", "src/pi_act_prof.c",
        "src/pi_clone.c", "src/pi_counter.c", "src/pi_learn.c", "src/pi_mc.c",
        "src/pi_meter.c", "src/pi_tables.c", "src/pi_value.c",
    ],
    hdrs = [
        ":pihdrs", "src/cb_mgr.h", "src/device_map.h", "src/pi_learn_int.h",
        "src/pi_notifications_pub.h", "src/pi_tables_int.h",
    ],
    includes = ["include", "src"],
    deps = [":pip4info"],
)

cc_library(
    name = "pifegeneric",
    srcs = ["src/frontends/generic/pi.c"],
    hdrs = ["include/PI/frontends/generic/pi.h"],
    includes = ["include"],
    copts = ["-DPI_LOG_ON"],
    deps = [":libpi"],
)

alias(name = "pifecpp", actual = "//frontends_extra/cpp:pifecpp")
alias(name = "piprotobuf", actual = "//proto:piprotobuf")
alias(name = "piprotogrpc", actual = "//proto:piprotogrpc")
alias(name = "piconvertproto", actual = "//proto/p4info:piconvertproto")
alias(name = "pi_convert_p4info", actual = "//proto/p4info:pi_convert_p4info")

filegroup(
    name = "pi_python_proto_tree",
    srcs = [
        "//proto:p4config_py_proto", "//proto:p4serverconfig_py_proto",
        "//proto:p4serverconfig_py_grpc", "@pi_googleapis//:code_py_proto",
        "@pi_googleapis//:status_py_proto", "@pi_p4runtime//:p4data_py_proto",
        "@pi_p4runtime//:p4info_py_proto", "@pi_p4runtime//:p4runtime_py_grpc",
        "@pi_p4runtime//:p4runtime_py_proto", "@pi_p4runtime//:p4types_py_proto",
    ],
)

cc_binary(
    name = "pi_gen_native_json",
    srcs = ["bin/gen_pi_json.c"],
    deps = [":libpi"],
)

cc_binary(
    name = "pi_gen_fe_defines",
    srcs = ["generators/fe_defines.c"],
    deps = [":pi"],
)

cc_library(
    name = "picli",
    srcs = [
        "CLI/act_profs/act_prof_common.c", "CLI/act_profs/act_prof_create_member.c",
        "CLI/act_profs/act_prof_dump.c", "CLI/act_profs/act_prof_groups.c",
        "CLI/add_p4.c", "CLI/counter_commands.c", "CLI/device_commands.c",
        "CLI/direct_res_reset.c", "CLI/error_codes.c", "CLI/main.c",
        "CLI/meter_commands.c", "CLI/p4_config_repo.c", "CLI/table_add.c",
        "CLI/table_common.c", "CLI/table_delete.c", "CLI/table_dump.c",
        "CLI/table_modify.c", "CLI/table_reset_default.c", "CLI/table_set_default.c",
        "CLI/utils.c",
    ],
    hdrs = [
        "CLI/act_profs/act_prof_common.h", "CLI/commands.h", "CLI/error_codes.h",
        "CLI/p4_config_repo.h", "CLI/table_common.h", "CLI/utils.h",
    ],
    includes = ["CLI", "include", "lib"],
    deps = [":pi", ":pifegeneric", ":pip4info", ":pitoolkit", "@p4lang_pi_deps//libreadline-dev:libreadline"],
)

cc_binary(
    name = "pi_CLI_dummy",
    linkopts = ["-Wl,--allow-shlib-undefined"],
    srcs = ["pi_cli_dummy_main.c"],
    deps = [":picli", ":pi_dummy"],
)

sonic_shared_library_versioned(
    name = "libpi",
    allow_undefined = True,
    exports_filter = ["//:__subpackages__"],
    output_name = "libpi",
    srcs = [
        "src/cb_mgr.c", "src/device_map.c", "src/pi.c", "src/pi_act_prof.c",
        "src/pi_clone.c", "src/pi_counter.c", "src/pi_learn.c", "src/pi_mc.c",
        "src/pi_meter.c", "src/pi_tables.c", "src/pi_value.c",
    ],
    hdrs = [":pihdrs", "src/cb_mgr.h", "src/device_map.h", "src/pi_learn_int.h", "src/pi_tables_int.h"],
    includes = ["include", "src"],
    deps = [":pip4info"],
    soversion = "0",
    version = "0.0.0",
)

sonic_shared_library_versioned(
    name = "libpifegeneric",
    dynamic_deps = [":libpi_shared"],
    output_name = "libpifegeneric",
    srcs = ["src/frontends/generic/pi.c"],
    hdrs = ["include/PI/frontends/generic/pi.h"],
    includes = ["include"],
    copts = ["-DPI_LOG_ON"],
    deps = [":pi"],
    soversion = "0",
    version = "0.0.0",
)

cc_library(
    name = "pi_dummy",
    alwayslink = True,
    srcs = [
        "targets/dummy/func_counter.c", "targets/dummy/pi_act_prof_imp.c",
        "targets/dummy/pi_clone_imp.c", "targets/dummy/pi_counter_imp.c",
        "targets/dummy/pi_imp.c", "targets/dummy/pi_learn_imp.c",
        "targets/dummy/pi_mc_imp.c", "targets/dummy/pi_meter_imp.c",
        "targets/dummy/pi_tables_imp.c",
    ],
    hdrs = ["targets/dummy/func_counter.h"],
    includes = ["include", "targets/dummy"],
    deps = [":pi"],
)

sonic_shared_library_versioned(
    name = "libpi_dummy",
    dynamic_deps = [":libpi_shared"],
    output_name = "libpi_dummy",
    srcs = [
        "targets/dummy/func_counter.c", "targets/dummy/pi_act_prof_imp.c",
        "targets/dummy/pi_clone_imp.c", "targets/dummy/pi_counter_imp.c",
        "targets/dummy/pi_imp.c", "targets/dummy/pi_learn_imp.c",
        "targets/dummy/pi_mc_imp.c", "targets/dummy/pi_meter_imp.c",
        "targets/dummy/pi_tables_imp.c",
    ],
    hdrs = ["targets/dummy/func_counter.h"],
    includes = ["include", "targets/dummy"],
    deps = [":pi"],
    soversion = "0",
    version = "0.0.0",
)
