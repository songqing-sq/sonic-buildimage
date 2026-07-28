"""Hermetic sources for the SONiC-built host packages the vs image installs.

Ground truth for WHICH packages the host fs needs is the Make build's
fsroot-vs/var/lib/dpkg/status (57 SONiC-built debs). This file records where
each one comes from in the BAZEL build — never from target/debs, which is a
Make artifact; every entry below is a hermetic Bazel target.

HERMETIC_HOST_DEBS maps package -> the sonic_deb base target name. The macro
generates `<name>_data` (the deb's data tar, laid into the rootfs) and
`<name>_statusd` (registers the package in /var/lib/dpkg/status.d).

FIPS_HOST_DEBS is the same shape but for the INCLUDE_FIPS family, which upstream
publishes prebuilt rather than as source.

Packages not yet migrated are listed in TODO_HERMETIC so the gap is visible
rather than silently bridged from Make output.
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
    # SONiC's libnl3 carries a version suffix of its own (`+b1sonic1`): the
    # RTA_NH_ID / nexthop-group patches are not in trixie's 3.7.0-0.2, so the
    # stock package is NOT equivalent.
    "libnl-3-200": "@libnl3//:libnl-3-200_3.7.0-0.2+b1sonic1.deb",
    "libnl-cli-3-200": "@libnl3//:libnl-cli-3-200_3.7.0-0.2+b1sonic1.deb",
    "libnl-genl-3-200": "@libnl3//:libnl-genl-3-200_3.7.0-0.2+b1sonic1.deb",
    "libnl-nf-3-200": "@libnl3//:libnl-nf-3-200_3.7.0-0.2+b1sonic1.deb",
    "libnl-route-3-200": "@libnl3//:libnl-route-3-200_3.7.0-0.2+b1sonic1.deb",
    # Built from source: trixie's 2.0.0-1 is the standalone pam_radius without
    # the FreeRADIUS bundle, so it lacks the RADIUS MPL / CHAP / PEAP-MSCHAPv2
    # support SONiC's 1.4.1-1 fork carries.
    "libpam-radius-auth": "@libpam-radius-auth//:libpam-radius-auth_1.4.1-1.deb",
    # Built from source: 0002-change_monit_alert_log_error.patch extends the
    # grammar with `alert ... repeat`, which SONiC's monit configs use. Verified
    # that stock trixie monit rejects that syntax outright.
    "monit": "@monit//:monit_5.34.3-1.deb",
    # Built from source: 0001-Check-CPUs-online-not-configured.patch switches
    # ras-events.c to _SC_NPROCESSORS_ONLN, without which the daemon fails to
    # start when any CPU is offline. Not upstream as of 0.6.8-1.
    "rasdaemon": "@rasdaemon//:rasdaemon_0.6.8-1.deb",
}

# The FIPS stack (INCLUDE_FIPS=y, the Makefile.work default): OpenSSL, CPython,
# OpenSSH and krb5 rebuilt against Microsoft's SymCrypt provider. Upstream
# publishes them prebuilt on packages.trafficmanager.net; src/sonic-fips fetches
# each via a sha256-pinned http_file, exactly as Make's src/sonic-fips/Makefile
# curls them, so these are as hermetic as the source they come from. Their
# `+fips` versions mean the stock @trixie packages are NOT interchangeable.
FIPS_HOST_DEBS = {
    "libssl3t64": "@sonic-fips//:libssl3t64_3.5.4-1+fips.deb",
    "libssl-dev": "@sonic-fips//:libssl-dev_3.5.4-1+fips.deb",
    "openssl": "@sonic-fips//:openssl_3.5.4-1+fips.deb",
    "symcrypt-openssl": "@sonic-fips//:symcrypt-openssl_1.9.4.deb",
    "libpython3.13-minimal": "@sonic-fips//:libpython3.13-minimal_3.13.5-2+fips.deb",
    "libpython3.13-stdlib": "@sonic-fips//:libpython3.13-stdlib_3.13.5-2+fips.deb",
    "libpython3.13": "@sonic-fips//:libpython3.13_3.13.5-2+fips.deb",
    "python3.13-minimal": "@sonic-fips//:python3.13-minimal_3.13.5-2+fips.deb",
    "python3.13": "@sonic-fips//:python3.13_3.13.5-2+fips.deb",
    "openssh-client": "@sonic-fips//:openssh-client_10.0p1-7+fips.deb",
    "openssh-server": "@sonic-fips//:openssh-server_10.0p1-7+fips.deb",
    "openssh-sftp-server": "@sonic-fips//:openssh-sftp-server_10.0p1-7+fips.deb",
    "ssh": "@sonic-fips//:ssh_10.0p1-7+fips_all.deb",
    "libk5crypto3": "@sonic-fips//:libk5crypto3_1.21.3-5+fips.deb",
    "libkrb5support0": "@sonic-fips//:libkrb5support0_1.21.3-5+fips.deb",
    "libkrb5-3": "@sonic-fips//:libkrb5-3_1.21.3-5+fips.deb",
    "libgssapi-krb5-2": "@sonic-fips//:libgssapi-krb5-2_1.21.3-5+fips.deb",
}

# sonic-device-data is built with sonic_deb's `data =` shortcut (its payload is
# a ~20k-file tree packed directly), so it has no `_data` sibling — the tar IS
# the data tar. Listed separately from HERMETIC_HOST_DEBS, whose entries follow
# the <name>_data / <name>_statusd convention.
HERMETIC_HOST_DEB_DATA_TARS = {
    # Built from source for its plugin-support patch: bash-tacplus is dlopen'd
    # through the hook that patch adds (and needs bash linked -rdynamic), so
    # trixie's stock bash is not a substitute. Uses sonic_deb's `data =`
    # shortcut because the locale tree is generated, hence no `_data` sibling.
    "bash": (
        "@bash//:bash_data",
        "@bash//:bash_5.2.37-2.deb_statusd",
    ),
    "sonic-device-data": (
        "//src/sonic-device-data:device_tar",
        "//src/sonic-device-data:sonic-device-data_1.0-1_all.deb_statusd",
    ),
}

TODO_HERMETIC = [
    # SONiC builds these from source with its own patches, so the stock trixie
    # package is not a substitute:
    #   ifupdown2         5 patches incl. python 3.12 compatibility
    #   kdump-tools       kdump core prefix, initrd generated at build time
    #   grub-common       cpio ustar large-uid handling
    #   grub2-common      (same source package as grub-common)
    #   makedumpfile      plain Debian rebuild, but pinned to 1.7.7-1 which
    #                     trixie does not carry
    #   sedutil           1.15-5ad84d8, a git snapshot with no Debian release
    "makedumpfile",
    "kdump-tools",
    "ifupdown2",
    "grub-common",
    "grub2-common",
    "sedutil",
]
