"""config.h for rasdaemon 0.6.8 on x86_64 Debian trixie (glibc).

The git snapshot ships no config.h.in — Debian runs `dh --with autoreconf`, so
autoconf generates both the template and the header. Rather than invoke
autoreconf (a host autotools run this build avoids), the resulting macro set is
recorded here and written out by a genrule.

Feature macros correspond to debian/rules' configure flags:
    --enable-mce --enable-aer --enable-sqlite3 --enable-extlog
    --enable-abrt-report --with-sysconfdefdir=/etc/default
"""

# Plain integer macros.
CONFIG_DEFINES = {
    "HAVE_ABRT_REPORT": "1",
    "HAVE_AER": "1",
    "HAVE_DLFCN_H": "1",
    "HAVE_EXTLOG": "1",
    "HAVE_INTTYPES_H": "1",
    "HAVE_MCE": "1",
    "HAVE_SQLITE3": "1",
    "HAVE_STDINT_H": "1",
    "HAVE_STDIO_H": "1",
    "HAVE_STDLIB_H": "1",
    "HAVE_STRINGS_H": "1",
    "HAVE_STRING_H": "1",
    "HAVE_SYS_STAT_H": "1",
    "HAVE_SYS_TYPES_H": "1",
    "HAVE_UNISTD_H": "1",
    "STDC_HEADERS": "1",
}

# String macros. The genrule adds the surrounding double quotes.
CONFIG_STRING_DEFINES = {
    "LT_OBJDIR": ".libs/",
    "PACKAGE": "rasdaemon",
    "PACKAGE_BUGREPORT": "",
    "PACKAGE_NAME": "RASdaemon",
    "PACKAGE_STRING": "RASdaemon 0.6.8",
    "PACKAGE_TARNAME": "rasdaemon",
    "PACKAGE_URL": "",
    "PACKAGE_VERSION": "0.6.8",
    "RASSTATEDIR": "/var/lib/rasdaemon",
    "RAS_DB_FNAME": "ras-mc_event.db",
    "VERSION": "0.6.8",
}

# automake conditional prefixes substituted into util/ras-mc-ctl.in: empty when
# the feature is enabled, "#" when disabled (which comments the line out).
# Matches debian/rules' flag set, and verified against Make's ras-mc-ctl.
RAS_MC_CTL_SUBST = {
    "WITH_AER_TRUE": "",
    "WITH_ARM_TRUE": "#",
    "WITH_DEVLINK_TRUE": "#",
    "WITH_DISKERROR_TRUE": "#",
    "WITH_EXTLOG_TRUE": "",
    "WITH_MCE_TRUE": "",
    "WITH_MEMORY_FAILURE_TRUE": "#",
    "RASSTATEDIR": "/var/lib/rasdaemon",
    "RAS_DB_FNAME": "ras-mc_event.db",
    "prefix": "/usr",
    "sysconfdir": "/etc",
}

# configure substitutions for misc/*.service.in. Verified against the units in
# Make's deb (ExecStart=/usr/sbin/..., EnvironmentFile=/etc/default/rasdaemon).
SERVICE_SUBST = {
    "sbindir": "/usr/sbin",
    "SYSCONFDEFDIR": "/etc/default",
}

def config_h_cmd(defines, string_defines):
    """genrule cmd: write config.h from the substitution tables."""
    echos = [
        "echo '#define {name} {value}';".format(name = name, value = value)
        for name, value in defines.items()
    ] + [
        "echo '#define {name} \"{value}\"';".format(name = name, value = value)
        for name, value in string_defines.items()
    ]
    return ("{ echo '#ifndef RASDAEMON_CONFIG_H'; " +
            "echo '#define RASDAEMON_CONFIG_H'; " +
            " ".join(echos) +
            " echo '#endif'; } > $@")
