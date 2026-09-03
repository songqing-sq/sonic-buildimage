load("@sonic_build_infra//shared_library:shared_library.bzl", "SymlinkInfo")

def _python_tree_impl(ctx):
    output = ctx.actions.declare_directory(ctx.label.name)
    inputs = depset(transitive = [target.files for target in ctx.attr.srcs])
    args = ctx.actions.args()
    args.add(output.path)
    args.add_all(inputs)
    ctx.actions.run_shell(
        arguments = [args],
        command = """
set -eu
out="$1"
shift
mkdir -p "$out"
for src in "$@"; do
  rel=""
  for marker in standard_thrift_py simple_pre_thrift_py simple_pre_lag_thrift_py simple_switch_thrift_py psa_switch_thrift_py pdfixed_res_thrift_py pdfixed_conn_mgr_thrift_py pdfixed_mc_thrift_py pdfixed_sswitch_thrift_py; do
    case "$src" in
      */$marker/*) rel="${src#*/$marker/}" ;;
    esac
    test -z "$rel" || break
  done
  case "$src" in
    *p4lang_bmv2_src/services/p4/bm/*) rel="p4/bm/${src##*/}" ;;
  esac
  test -n "$rel" || continue
  test "$rel" != "__init__.py" || continue
  dst="$out/$rel"
  mkdir -p "${dst%/*}"
  test ! -e "$dst" || continue
  cp "$src" "$dst"
done
mkdir -p "$out/p4/bm"
touch "$out/p4/bm/__init__.py"
""",
        inputs = inputs,
        outputs = [output],
        mnemonic = "Bmv2PythonInstallTree",
    )
    return [DefaultInfo(files = depset([output]))]

bmv2_python_tree = rule(
    implementation = _python_tree_impl,
    attrs = {"srcs": attr.label_list(mandatory = True)},
)

def _wrapper_impl(ctx):
    output = ctx.actions.declare_file(ctx.attr.output)
    ctx.actions.expand_template(
        template = ctx.file.src,
        output = output,
        substitutions = {"@pythondir@": "/usr/lib/python3/dist-packages"},
        is_executable = True,
    )
    return [DefaultInfo(files = depset([output]), executable = output)]

bmv2_python_wrapper = rule(
    implementation = _wrapper_impl,
    attrs = {
        "src": attr.label(mandatory = True, allow_single_file = True),
        "output": attr.string(mandatory = True),
    },
    executable = True,
)

def _library_links_impl(ctx):
    outputs = []
    destinations = {}
    for name, target in ctx.attr.links.items():
        output = ctx.actions.declare_symlink(ctx.label.name + "/" + name)
        ctx.actions.symlink(output = output, target_path = target)
        outputs.append(output)
        destinations[output.path] = target
    return [
        DefaultInfo(files = depset(outputs)),
        SymlinkInfo(dest = "", extra_dest = destinations),
    ]

bmv2_library_links = rule(
    implementation = _library_links_impl,
    attrs = {"links": attr.string_dict(mandatory = True)},
)

def _header_tree_impl(ctx):
    output = ctx.actions.declare_directory(ctx.label.name)
    files = []
    for target in ctx.attr.srcs:
        files.extend(target.files.to_list())
    inputs = depset(files)
    args = ctx.actions.args()
    args.add(output.path)
    args.add_all(inputs)
    ctx.actions.run_shell(
        arguments = [args],
        command = """
set -eu
out="$1"
shift
mkdir -p "$out"
for src in "$@"; do
  rel=""
  case "$src" in
    *p4lang_bmv2_src/include/*) rel="${src#*p4lang_bmv2_src/include/}" ;;
    *p4lang_bmv2_src/pdfixed/include/*) rel="${src#*p4lang_bmv2_src/pdfixed/include/}" ;;
    *p4lang_bmv2_src/third_party/spdlog/bm/*) rel="bm/${src#*p4lang_bmv2_src/third_party/spdlog/bm/}" ;;
    *p4lang_bmv2_src/PI/bm/*) rel="bm/${src#*p4lang_bmv2_src/PI/bm/}" ;;
    *p4lang_bmv2_src/targets/simple_switch/bm/*) rel="bm/${src#*p4lang_bmv2_src/targets/simple_switch/bm/}" ;;
    *p4lang_bmv2_src/pdfixed/thrift-src/*) rel="bm/pdfixed/thrift-src/${src#*p4lang_bmv2_src/pdfixed/thrift-src/}" ;;
    *p4lang_bmv2_src/pdfixed/thrift/*) rel="bm/pdfixed/thrift/${src#*p4lang_bmv2_src/pdfixed/thrift/}" ;;
    *p4lang_bmv2_src/_virtual_imports/dataplane_interface_proto/p4/*) rel="p4/${src#*p4lang_bmv2_src/_virtual_imports/dataplane_interface_proto/p4/}" ;;
    *p4lang_bmv2_src/services/p4/*) rel="p4/${src#*p4lang_bmv2_src/services/p4/}" ;;
    *p4lang_bmv2_src/dataplane_install/p4/*) rel="p4/${src#*p4lang_bmv2_src/dataplane_install/p4/}" ;;
    *p4lang_bmv2_src/bm/*) rel="bm/${src#*p4lang_bmv2_src/bm/}" ;;
  esac
  case "$rel" in *.h|*.ipp|*.thrift) ;; *) continue ;; esac
  dst="$out/$rel"
  mkdir -p "${dst%/*}"
  test -e "$dst" || cp "$src" "$dst"
done
""",
        inputs = inputs,
        outputs = [output],
        mnemonic = "Bmv2HeaderInstallTree",
    )
    return [DefaultInfo(files = depset([output]))]

bmv2_header_tree = rule(
    implementation = _header_tree_impl,
    attrs = {"srcs": attr.label_list(mandatory = True)},
)
