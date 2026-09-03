load("@rules_cc//cc:defs.bzl", "cc_library")

def bmv2_thrift_cc_library(name, src, outs, deps = [], thrift_deps = [], output_dir = "bm"):
    native.genrule(
        name = name + "_gen",
        srcs = [src] + thrift_deps,
        outs = outs,
        cmd = "mkdir -p $(@D)/{out} && $(THRIFT) --gen cpp {incs} -out $(@D)/{out} $(location {src})".format(
            out = output_dir,
            incs = " ".join(["-I $$(dirname $(location %s))" % dep for dep in thrift_deps]),
            src = src,
        ),
        tools = ["@rules_thrift//:thrift_compiler"],
        toolchains = ["@rules_thrift//:thrift_toolchain_for_make_var"],
    )
    cc_library(
        name = name,
        srcs = [f for f in outs if f.endswith(".cpp") and not f.endswith(".skeleton.cpp")],
        hdrs = [f for f in outs if f.endswith(".h")],
        includes = [".", output_dir],
        deps = deps,
    )
