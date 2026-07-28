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
    "systemd-sonic-generator": "@systemd-sonic-generator//:systemd-sonic-generator_1.0.0.deb",
    "libtac2": "@pam-tacplus//:libtac2_1.4.1-1.deb",
    "libpam-tacplus": "@pam-tacplus//:libpam-tacplus_1.4.1-1.deb",
    "libnss-tacplus": "@libnss-tacplus//:libnss-tacplus_1.0.4-1.deb",
    "audisp-tacplus": "@audisp-tacplus//:audisp-tacplus_1.0.2.deb",
    "bash-tacplus": "@bash-tacplus//:bash-tacplus_1.0.0.deb",
    "libnss-radius": "@libnss-radius//:libnss-radius_1.0.1-1.deb",
    "sonic-host-services-data": "@sonic-host-services//:sonic-host-services-data_1.0-1_all.deb",
    "sonic-utilities-data": "@sonic-utilities//:sonic-utilities-data_1.0-1_all.deb",
    "sonic-ctrmgrd-rs": "@sonic-ctrmgrd-rs//:sonic-ctrmgrd-rs_1.0.0.deb",
    "sonic-host-services-rs": "@sonic-host-services//:sonic-host-services-rs_1.0.0.deb",
    "sonic-nettools": "@sonic-nettools//:sonic-nettools_0.0.1-0.deb",
    "syslog-counter": "@syslog-counter//:syslog-counter_1.0.0.deb",
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
# What remains is the FIPS stack: symcrypt-openssl first, then OpenSSL, CPython,
# OpenSSH and krb5 rebuilt against it.
# sonic-device-data is built with sonic_deb's `data =` shortcut (its payload is
# a ~20k-file tree packed directly), so it has no `_data` sibling — the tar IS
# the data tar. Listed separately from HERMETIC_HOST_DEBS, whose entries follow
# the <name>_data / <name>_statusd convention.
HERMETIC_HOST_DEB_DATA_TARS = {
    "sonic-device-data": (
        "//src/sonic-device-data:device_tar",
        "//src/sonic-device-data:sonic-device-data_1.0-1_all.deb_statusd",
    ),
}

TODO_HERMETIC = [
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
