"""Hermetic sources for the SONiC-built host packages the vs image installs.

Ground truth for WHICH packages the host fs needs is the Make build's
fsroot-vs/var/lib/dpkg/status (57 SONiC-built debs). This file records where
each one comes from in the BAZEL build — never from target/debs, which is a
Make artifact; every entry below is a hermetic Bazel target.

HERMETIC_HOST_DEBS maps package -> the sonic_deb base target name. The macro
generates `<name>_data` (the deb's data tar, laid into the rootfs) and
`<name>_statusd` (registers the package in /var/lib/dpkg/status.d).

Packages not yet migrated are listed explicitly so the gap is visible rather
than silently bridged from Make output.
"""

# Produced by a hermetic sonic_deb elsewhere in the workspace.
HERMETIC_HOST_DEBS = {
    "libswsscommon": "@sonic-swss-common//:libswsscommon_1.0.0.deb",
    "python3-swsscommon": "@sonic-swss-common//:python3-swsscommon_1.0.0.deb",
    "sonic-db-cli": "@sonic-swss-common//:sonic-db-cli_1.0.0.deb",
    "iproute2": "@iproute2//:iproute2_6.15.0-1.deb",
    "libyang3": "@libyang3//:libyang3_3.12.2-1.deb",
    "python3-libyang": "@libyang3-py3//:python3-libyang_3.1.0-1.deb",
    "libsensors5": "@lm-sensors//:libsensors5_3.6.0-7.1.deb",
    "socat": "@socat//:socat_1.8.0.3-1.deb",
    "sonic-rsyslog-plugin": "@sonic-eventd//:sonic-rsyslog-plugin_1.0.0-0.deb",
    # Upstream v0.142 rebuilt with SONiC's two loopback patches (BOOT-CRITICAL:
    # mount_loop_root loop-mounts fs.squashfs). Debian trixie ships 0.148.3,
    # which the patches do not apply to, hence the pinned salsa tarball.
    "initramfs-tools": "@initramfs-tools//:initramfs-tools_0.142_all.deb",
    "initramfs-tools-core": "@initramfs-tools//:initramfs-tools-core_0.142_all.deb",
}

# Packages SONiC merely REBUILDS from Debian source at the same upstream
# version, with no patch that changes shipped behaviour: the binary from the
# pinned @trixie snapshot is equivalent, so they ship via base_layer
# (HOST_PACKAGES) rather than as a SONiC deb.
DEBIAN_EQUIVALENT = [
    "bash",
    "monit",
    "rasdaemon",
    "makedumpfile",
    "kdump-tools",
    "ifupdown2",
    "grub-common",
    "grub2-common",
    "sedutil",
    "libpam-radius-auth",
    "libnl-3-200",
    "libnl-cli-3-200",
    "libnl-genl-3-200",
    "libnl-nf-3-200",
    "libnl-route-3-200",
]

# Awaiting a hermetic sonic_deb. No Make bridge is used for these — until each
# lands the image simply lacks it, which is visible rather than papered over.
#
#   tacacs/radius, Rust daemons, data-only packages: SONiC-only sources.
#   FIPS stack: needs symcrypt-openssl, then OpenSSL/CPython/OpenSSH/krb5
#       rebuilt against it.
TODO_HERMETIC = [
    "libtac2",
    "libpam-tacplus",
    "libnss-tacplus",
    "audisp-tacplus",
    "bash-tacplus",
    "libnss-radius",
    "sonic-ctrmgrd-rs",
    "sonic-host-services-rs",
    "sonic-nettools",
    "syslog-counter",
    "sonic-device-data",
    "sonic-host-services-data",
    "sonic-utilities-data",
    "systemd-sonic-generator",
    "symcrypt-openssl",
    "openssl",
    "libssl3t64",
    "libssl-dev",
    "python3.13",
    "python3.13-minimal",
    "libpython3.13",
    "libpython3.13-minimal",
    "libpython3.13-stdlib",
    "openssh-client",
    "openssh-server",
    "openssh-sftp-server",
    "ssh",
    "libkrb5-3",
    "libk5crypto3",
    "libkrb5support0",
    "libgssapi-krb5-2",
]
