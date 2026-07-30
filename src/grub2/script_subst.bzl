"""Autoconf substitutions for the GRUB shell scripts grub-common / grub2-common ship.

grub-mkconfig, grub-kbdcomp, grub-set-default, grub-reboot, grub-mkconfig_lib and
the etc/grub.d/* snippets are all `.in` templates; ./configure fills these in.

Every value below was read back out of Make's own grub-common /
grub2-common debs (e.g. `prefix=/usr`, `grubdir=/boot/grub`,
`TEXTDOMAINDIR=${datarootdir}/locale`), so the generated scripts match rather
than being guessed from the Debian defaults.
"""

# Deliberately keeps the ${...} forms the shipped scripts use — Make's copies
# read e.g. `bindir=${exec_prefix}/bin`, not a flattened /usr/bin.
SCRIPT_SUBST = {
    "prefix": "/usr",
    "exec_prefix": "/usr",
    "bindir": "${exec_prefix}/bin",
    "sbindir": "${exec_prefix}/sbin",
    "datarootdir": "/usr/share",
    "datadir": "${datarootdir}",
    "sysconfdir": "/etc",
    "localedir": "${datarootdir}/locale",
    "host_os": "linux-gnu",
    "bootdirname": "boot",
    "grubdirname": "grub",
    "PACKAGE": "grub",
    "PACKAGE_NAME": "GRUB",
    "PACKAGE_VERSION": "2.06-13+deb13u1",
    # Bare program names: the templates already supply the directory, e.g.
    # grub-mkconfig.in has `grub_probe="${sbindir}/@grub_probe@"`.
    "grub_probe": "grub-probe",
    "grub_file": "grub-file",
    "grub_editenv": "grub-editenv",
    "grub_mklayout": "grub-mklayout",
    "grub_mkrelpath": "grub-mkrelpath",
    "grub_script_check": "grub-script-check",
    # Only referenced by the bash-completion template, which likewise supplies
    # the directory itself.
    "grub_bios_setup": "grub-bios-setup",
    "grub_install": "grub-install",
    "grub_mkconfig": "grub-mkconfig",
    "grub_mkfont": "grub-mkfont",
    "grub_mkimage": "grub-mkimage",
    "grub_mkrescue": "grub-mkrescue",
    "grub_reboot": "grub-reboot",
    "grub_set_default": "grub-set-default",
    "grub_sparc64_setup": "grub-sparc64-setup",
    "grub_mkpasswd_pbkdf2": "grub-mkpasswd-pbkdf2",
    # Debian feature toggles patched into the grub.d snippets
    # (mkconfig-ubuntu-recovery.patch, quick-boot.patch, vt-handoff.patch, ...).
    # All 0 for Debian; Ubuntu flips several on.
    "QUICK_BOOT": "0",
    "QUIET_BOOT": "0",
    "GFXPAYLOAD_DYNAMIC": "0",
    "VT_HANDOFF": "0",
    "UBUNTU_RECOVERY": "0",
    # debian/default/grub's two knobs.
    "DEFAULT_TIMEOUT": "5",
    "DEFAULT_CMDLINE": "quiet",
}

def script_subst_cmd():
    """genrule cmd fragment: sed expressions filling in every @NAME@."""
    return "sed " + " ".join([
        # `$` is doubled: genrule treats a bare ${...} as a Make variable, and
        # these values must reach the output file literally.
        "-e 's|@{name}@|{value}|g'".format(
            name = name,
            value = value.replace("$", "$$"),
        )
        for name, value in SCRIPT_SUBST.items()
    ])
