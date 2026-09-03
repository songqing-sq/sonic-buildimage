"""Expose a C++ dependency's headers without propagating its link inputs."""

def _cc_headers_only_impl(ctx):
    generated_headers = [f for f in ctx.files.generated if f.extension == "h"]
    generated_roots = []
    for header in generated_headers:
        root = header.dirname
        for _part in ctx.attr.strip_include_prefix.split("/"):
            root = root.rpartition("/")[0]
        generated_roots.append(root)

    contexts = [dep[CcInfo].compilation_context for dep in ctx.attr.deps]
    return [CcInfo(compilation_context = cc_common.create_compilation_context(
        headers = depset(
            direct = generated_headers,
            transitive = [context.headers for context in contexts],
        ),
        system_includes = depset(
            direct = generated_roots,
            transitive = [
                include_dirs
                for context in contexts
                for include_dirs in [
                    context.includes,
                    context.quote_includes,
                    context.system_includes,
                ]
            ],
        ),
    ))]

cc_headers_only = rule(
    implementation = _cc_headers_only_impl,
    attrs = {
        "deps": attr.label_list(mandatory = True, providers = [CcInfo]),
        "generated": attr.label(allow_files = True),
        "strip_include_prefix": attr.string(),
    },
)
