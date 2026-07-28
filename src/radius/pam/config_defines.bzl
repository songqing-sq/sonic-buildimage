"""Autoconf substitutions for pam_radius and FreeRADIUS 1.1.8 on x86_64 trixie.

Stands in for the ./configure runs the upstream Makefiles perform, which probe
the host compiler and libc. Applied to each project's own <header>.in template
by the genrules in BUILD.bazel.

Macros absent from a table stay #undef, matching autoconf.
"""

# pam_radius/src/config.h.in
PAM_RADIUS_DEFINES = {
    "AC_LITTLE_ENDIAN": "1",
    "HAVE_CTYPE_H": "1",
    "HAVE_ERRNO_H": "1",
    "HAVE_FCNTL_H": "1",
    "HAVE_INET_ATON": "1",
    "HAVE_INET_NTOP": "1",
    "HAVE_INET_PTON": "1",
    "HAVE_INTTYPES_H": "1",
    "HAVE_LIBNSL": "1",
    "HAVE_LIBRESOLV": "1",
    "HAVE_LIMITS_H": "1",
    "HAVE_LINUX_IF_H": "1",
    "HAVE_MALLOC_H": "1",
    "HAVE_NETDB_H": "1",
    "HAVE_NETINET_IN_H": "1",
    "HAVE_NET_IF_H": "1",
    "HAVE_POLL_H": "1",
    "HAVE_SECURITY_PAM_APPL_H": "1",
    "HAVE_SECURITY_PAM_MODULES_H": "1",
    "HAVE_SETSOCKOPT": "1",
    "HAVE_SNPRINTF": "1",
    "HAVE_STDARG_H": "1",
    "HAVE_STDINT_H": "1",
    "HAVE_STDIO_H": "1",
    "HAVE_STDLIB_H": "1",
    "HAVE_STRINGS_H": "1",
    "HAVE_STRING_H": "1",
    "HAVE_STRLCAT": "1",
    "HAVE_STRLCPY": "1",
    "HAVE_STRUCT_IN6_ADDR": "1",
    "HAVE_SYSLOG_H": "1",
    "HAVE_SYS_PARAM_H": "1",
    "HAVE_SYS_RESOURCE_H": "1",
    "HAVE_SYS_SOCKET_H": "1",
    "HAVE_SYS_STAT_H": "1",
    "HAVE_SYS_TIME_H": "1",
    "HAVE_SYS_TYPES_H": "1",
    "HAVE_TIME_H": "1",
    "HAVE_UNISTD_H": "1",
    "HAVE_UTMP_H": "1",
    "HAVE_WCHAR_H": "1",
    "PACKAGE_BUGREPORT": "\"http://bugs.freeradius.org\"",
    "PACKAGE_NAME": "\"pam_radius\"",
    "PACKAGE_STRING": "\"pam_radius 1.5\"",
    "PACKAGE_TARNAME": "\"pam_radius\"",
    "PACKAGE_URL": "\"http://www.freeradius.org\"",
    "PACKAGE_VERSION": "\"1.5\"",
    "PAM_RADIUS_VERSION": "010401",
    "PAM_RADIUS_VERSION_STRING": "\"1.4.1\"",
    "STDC_HEADERS": "1",
}

# freeradius-server/src/include/autoconf.h.in
FREERADIUS_DEFINES = {
    "HAVE_SYS_WAIT_H": "1",
    "RETSIGTYPE": "void",
    "STDC_HEADERS": "1",
    "TIME_WITH_SYS_TIME": "1",
    "GETHOSTBYADDRRSTYLE": "GNUSTYLE",
    "GETHOSTBYNAMERSTYLE": "GNUSTYLE",
    "CTIMERSTYLE": "POSIXSTYLE",
    "HAVE_CRYPT": "1",
    "ASCEND_BINARY": "1",
    "WITH_SNMP": "1",
    "HAVE_UCD_SNMP_ASN1_SNMP_SNMPIMPL_H": "1",
    "HAVE_LIBSNMP": "1",
    "HAVE_REGEX_H": "1",
    "HAVE_REG_EXTENDED": "1",
    "ut_xtime": "ut_tv.tv_sec",
    "HAVE_IP_PKTINFO": "1",
    "HAVE_CLOSEFROM": "1",
    "HAVE_CTIME_R": "1",
    "HAVE_GETHOSTNAME": "1",
    "HAVE_GETOPT_LONG": "1",
    "HAVE_GETUSERSHELL": "1",
    "HAVE_GMTIME_R": "1",
    "HAVE_INET_ATON": "1",
    "HAVE_INET_NTOP": "1",
    "HAVE_INET_PTON": "1",
    "HAVE_INITGROUPS": "1",
    "HAVE_LOCALTIME_R": "1",
    "HAVE_LOCKF": "1",
    "HAVE_PTHREAD_SIGMASK": "1",
    "HAVE_SETLINEBUF": "1",
    "HAVE_SETSID": "1",
    "HAVE_SETVBUF": "1",
    "HAVE_SIGACTION": "1",
    "HAVE_SIGPROCMASK": "1",
    "HAVE_SNPRINTF": "1",
    "HAVE_STRCASECMP": "1",
    "HAVE_STRNCASECMP": "1",
    "HAVE_STRSEP": "1",
    "HAVE_STRSIGNAL": "1",
    "HAVE_VSNPRINTF": "1",
    "HAVE_ARPA_INET_H": "1",
    "HAVE_CRYPT_H": "1",
    "HAVE_DIRENT_H": "1",
    "HAVE_DLFCN_H": "1",
    "HAVE_ERRNO_H": "1",
    "HAVE_FCNTL_H": "1",
    "HAVE_GETOPT_H": "1",
    "HAVE_INTTYPES_H": "1",
    "HAVE_MALLOC_H": "1",
    "HAVE_NETDB_H": "1",
    "HAVE_NETINET_IN_H": "1",
    "HAVE_OPENSSL_CRYPTO_H": "1",
    "HAVE_OPENSSL_ENGINE_H": "1",
    "HAVE_OPENSSL_ERR_H": "1",
    "HAVE_OPENSSL_SSL_H": "1",
    "HAVE_PTHREAD_H": "1",
    "HAVE_SEMAPHORE_H": "1",
    "HAVE_SIGNAL_H": "1",
    "HAVE_STDINT_H": "1",
    "HAVE_STDIO_H": "1",
    "HAVE_SYS_FCNTL_H": "1",
    "HAVE_SYS_PRCTL_H": "1",
    "HAVE_SYS_SELECT_H": "1",
    "HAVE_SYS_SOCKET_H": "1",
    "HAVE_SYS_STAT_H": "1",
    "HAVE_SYS_TIME_H": "1",
    "HAVE_SYS_TYPES_H": "1",
    "HAVE_SYSLOG_H": "1",
    "HAVE_UNISTD_H": "1",
    "HAVE_UTMP_H": "1",
    "HAVE_UTMPX_H": "1",
    "HAVE_LIBNSL": "1",
    "HAVE_LIBRESOLV": "1",
    "HAVE_LIBCRYPTO": "1",
    "HAVE_LIBSSL": "1",
}

# src/include/radpaths.h, normally written by the `build-radpaths-h` script
# ./configure runs (the script itself is not in this git snapshot). Only
# RADDBDIR is actually referenced by the code compiled here
# (libeap/eapsimlib.c), and the deb ships no raddb, so upstream's default
# /usr/local prefix is kept verbatim rather than invented.
RADPATHS = {
    "LOGDIR": "/usr/local/var/log/radius",
    "LIBDIR": "/usr/local/lib",
    "RADDBDIR": "/usr/local/etc/raddb",
    "RUNDIR": "/usr/local/var/run",
    "SBINDIR": "/usr/local/sbin",
    "RADIR": "/usr/local/var/log/radius/radacct",
}

def config_h_cmd(defines):
    """genrule cmd: fill a <header>.in template from a substitution table.

    Enabled macros become `#define NAME VALUE`; every other `#undef NAME` is
    commented out, the way autoconf does.
    """
    return "sed " + " ".join([
        "-e 's|^#undef {name}$$|#define {name} {value}|'".format(
            name = name,
            value = value,
        )
        for name, value in defines.items()
    ] + [
        "-e 's|^#undef \\(.*\\)$$|/* #undef \\1 */|'",
    ]) + " $< > $@"
