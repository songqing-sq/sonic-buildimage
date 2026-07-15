"""Run cffi's FFI.emit_c_code() to turn cdefs.h + source.c into _libyang.c.

cffi is venv-gated in the @libyang3_py3_pip hub. To pull it in we apply
a rule transition that sets the @aspect_rules_py venv flag to "default"
(the venv we declared in MODULE.bazel). Same idea as
sonic_rules//python:site_packages.bzl `_venv_transition`.
"""

load("@aspect_rules_py//py/private/py_venv:types.bzl", "VirtualenvInfo")

_VENV_FLAG = "@aspect_rules_py//uv/private/constraints/venv:venv"
_PLATFORMS_FLAG = "//command_line_option:platforms"

def _venv_default_transition_impl(settings, attr):
    return {
        _VENV_FLAG: "default",
        # cffi codegen is pure-python but executed via the venv's host
        # python3 binary; pin to x86_64 so cross-compiling to aarch64 still
        # invokes an executable interpreter.
        _PLATFORMS_FLAG: [str(Label("@sonic_build_infra//platform:x86_64_trixie"))],
    }

_venv_default_transition = transition(
    implementation = _venv_default_transition_impl,
    inputs = [],
    outputs = [_VENV_FLAG, _PLATFORMS_FLAG],
)

def _libyang_cffi_emit_impl(ctx):
    venv_home = ctx.attr.venv[0][VirtualenvInfo].home
    venv_files = ctx.attr.venv[0][DefaultInfo].files.to_list()
    out = ctx.actions.declare_file(ctx.label.name + ".c")

    driver = ctx.actions.declare_file(ctx.label.name + "_emit.py")
    ctx.actions.write(
        output = driver,
        content = """\
import sys
import cffi
cdefs_path, source_path, out_path = sys.argv[1:4]
cdefs = open(cdefs_path).read()
source = open(source_path).read()
b = cffi.FFI()
b.cdef(cdefs)
b.set_source("_libyang", source, libraries=["yang"])
b.emit_c_code(out_path)
""",
    )

    command = """
set -e
"{python}" "{driver}" "{cdefs}" "{source}" "{out}"
""".format(
        python = venv_home.path + "/bin/python3",
        driver = driver.path,
        cdefs = ctx.file.cdefs.path,
        source = ctx.file.source.path,
        out = out.path,
    )

    ctx.actions.run_shell(
        command = command,
        inputs = [venv_home, driver, ctx.file.cdefs, ctx.file.source] + venv_files,
        outputs = [out],
        mnemonic = "CffiEmit",
        progress_message = "Generating %s via cffi.emit_c_code()" % out.short_path,
    )

    return [DefaultInfo(files = depset([out]))]

libyang_cffi_emit = rule(
    implementation = _libyang_cffi_emit_impl,
    attrs = {
        "venv": attr.label(
            doc = "A py_venv target with `cffi` installed; its python3 is invoked.",
            providers = [VirtualenvInfo],
            mandatory = True,
            cfg = _venv_default_transition,
        ),
        "cdefs": attr.label(allow_single_file = True, mandatory = True),
        "source": attr.label(allow_single_file = True, mandatory = True),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)
