"""Repository rule that materialises a *patched* FRR 10.5.4 source tree.

Approach-B (cc-rebuild) migration of sonic-frr needs the pristine upstream
FRR submodule at `src/sonic-frr/frr/` PLUS the 85 external patches in
`src/sonic-frr/patch/` applied in `series` order (mirroring the Make recipe's
`stg import -s ../patch/series`), and the SONiC-private
`dplane_fpm_sonic/dplane_fpm_sonic.c` copied into `zebra/` (mirroring the Make
recipe's `cp ../dplane_fpm_sonic/dplane_fpm_sonic.c zebra/`).

The reference migration (sonic-alibgp) checked in an already-patched tree so
its BUILD.bazel could glob `alibgp/**` directly.  We have pristine upstream +
external patches, so we reproduce the same shape hermetically inside Bazel:

  1. copy `frr/` -> @frr_patched repo root
  2. apply `patch/series` with `patch -p1` in order
  3. copy dplane_fpm_sonic.c into zebra/
  4. drop in a BUILD.bazel (the real cc rules) + clippy_helpers.bzl

Because the patched tree lands at the @frr_patched repo ROOT, the BUILD file
can glob `lib/**/*.h`, `zebra/*.c`, etc. and use `strip_include_prefix` the
exact same way the reference does with the `alibgp/` prefix -- just with no
prefix component.  This keeps the port structurally faithful to the reference.
"""

def _frr_patched_impl(repository_ctx):
    # Locate the sonic-frr module root via a sentinel label (patch/series is
    # a real file that always exists).  dirname twice -> module root.
    series = repository_ctx.path(repository_ctx.attr.series)
    patch_dir = series.dirname
    module_root = patch_dir.dirname
    frr_dir = module_root.get_child("frr")
    dplane_c = module_root.get_child("dplane_fpm_sonic").get_child("dplane_fpm_sonic.c")

    # 1. Copy the pristine submodule tree into a `frr/` subdirectory of the
    #    repo root.  Mirroring the sonic-alibgp reference's `alibgp/` prefix
    #    layout avoids output-path collisions between daemon binaries (e.g.
    #    //:staticd) and the identically-named source subdirectory (staticd/).
    res = repository_ctx.execute(
        ["cp", "-a", str(frr_dir), "frr"],
        quiet = True,
    )
    if res.return_code != 0:
        fail("frr_patched: failed to copy frr tree:\n%s\n%s" % (res.stdout, res.stderr))
    repository_ctx.execute(["rm", "-rf", "frr/.git"], quiet = True)

    # 2. Apply the patch series with `patch -p1` in order (inside frr/).
    series_content = repository_ctx.read(series)
    for line in series_content.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        patch_path = patch_dir.get_child(line)
        repository_ctx.watch(patch_path)
        res = repository_ctx.execute(
            ["patch", "-p1", "--no-backup-if-mismatch", "-i", str(patch_path)],
            quiet = True,
            working_directory = "frr",
        )
        if res.return_code != 0:
            fail("frr_patched: failed to apply patch %s:\n%s\n%s" % (
                line,
                res.stdout,
                res.stderr,
            ))

    # 3. Copy the SONiC dplane_fpm_sonic module into zebra/ (patch 0012 wires
    #    zebra/subdir.am to build zebra/dplane_fpm_sonic.c into a plugin .so).
    res = repository_ctx.execute(
        ["cp", str(dplane_c), "frr/zebra/dplane_fpm_sonic.c"],
        quiet = True,
    )
    if res.return_code != 0:
        fail("frr_patched: failed to copy dplane_fpm_sonic.c:\n%s\n%s" % (res.stdout, res.stderr))

    # 4. Materialise the build wiring.  clippy_helpers.bzl + the BUILD template
    #    are symlinked in from the sonic-frr module so the patched tree can be
    #    built as-is.
    repository_ctx.symlink(repository_ctx.attr.clippy_helpers, "clippy_helpers.bzl")
    repository_ctx.symlink(repository_ctx.attr.build_file, "BUILD.bazel")

frr_patched = repository_rule(
    implementation = _frr_patched_impl,
    attrs = {
        "series": attr.label(
            mandatory = True,
            doc = "Label of patch/series (used to locate the module root).",
        ),
        "build_file": attr.label(
            mandatory = True,
            doc = "BUILD.bazel to drop into the patched repo root.",
        ),
        "clippy_helpers": attr.label(
            mandatory = True,
            doc = "clippy_helpers.bzl to expose inside the patched repo.",
        ),
        "patches_marker": attr.label(
            doc = "Marker input so edits to the patch set retrigger the fetch.",
        ),
    },
)
