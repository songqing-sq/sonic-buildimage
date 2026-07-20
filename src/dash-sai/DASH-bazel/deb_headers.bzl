"""deb_headers: expose the C/C++ headers shipped inside one or more .deb / apt
`:data` tarballs to cc rules as a single `-isystem` include root.

The DASH SAI implementation (dash-pipeline/SAI/lib/*.cpp) `#include`s protobuf
3.21.x, grpc++, P4Runtime (`p4/v1/*.pb.h`) and PI headers. In the upstream Make
build these live in the build container's /usr/include (from libprotobuf-dev,
libgrpc++-dev, p4lang-pi, ...). libsai.so is only *compiled* against them — it
never *links* them (the resulting .so carries the protobuf/grpc/p4/absl symbols
as UNDEFINED, resolved at load time inside the p4/bmv2 host process).

This rule extracts the `usr/include` trees of the given debs/tars into one merged
directory and returns a CcInfo whose compilation_context marks that directory as
a *system* include path (`-isystem`). Using `-isystem` (not `-I`) keeps the SAI
library's strict `-Werror -Wconversion ...` flags from firing on third-party
headers, exactly as `/usr/include` would behave under GCC.
"""

def _deb_headers_impl(ctx):
    incroot = ctx.actions.declare_directory(ctx.label.name + ".incroot")

    inputs = list(ctx.files.tars) + list(ctx.files.debs)

    parts = [
        "set -eu",
        "OUT=%s" % incroot.path,
        "mkdir -p \"$OUT\"",
        "TMP=$(mktemp -d)",
        "trap 'rm -rf \"$TMP\"' EXIT",
    ]

    # apt `:data` tarballs (gzip/zstd tar rooted at ./). Extract, then merge any
    # usr/include tree into the shared include root.
    for t in ctx.files.tars:
        parts.append("D=$(mktemp -d -p \"$TMP\")")
        parts.append("tar -xf %s -C \"$D\"" % t.path)
        parts.append("if [ -d \"$D/usr/include\" ]; then cp -a \"$D/usr/include/.\" \"$OUT/\"; fi")

    # Raw .deb archives (ar container). dpkg-deb -x unpacks the data member
    # irrespective of its compression (xz/zstd), matching the other genrules in
    # this module (p4_compile / sai_gen) that already rely on host dpkg-deb.
    for d in ctx.files.debs:
        parts.append("D=$(mktemp -d -p \"$TMP\")")
        parts.append("dpkg-deb -x %s \"$D\"" % d.path)
        parts.append("if [ -d \"$D/usr/include\" ]; then cp -a \"$D/usr/include/.\" \"$OUT/\"; fi")

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [incroot],
        command = "\n".join(parts),
        env = {"PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"},
        mnemonic = "DebHeaders",
        progress_message = "Extracting deb headers for %s" % ctx.label.name,
    )

    compilation_context = cc_common.create_compilation_context(
        headers = depset([incroot]),
        system_includes = depset([incroot.path]),
    )

    return [
        DefaultInfo(files = depset([incroot])),
        CcInfo(compilation_context = compilation_context),
    ]

deb_headers = rule(
    implementation = _deb_headers_impl,
    doc = "Merge the usr/include trees of .deb/apt-:data inputs into one -isystem CcInfo.",
    attrs = {
        "tars": attr.label_list(
            allow_files = True,
            doc = "apt `:data` tarballs (rules_distroless) to harvest usr/include from.",
        ),
        "debs": attr.label_list(
            allow_files = [".deb"],
            doc = "Raw .deb archives to harvest usr/include from (via dpkg-deb -x).",
        ),
    },
    provides = [CcInfo],
)
