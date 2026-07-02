"""Wrap an externally-downloaded .deb file into the SONiC `_data` + `_statusd`
target convention used by sonic-vs.bin's oci_image consumers.

The legacy `rules/sonic-fips.mk` `wget`s these debs at build time and
`dpkg -i`s them directly into the host root filesystem. For Bazel, we need
two artifacts per .deb so the OCI image composer can stack them:

  <name>_data    — content.tar.gz (the deb's data.tar.* normalized to gzip)
  <name>_statusd — tar layer placing /var/lib/dpkg/status.d/<pkg> stubs so
                    `dpkg -l` inside the container lists the package

The .deb file itself is also re-exposed under `<name>` as an alias to the
http_file label so any consumer that wants the raw .deb (e.g. the host
filesystem composer) can reach it through `//src/sonic-fips:<filename>.deb`.
"""

load("@rules_deb//apt:defs.bzl", "dpkg_statusd")

def external_fips_deb(name, src, package_name, visibility = ["//visibility:public"]):
    """Wrap an http_file-downloaded .deb into _data + _statusd + alias targets.

    Args:
      name:         Bazel target base. By convention pass the upstream
                    .deb filename (e.g. `libssl3_3.0.11-1~deb12u2+fips_amd64.deb`).
                    The macro generates `<name>`, `<name>_data`, `<name>_statusd`.
      src:          Label of the http_file target (e.g. `@fips_libssl3//file`).
      package_name: Debian package name as it should appear in
                    `/var/lib/dpkg/status.d/<pkg>` (e.g. `libssl3`).
      visibility:   Visibility for the generated targets.
    """

    # Extract `data.tar.*` from the .deb (an `ar` archive) and re-stream
    # through bsdtar so the output is always gzip-compressed. The OCI image
    # spec only supports tar+gzip and tar+zstd; data.tar.xz (the Debian
    # default for these FIPS debs) is not acceptable as a layer directly.
    native.genrule(
        name = name + "_extract_data",
        srcs = [src],
        outs = [name + ".content.tar.gz"],
        cmd = """
set -eo pipefail
tmp=$$(mktemp -d)
trap 'rm -rf $$tmp' EXIT
"$(BSDTAR_BIN)" -xf $< -C $$tmp
data_file=$$(ls $$tmp/data.tar.* | head -n1)
"$(BSDTAR_BIN)" --gzip -cf $@ "@$$data_file"
""",
        toolchains = ["@bsd_tar_toolchains//:resolved_toolchain"],
        visibility = visibility,
    )

    # Extract `control.tar.*` so dpkg_statusd can read ./control + ./md5sums
    # and produce the /var/lib/dpkg/status.d/<pkg> stub layer.
    #
    # dpkg_statusd.sh hard-requires `./md5sums` in the control tar (it
    # passes `--include "^./md5sums$"` to bsdtar and treats absence as a
    # fatal error). Some upstream FIPS debs (notably symcrypt-openssl) do
    # not ship a `./md5sums` file in their control tar. We unpack the
    # control tar, materialize an empty `./md5sums` placeholder when
    # missing, then repack as `.tar.gz`. `dpkg -l` will still list the
    # package; only `debsums` verification is degraded, which
    # sonic-vs.bin does not run.
    native.genrule(
        name = name + "_extract_control",
        srcs = [src],
        outs = [name + ".control.tar.gz"],
        cmd = """
set -eo pipefail
tmp=$$(mktemp -d)
trap 'rm -rf $$tmp' EXIT
"$(BSDTAR_BIN)" -xf $< -C $$tmp
ctl_file=$$(ls $$tmp/control.tar.* | head -n1)
unpacked=$$tmp/unpacked
mkdir -p $$unpacked
"$(BSDTAR_BIN)" -xf $$ctl_file -C $$unpacked
[ -f $$unpacked/md5sums ] || : > $$unpacked/md5sums
"$(BSDTAR_BIN)" --gzip -cf $@ -C $$unpacked .
""",
        toolchains = ["@bsd_tar_toolchains//:resolved_toolchain"],
        visibility = visibility,
    )

    # Canonical `_data` alias — consumers reference this as the image layer.
    native.alias(
        name = name + "_data",
        actual = ":" + name + "_extract_data",
        visibility = visibility,
    )

    # /var/lib/dpkg/status.d/<pkg> stub tar layer.
    dpkg_statusd(
        name = name + "_statusd",
        package_name = package_name,
        control = ":" + name + "_extract_control",
        visibility = visibility,
    )

    # Re-expose the raw .deb file under the conventional Bazel name so
    # consumers that want the file itself (host filesystem assembly,
    # tests, debug) can reach it via `//src/sonic-fips:<filename>`.
    native.alias(
        name = name,
        actual = src,
        visibility = visibility,
    )
