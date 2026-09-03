load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_thrift//:thrift.bzl", "thrift")
load("@p4lang//:bmv2_thrift.bzl", "bmv2_thrift_cc_library")
load("@sonic_build_infra//shared_library:shared_library.bzl", "sonic_shared_library_versioned")
load("@com_github_grpc_grpc//bazel:cc_grpc_library.bzl", "cc_grpc_library")
load("@com_github_grpc_grpc//bazel:python_rules.bzl", "py_grpc_library", "py_proto_library")

package(default_visibility = ["//visibility:public"])

exports_files([
    "targets/psa_switch/psa_switch_CLI.in",
    "targets/psa_switch/pswitch_CLI.py",
    "targets/simple_switch/simple_switch_CLI.in",
    "targets/simple_switch/sswitch_CLI.py",
    "tools/bm_CLI.in",
    "tools/bm_nanomsg_events.in",
    "tools/bm_p4dbg.in",
    "tools/bmpy_utils.py",
    "tools/nanomsg_client.py",
    "tools/p4dbg.py",
    "tools/runtime_CLI.py",
])

cc_library(
    name = "jsoncpp",
    srcs = ["third_party/jsoncpp/src/jsoncpp.cpp"],
    hdrs = ["third_party/jsoncpp/include/jsoncpp/json.h"],
    includes = ["third_party/jsoncpp/include"],
)

cc_library(
    name = "bflpmtrie",
    srcs = ["src/bf_lpm_trie/bf_lpm_trie.c"],
    hdrs = ["src/bf_lpm_trie/bf_lpm_trie/bf_lpm_trie.h"],
    includes = ["src/bf_lpm_trie"],
)

cc_library(
    name = "bmi",
    srcs = ["src/BMI/bmi_interface.c", "src/BMI/bmi_port.c"],
    hdrs = ["src/BMI/bmi_interface.h", "src/BMI/BMI/bmi_port.h"],
    includes = ["src/BMI"],
    deps = ["@p4lang_backend_deps//libpcap0.8-dev:pcap"],
)

_BM_SIM_SOURCES = [
    "src/bm_sim/P4Objects.cpp", "src/bm_sim/_assert.cpp",
    "src/bm_sim/action_profile.cpp", "src/bm_sim/actions.cpp",
    "src/bm_sim/ageing.cpp", "src/bm_sim/bytecontainer.cpp",
    "src/bm_sim/calculations.cpp", "src/bm_sim/checksums.cpp",
    "src/bm_sim/conditionals.cpp", "src/bm_sim/context.cpp",
    "src/bm_sim/control_action.cpp", "src/bm_sim/core/primitives.cpp",
    "src/bm_sim/counters.cpp", "src/bm_sim/crc_map.cpp",
    "src/bm_sim/debugger.cpp", "src/bm_sim/deparser.cpp",
    "src/bm_sim/dev_mgr.cpp", "src/bm_sim/dev_mgr_bmi.cpp",
    "src/bm_sim/dev_mgr_packet_in.cpp", "src/bm_sim/enums.cpp",
    "src/bm_sim/event_logger.cpp", "src/bm_sim/expressions.cpp",
    "src/bm_sim/extern.cpp", "src/bm_sim/fields.cpp",
    "src/bm_sim/header_unions.cpp", "src/bm_sim/headers.cpp",
    "src/bm_sim/learning.cpp", "src/bm_sim/logger.cpp",
    "src/bm_sim/lookup_structures.cpp", "src/bm_sim/match_error_codes.cpp",
    "src/bm_sim/match_tables.cpp", "src/bm_sim/match_units.cpp",
    "src/bm_sim/md5.c", "src/bm_sim/meters.cpp",
    "src/bm_sim/options_parse.cpp", "src/bm_sim/packet.cpp",
    "src/bm_sim/parser.cpp", "src/bm_sim/parser_error.cpp",
    "src/bm_sim/pcap_file.cpp", "src/bm_sim/periodic_task.cpp",
    "src/bm_sim/phv.cpp", "src/bm_sim/phv_source.cpp",
    "src/bm_sim/pipeline.cpp", "src/bm_sim/port_monitor.cpp",
    "src/bm_sim/simple_pre.cpp", "src/bm_sim/simple_pre_lag.cpp",
    "src/bm_sim/source_info.cpp", "src/bm_sim/stacks.cpp",
    "src/bm_sim/stateful.cpp", "src/bm_sim/switch.cpp",
    "src/bm_sim/tables.cpp", "src/bm_sim/target_parser.cpp",
    "src/bm_sim/transport.cpp", "src/bm_sim/transport_nn.cpp",
    "src/bm_sim/version.cpp", "src/bm_sim/xxhash.c",
]

_BM_SIM_HEADERS = [
    "include/bm/config.h",
    "include/bm/bm_runtime/bm_runtime.h", "include/bm/bm_sim/P4Objects.h",
    "include/bm/bm_sim/_assert.h", "include/bm/bm_sim/action_entry.h",
    "include/bm/bm_sim/action_profile.h", "include/bm/bm_sim/actions.h",
    "include/bm/bm_sim/ageing.h", "include/bm/bm_sim/bignum.h",
    "include/bm/bm_sim/bytecontainer.h", "include/bm/bm_sim/calculations.h",
    "include/bm/bm_sim/checksums.h", "include/bm/bm_sim/conditionals.h",
    "include/bm/bm_sim/context.h", "include/bm/bm_sim/control_action.h",
    "include/bm/bm_sim/control_flow.h", "include/bm/bm_sim/core/primitives.h",
    "include/bm/bm_sim/counters.h", "include/bm/bm_sim/data.h",
    "include/bm/bm_sim/debugger.h", "include/bm/bm_sim/deparser.h",
    "include/bm/bm_sim/dev_mgr.h", "include/bm/bm_sim/device_id.h",
    "include/bm/bm_sim/dynamic_bitset.h", "include/bm/bm_sim/entries.h",
    "include/bm/bm_sim/enums.h", "include/bm/bm_sim/event_logger.h",
    "include/bm/bm_sim/expressions.h", "include/bm/bm_sim/extern.h",
    "include/bm/bm_sim/field_lists.h", "include/bm/bm_sim/fields.h",
    "include/bm/bm_sim/handle_mgr.h", "include/bm/bm_sim/header_unions.h",
    "include/bm/bm_sim/headers.h", "include/bm/bm_sim/learning.h",
    "include/bm/bm_sim/logger.h", "include/bm/bm_sim/lookup_structures.h",
    "include/bm/bm_sim/match_error_codes.h", "include/bm/bm_sim/match_key_types.h",
    "include/bm/bm_sim/match_tables.h", "include/bm/bm_sim/match_units.h",
    "include/bm/bm_sim/meters.h", "include/bm/bm_sim/named_p4object.h",
    "include/bm/bm_sim/nn.h", "include/bm/bm_sim/options_parse.h",
    "include/bm/bm_sim/packet.h", "include/bm/bm_sim/packet_buffer.h",
    "include/bm/bm_sim/packet_handler.h", "include/bm/bm_sim/parser.h",
    "include/bm/bm_sim/parser_error.h", "include/bm/bm_sim/pcap_file.h",
    "include/bm/bm_sim/periodic_task.h", "include/bm/bm_sim/phv.h",
    "include/bm/bm_sim/phv_forward.h", "include/bm/bm_sim/phv_source.h",
    "include/bm/bm_sim/pipeline.h", "include/bm/bm_sim/port_monitor.h",
    "include/bm/bm_sim/pre.h", "include/bm/bm_sim/queue.h",
    "include/bm/bm_sim/queueing.h", "include/bm/bm_sim/ras.h",
    "include/bm/bm_sim/runtime_interface.h", "include/bm/bm_sim/short_alloc.h",
    "include/bm/bm_sim/simple_pre.h", "include/bm/bm_sim/simple_pre_lag.h",
    "include/bm/bm_sim/source_info.h", "include/bm/bm_sim/stacks.h",
    "include/bm/bm_sim/stateful.h", "include/bm/bm_sim/switch.h",
    "include/bm/bm_sim/tables.h", "include/bm/bm_sim/target_parser.h",
    "include/bm/bm_sim/transport.h", "include/bm/thrift/stdcxx.h",
    "src/bm_sim/crc_map.h", "src/bm_sim/crc_tables.h", "src/bm_sim/extract.h",
    "src/bm_sim/lpm_trie.h", "src/bm_sim/md5.h", "src/bm_sim/utils.h",
    "src/bm_sim/version.h", "src/bm_sim/xxhash.h",
] + [
    "third_party/spdlog/bm/spdlog/async_logger.h",
    "third_party/spdlog/bm/spdlog/common.h",
    "third_party/spdlog/bm/spdlog/details/async_log_helper.h",
    "third_party/spdlog/bm/spdlog/details/async_logger_impl.h",
    "third_party/spdlog/bm/spdlog/details/file_helper.h",
    "third_party/spdlog/bm/spdlog/details/format.cc",
    "third_party/spdlog/bm/spdlog/details/format.h",
    "third_party/spdlog/bm/spdlog/details/line_logger.h",
    "third_party/spdlog/bm/spdlog/details/log_msg.h",
    "third_party/spdlog/bm/spdlog/details/logger_impl.h",
    "third_party/spdlog/bm/spdlog/details/mpmc_bounded_q.h",
    "third_party/spdlog/bm/spdlog/details/null_mutex.h",
    "third_party/spdlog/bm/spdlog/details/os.h",
    "third_party/spdlog/bm/spdlog/details/pattern_formatter_impl.h",
    "third_party/spdlog/bm/spdlog/details/registry.h",
    "third_party/spdlog/bm/spdlog/details/spdlog_impl.h",
    "third_party/spdlog/bm/spdlog/formatter.h",
    "third_party/spdlog/bm/spdlog/logger.h",
    "third_party/spdlog/bm/spdlog/sinks/android_sink.h",
    "third_party/spdlog/bm/spdlog/sinks/base_sink.h",
    "third_party/spdlog/bm/spdlog/sinks/dist_sink.h",
    "third_party/spdlog/bm/spdlog/sinks/file_sinks.h",
    "third_party/spdlog/bm/spdlog/sinks/null_sink.h",
    "third_party/spdlog/bm/spdlog/sinks/ostream_sink.h",
    "third_party/spdlog/bm/spdlog/sinks/sink.h",
    "third_party/spdlog/bm/spdlog/sinks/stdout_sinks.h",
    "third_party/spdlog/bm/spdlog/sinks/syslog_sink.h",
    "third_party/spdlog/bm/spdlog/spdlog.h",
    "third_party/spdlog/bm/spdlog/tweakme.h",
]

filegroup(name = "bmsim_headers", srcs = _BM_SIM_HEADERS)

filegroup(
    name = "bmv2_install_header_sources",
    srcs = _BM_SIM_HEADERS + [
        "include/bm/bm_apps/learn.h",
        "include/bm/bm_apps/notifications.h",
        "include/bm/bm_apps/packet_pipe.h",
        "PI/bm/PI/pi.h",
        "targets/simple_switch/bm/simple_switch/runner.h",
        "pdfixed/include/bm/pdfixed/int/pd_conn_mgr.h",
        "pdfixed/include/bm/pdfixed/int/pd_helpers.h",
        "pdfixed/include/bm/pdfixed/int/pd_notifications.h",
        "pdfixed/include/bm/pdfixed/pd_common.h",
        "pdfixed/include/bm/pdfixed/pd_mirroring.h",
        "pdfixed/include/bm/pdfixed/pd_pre.h",
        "pdfixed/include/bm/pdfixed/pd_static.h",
        "pdfixed/include/bm/pdfixed/pd_swap.h",
        "pdfixed/thrift-src/pdfixed_rpc_server.h",
        "pdfixed/thrift-src/conn_mgr_pd_rpc_server.ipp",
        "pdfixed/thrift-src/mc_pd_rpc_server.ipp",
        "pdfixed/thrift-src/sswitch_pd_rpc_server.ipp",
        "pdfixed/thrift/res.thrift",
    ],
)

cc_library(
    name = "bmsim",
    srcs = _BM_SIM_SOURCES,
    hdrs = _BM_SIM_HEADERS,
    includes = ["include", "src/BMI", "src/bf_lpm_trie", "src/bm_sim", "third_party/spdlog"],
    copts = ["-DELOG_ON", "-DTHRIFT_ON", "-DHAVE_THRIFT_STDCXX_H", "-DWP4_16_STACKS"],
    deps = [
        ":bflpmtrie", ":bmi", ":jsoncpp",
        "@p4lang_backend_deps//libboost-dev:libboost",
        "@p4lang_backend_deps//libboost-filesystem1.83-dev:boost_filesystem",
        "@p4lang_backend_deps//libboost-program-options1.83-dev:boost_program_options",
        "@p4lang_backend_deps//libboost-system-dev:libboost-system",
        "@p4lang_backend_deps//libboost-thread1.83-dev:boost_thread",
        "@p4lang_backend_deps//libgmp-dev:libgmp",
        "@p4lang_backend_deps//libnanomsg-dev:libnanomsg",
        "@p4lang_backend_deps//libpcap0.8-dev:pcap",
        "@p4lang_backend_deps//libssl-dev:libssl",
        "@p4lang_backend_deps//libthrift-dev:thrift",
        "@sonic_build_infra//system_libs:pthread",
    ],
)

_THRIFT_DEPS = [
    "@p4lang_backend_deps//libboost-dev:libboost",
    "@p4lang_backend_deps//libthrift-dev:thrift",
]

bmv2_thrift_cc_library(
    name = "standard_thrift",
    src = "thrift_src/standard.thrift",
    outs = [
        "bm/Standard.cpp", "bm/Standard.h", "bm/Standard_server.skeleton.cpp",
        "bm/standard_types.cpp", "bm/standard_types.h",
    ],
    deps = _THRIFT_DEPS,
)

bmv2_thrift_cc_library(
    name = "simple_pre_thrift",
    src = "thrift_src/simple_pre.thrift",
    outs = [
        "bm/SimplePre.cpp", "bm/SimplePre.h", "bm/SimplePre_server.skeleton.cpp",
        "bm/simple_pre_types.cpp", "bm/simple_pre_types.h",
    ],
    deps = _THRIFT_DEPS,
)

bmv2_thrift_cc_library(
    name = "simple_pre_lag_thrift",
    src = "thrift_src/simple_pre_lag.thrift",
    outs = [
        "bm/SimplePreLAG.cpp", "bm/SimplePreLAG.h", "bm/SimplePreLAG_server.skeleton.cpp",
        "bm/simple_pre_lag_types.cpp", "bm/simple_pre_lag_types.h",
    ],
    deps = _THRIFT_DEPS,
)

cc_library(
    name = "runtimestubs",
    deps = [":standard_thrift", ":simple_pre_thrift", ":simple_pre_lag_thrift"],
)

sonic_shared_library_versioned(
    name = "libruntimestubs",
    output_name = "libruntimestubs",
    deps = [":runtimestubs"],
    exports_filter = ["//:__subpackages__"],
    soversion = "0",
    version = "0.0.0",
)

cc_library(
    name = "bmruntime",
    srcs = [
        "src/bm_runtime/server.cpp", "src/bm_runtime/Standard_server.cpp",
        "src/bm_runtime/SimplePre_server.cpp", "src/bm_runtime/SimplePreLAG_server.cpp",
    ],
    includes = ["include"],
    deps = [":bmsim", ":runtimestubs"] + _THRIFT_DEPS,
)

thrift(name = "standard_thrift_py", src = "thrift_src/standard.thrift", language = "py")
thrift(name = "simple_pre_thrift_py", src = "thrift_src/simple_pre.thrift", language = "py")
thrift(name = "simple_pre_lag_thrift_py", src = "thrift_src/simple_pre_lag.thrift", language = "py")

bmv2_thrift_cc_library(
    name = "simple_switch_thrift",
    src = "targets/simple_switch/thrift/simple_switch.thrift",
    outs = [
        "bm/SimpleSwitch.cpp", "bm/SimpleSwitch.h", "bm/SimpleSwitch_server.skeleton.cpp",
        "bm/simple_switch_types.cpp", "bm/simple_switch_types.h",
    ],
    deps = _THRIFT_DEPS,
)

cc_library(
    name = "simpleswitch",
    srcs = [
        "targets/simple_switch/simple_switch.cpp",
        "targets/simple_switch/primitives.cpp",
        "targets/simple_switch/thrift/src/SimpleSwitch_server.cpp",
    ],
    hdrs = [
        "targets/simple_switch/simple_switch.h",
        "targets/simple_switch/register_access.h",
    ],
    includes = ["include", "targets/simple_switch"],
    deps = [":bmsim", ":bmruntime", ":runtimestubs", ":simple_switch_thrift"] + _THRIFT_DEPS,
)

sonic_shared_library_versioned(
    name = "libsimpleswitch_thrift",
    output_name = "libsimpleswitch_thrift",
    deps = [":simple_switch_thrift"],
    exports_filter = ["//:__subpackages__"],
    soversion = "0",
    version = "0.0.0",
)

cc_binary(
    name = "simple_switch",
    srcs = ["targets/simple_switch/main.cpp"],
    deps = [":simpleswitch"],
)

thrift(name = "simple_switch_thrift_py", src = "targets/simple_switch/thrift/simple_switch.thrift", language = "py")

bmv2_thrift_cc_library(
    name = "psa_switch_thrift",
    src = "targets/psa_switch/thrift/psa_switch.thrift",
    outs = [
        "bm/PsaSwitch.cpp", "bm/PsaSwitch.h", "bm/PsaSwitch_server.skeleton.cpp",
        "bm/psa_switch_types.cpp", "bm/psa_switch_types.h",
    ],
    deps = _THRIFT_DEPS,
)

cc_library(
    name = "psaswitch",
    srcs = [
        "targets/psa_switch/psa_switch.cpp",
        "targets/psa_switch/primitives.cpp",
        "targets/psa_switch/externs/psa_counter.cpp",
        "targets/psa_switch/externs/psa_meter.cpp",
        "targets/psa_switch/externs/psa_random.cpp",
        "targets/psa_switch/externs/psa_internet_checksum.cpp",
        "targets/psa_switch/externs/psa_hash.cpp",
        "targets/psa_switch/thrift/src/PsaSwitch_server.cpp",
    ],
    hdrs = [
        "targets/psa_switch/psa_switch.h",
        "targets/psa_switch/externs/psa_counter.h",
        "targets/psa_switch/externs/psa_meter.h",
        "targets/psa_switch/externs/psa_random.h",
        "targets/psa_switch/externs/psa_internet_checksum.h",
        "targets/psa_switch/externs/psa_hash.h",
    ],
    includes = ["include", "targets/psa_switch"],
    deps = [":bmsim", ":bmruntime", ":runtimestubs", ":psa_switch_thrift"] + _THRIFT_DEPS,
)

sonic_shared_library_versioned(
    name = "libpsaswitch_thrift",
    output_name = "libpsaswitch_thrift",
    deps = [":psa_switch_thrift"],
    exports_filter = ["//:__subpackages__"],
    soversion = "0",
    version = "0.0.0",
)

cc_binary(
    name = "psa_switch",
    srcs = ["targets/psa_switch/main.cpp"],
    deps = [":psaswitch"],
)

thrift(name = "psa_switch_thrift_py", src = "targets/psa_switch/thrift/psa_switch.thrift", language = "py")

thrift(name = "pdfixed_res_thrift_py", src = "pdfixed/thrift/res.thrift", language = "py")
thrift(
    name = "pdfixed_conn_mgr_thrift_py",
    src = "pdfixed/thrift/conn_mgr_pd_rpc.thrift",
    language = "py",
    thrift_deps = ["pdfixed/thrift/res.thrift"],
)
thrift(
    name = "pdfixed_mc_thrift_py",
    src = "pdfixed/thrift/mc_pd_rpc.thrift",
    language = "py",
    thrift_deps = ["pdfixed/thrift/res.thrift"],
)
thrift(
    name = "pdfixed_sswitch_thrift_py",
    src = "pdfixed/thrift/sswitch_pd_rpc.thrift",
    language = "py",
    thrift_deps = ["pdfixed/thrift/res.thrift"],
)

cc_library(
    name = "bmpi",
    alwayslink = True,
    srcs = [
        "PI/src/pi.cpp", "PI/src/pi_imp.cpp", "PI/src/pi_tables_imp.cpp",
        "PI/src/pi_act_prof_imp.cpp", "PI/src/pi_counter_imp.cpp",
        "PI/src/pi_meter_imp.cpp", "PI/src/pi_learn_imp.cpp",
        "PI/src/pi_mc_imp.cpp", "PI/src/pi_clone_imp.cpp",
        "PI/src/common.cpp", "PI/src/action_helpers.cpp",
        "PI/src/direct_res_spec.cpp", "PI/src/group_selection.cpp",
        "PI/src/device_state.cpp",
    ],
    hdrs = [
        "PI/bm/PI/pi.h", "PI/src/common.h", "PI/src/action_helpers.h",
        "PI/src/direct_res_spec.h", "PI/src/group_selection.h", "PI/src/device_state.h",
    ],
    includes = ["PI", "include", "targets/simple_switch"],
    copts = ["-DWITH_SIMPLE_SWITCH"],
    deps = [
        ":bmsim", ":simpleswitch",
        "@p4lang_pi_src//:pi", "@p4lang_pi_src//:pip4info",
    ],
)

sonic_shared_library_versioned(
    name = "libbmpi",
    exports_filter = ["//:__subpackages__", "@@+_repo_rules+p4lang_pi_src//:__subpackages__"],
    output_name = "libbmpi",
    srcs = [
        "PI/src/pi.cpp", "PI/src/pi_imp.cpp", "PI/src/pi_tables_imp.cpp",
        "PI/src/pi_act_prof_imp.cpp", "PI/src/pi_counter_imp.cpp",
        "PI/src/pi_meter_imp.cpp", "PI/src/pi_learn_imp.cpp",
        "PI/src/pi_mc_imp.cpp", "PI/src/pi_clone_imp.cpp",
        "PI/src/common.cpp", "PI/src/action_helpers.cpp",
        "PI/src/direct_res_spec.cpp", "PI/src/group_selection.cpp",
        "PI/src/device_state.cpp",
    ],
    hdrs = [
        "PI/bm/PI/pi.h", "PI/src/common.h", "PI/src/action_helpers.h",
        "PI/src/direct_res_spec.h", "PI/src/group_selection.h", "PI/src/device_state.h",
    ],
    includes = ["PI", "include", "targets/simple_switch"],
    copts = ["-DWITH_SIMPLE_SWITCH"],
    deps = [":bmsim", ":simpleswitch", "@p4lang_pi_src//:pi", "@p4lang_pi_src//:pip4info"],
    soversion = "0",
    version = "0.0.0",
)

sonic_shared_library_versioned(
    name = "libsimpleswitch_runner",
    dynamic_deps = [":libbmpi_shared"],
    output_name = "libsimpleswitch_runner",
    srcs = ["targets/simple_switch/runner.cpp"],
    hdrs = ["targets/simple_switch/bm/simple_switch/runner.h"],
    includes = ["PI", "include", "targets/simple_switch"],
    copts = ["-DWITH_PI"],
    deps = [":libbmpi", ":simpleswitch"],
    soversion = "0",
    version = "0.0.0",
)

bmv2_thrift_cc_library(
    name = "pdfixed_res_thrift",
    src = "pdfixed/thrift/res.thrift",
    outs = ["pdfixed_gen/res_types.cpp", "pdfixed_gen/res_types.h"],
    output_dir = "pdfixed_gen",
    deps = _THRIFT_DEPS,
)
bmv2_thrift_cc_library(
    name = "pdfixed_conn_mgr_thrift",
    src = "pdfixed/thrift/conn_mgr_pd_rpc.thrift",
    thrift_deps = ["pdfixed/thrift/res.thrift"],
    outs = ["pdfixed_gen/conn_mgr.cpp", "pdfixed_gen/conn_mgr.h", "pdfixed_gen/conn_mgr_pd_rpc_types.h", "pdfixed_gen/conn_mgr_server.skeleton.cpp"],
    output_dir = "pdfixed_gen",
    deps = [":pdfixed_res_thrift"] + _THRIFT_DEPS,
)
bmv2_thrift_cc_library(
    name = "pdfixed_mc_thrift",
    src = "pdfixed/thrift/mc_pd_rpc.thrift",
    thrift_deps = ["pdfixed/thrift/res.thrift"],
    outs = ["pdfixed_gen/mc.cpp", "pdfixed_gen/mc.h", "pdfixed_gen/mc_pd_rpc_types.h", "pdfixed_gen/mc_server.skeleton.cpp"],
    output_dir = "pdfixed_gen",
    deps = [":pdfixed_res_thrift"] + _THRIFT_DEPS,
)
bmv2_thrift_cc_library(
    name = "pdfixed_sswitch_thrift",
    src = "pdfixed/thrift/sswitch_pd_rpc.thrift",
    thrift_deps = ["pdfixed/thrift/res.thrift"],
    outs = ["pdfixed_gen/sswitch.cpp", "pdfixed_gen/sswitch.h", "pdfixed_gen/sswitch_pd_rpc_types.h", "pdfixed_gen/sswitch_server.skeleton.cpp"],
    output_dir = "pdfixed_gen",
    deps = [":pdfixed_res_thrift"] + _THRIFT_DEPS,
)

sonic_shared_library_versioned(
    name = "libbmpdfixed",
    output_name = "libbmpdfixed",
    srcs = [
        "pdfixed/src/pd_notifications.cpp", "pdfixed/src/pd_helpers.cpp",
        "pdfixed/src/pd_pre.cpp", "pdfixed/src/pd_mirroring.cpp",
        "pdfixed/src/pd_static.cpp", "pdfixed/src/pd_swap.cpp",
    ],
    hdrs = [
        "pdfixed/include/bm/pdfixed/int/pd_helpers.h",
        "pdfixed/include/bm/pdfixed/int/pd_conn_mgr.h",
        "pdfixed/include/bm/pdfixed/int/pd_notifications.h",
        "pdfixed/include/bm/pdfixed/pd_common.h",
        "pdfixed/include/bm/pdfixed/pd_mirroring.h",
        "pdfixed/include/bm/pdfixed/pd_pre.h",
        "pdfixed/include/bm/pdfixed/pd_static.h",
        "pdfixed/include/bm/pdfixed/pd_swap.h",
    ],
    includes = ["include", "pdfixed/include"],
    deps = [":bmsim", ":runtimestubs", ":simple_switch_thrift"],
    soversion = "0",
    version = "0.0.0",
)

sonic_shared_library_versioned(
    name = "libbmpdfixedthrift",
    output_name = "libbmpdfixedthrift",
    srcs = ["pdfixed/thrift-src/pdfixed_rpc_server.cpp"],
    hdrs = [
        "pdfixed/thrift-src/pdfixed_rpc_server.h",
        "pdfixed/thrift-src/conn_mgr_pd_rpc_server.ipp",
        "pdfixed/thrift-src/mc_pd_rpc_server.ipp",
        "pdfixed/thrift-src/sswitch_pd_rpc_server.ipp",
    ],
    includes = ["include", "pdfixed/include", "pdfixed/thrift-src"],
    deps = [
        ":libbmpdfixed", ":simpleswitch", ":simple_switch_thrift",
        ":pdfixed_conn_mgr_thrift", ":pdfixed_mc_thrift", ":pdfixed_sswitch_thrift",
    ] + _THRIFT_DEPS,
    soversion = "0",
    version = "0.0.0",
)

sonic_shared_library_versioned(
    name = "libbmall",
    output_name = "libbmall",
    deps = [
        ":bmsim", ":bmruntime", ":runtimestubs", ":bflpmtrie", ":bmi", ":jsoncpp",
    ],
    soversion = "0",
    version = "0.0.0",
)

proto_library(
    name = "dataplane_interface_proto",
    srcs = ["services/p4/bm/dataplane_interface.proto"],
)

cc_proto_library(
    name = "dataplane_interface_cc_proto",
    deps = [":dataplane_interface_proto"],
)

py_proto_library(
    name = "dataplane_interface_py_proto",
    deps = [":dataplane_interface_proto"],
)

py_grpc_library(
    name = "dataplane_interface_py_grpc",
    srcs = [":dataplane_interface_proto"],
    deps = [":dataplane_interface_py_proto"],
)

cc_grpc_library(
    name = "dataplane_interface_cc_grpc",
    srcs = [":dataplane_interface_proto"],
    deps = [":dataplane_interface_cc_proto"],
    grpc_only = True,
)

genrule(
    name = "dataplane_install_headers",
    srcs = ["services/p4/bm/dataplane_interface.proto"],
    outs = [
        "dataplane_install/p4/bm/dataplane_interface.pb.h",
        "dataplane_install/p4/bm/dataplane_interface.grpc.pb.h",
    ],
    cmd = """
root=$(location services/p4/bm/dataplane_interface.proto)
root=$${root%/*}
root=$${root%/*}
root=$${root%/*}
mkdir -p $(RULEDIR)/dataplane_install
$(location @protobuf//:protoc) -I$$root --cpp_out=$(RULEDIR)/dataplane_install $(location services/p4/bm/dataplane_interface.proto)
$(location @protobuf//:protoc) -I$$root --grpc_out=$(RULEDIR)/dataplane_install --plugin=protoc-gen-grpc=$(location @com_github_grpc_grpc//src/compiler:grpc_cpp_plugin) $(location services/p4/bm/dataplane_interface.proto)
""",
    tools = [
        "@protobuf//:protoc",
        "@com_github_grpc_grpc//src/compiler:grpc_cpp_plugin",
    ],
)

sonic_shared_library_versioned(
    name = "libbm_grpc_dataplane",
    output_name = "libbm_grpc_dataplane",
    deps = [
        ":dataplane_interface_cc_grpc",
        "@com_github_grpc_grpc//:grpc++",
    ],
    exports_filter = ["//:__subpackages__"],
    soversion = "0",
    version = "0.0.0",
)

cc_library(
    name = "simple_switch_grpc_lib",
    srcs = ["targets/simple_switch_grpc/switch_runner.cpp"],
    hdrs = ["targets/simple_switch_grpc/switch_runner.h"],
    includes = ["PI", "include", "targets/simple_switch", "targets/simple_switch_grpc"],
    copts = ["-DWITH_THRIFT"],
    deps = [
        ":bmpi",
        ":bmruntime",
        ":dataplane_interface_cc_grpc",
        ":runtimestubs",
        ":simple_switch_thrift",
        ":simpleswitch",
        "@com_github_grpc_grpc//:grpc++",
        "@p4lang_pi_src//:pi",
        "@p4lang_pi_src//:pip4info",
        "@p4lang_pi_src//proto/frontend:pifeproto",
        "@p4lang_pi_src//proto/server:piserver",
    ] + _THRIFT_DEPS,
)

cc_binary(
    name = "simple_switch_grpc",
    srcs = ["targets/simple_switch_grpc/main.cpp"],
    linkopts = ["-rdynamic"],
    deps = [
        ":simple_switch_grpc_lib",
        "@com_github_grpc_grpc//:grpc++_reflection",
    ],
)

cc_library(
    name = "bmapps",
    srcs = [
        "src/bm_apps/learn.cpp",
        "src/bm_apps/notifications.cpp",
        "src/bm_apps/packet_pipe.cpp",
    ],
    hdrs = [
        "include/bm/bm_apps/learn.h",
        "include/bm/bm_apps/notifications.h",
        "include/bm/bm_apps/packet_pipe.h",
        "src/bm_apps/nn.h",
    ],
    includes = ["include", "src/bm_apps"],
    deps = [
        ":bmsim",
        ":runtimestubs",
        "@p4lang_backend_deps//libnanomsg-dev:libnanomsg",
    ] + _THRIFT_DEPS,
)

sonic_shared_library_versioned(
    name = "libbmp4apps",
    output_name = "libbmp4apps",
    srcs = [
        "src/bm_apps/learn.cpp",
        "src/bm_apps/notifications.cpp",
        "src/bm_apps/packet_pipe.cpp",
    ],
    hdrs = [
        "include/bm/bm_apps/learn.h",
        "include/bm/bm_apps/notifications.h",
        "include/bm/bm_apps/packet_pipe.h",
        "src/bm_apps/nn.h",
    ],
    includes = ["include", "src/bm_apps"],
    deps = [
        ":bmsim",
        ":runtimestubs",
        "@p4lang_backend_deps//libnanomsg-dev:libnanomsg",
    ] + _THRIFT_DEPS,
    soversion = "0",
    version = "0.0.0",
)
