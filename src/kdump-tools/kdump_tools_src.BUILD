"""Source exposure for the kdump-tools 1.10.7 native package.

Everything shipped is a shell script or a config file; nothing is compiled.
"""

package(default_visibility = ["//visibility:public"])

exports_files([
    "debian/initramfs.hook",
    "debian/initramfs.local-bottom",
    "debian/kdump-config.in",
    "debian/kdump-tools.conf.in",
    "debian/kdump-tools.grub.default",
    "debian/kdump-tools.init",
    "debian/kdump-tools.kdump-tools-dump.service",
    "debian/kdump-tools.service",
    "debian/kdump-tools.udev",
    "debian/kdump_mem_estimator",
    "debian/kernel-postinst-generate-initrd",
    "debian/kernel-postrm-delete-initrd",
    "debian/sysctl.conf",
])
