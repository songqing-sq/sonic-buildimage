"""Source exposure for the monit 5.34.3 tarball.

Only file groups and the header cc_libraries live here — `includes` paths are
resolved relative to the package that declares them, so they have to be in this
repo rather than the monit module.

Compilation happens in the monit module, which supplies the generated config.h
and the regenerated parser (SONiC's patch edits src/p.y, so the tarball's
pre-generated src/y.tab.c is stale).
"""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "hdrs_lib",
    hdrs = glob(
        [
            "src/**/*.h",
            "libmonit/src/**/*.h",
        ],
        allow_empty = False,
    ),
    # Both trees include headers unqualified across subdirectories
    # (libmonit/src/Config.h -> "AssertException.h", monit's src/*.c ->
    # "protocol.h"), so every directory holding a header goes on the path.
    includes = [
        "libmonit/src",
        "libmonit/src/exceptions",
        "libmonit/src/io",
        "libmonit/src/system",
        "libmonit/src/thread",
        "libmonit/src/util",
        "src",
        "src/device",
        "src/http",
        "src/net",
        "src/notification",
        "src/process",
        "src/protocols",
        "src/ssl",
        "src/statistics",
        "src/terminal",
    ],
)

# src/net/Link.c textually #includes "os/linux/Link.inc" (selected by the
# platform), so it must be an input without being its own translation unit.
cc_library(
    name = "textual_includes",
    textual_hdrs = ["src/net/os/linux/Link.inc"],
    includes = ["src/net"],
)

# Makefile.am monit_SOURCES, minus the two generated parser files and with
# sysdep_@ARCH@ resolved to LINUX.
filegroup(
    name = "monit_srcs",
    srcs = [
        "src/alert.c",
        "src/checksum.c",
        "src/control.c",
        "src/daemonize.c",
        "src/device/device_common.c",
        "src/device/sysdep_LINUX.c",
        "src/env.c",
        "src/event.c",
        "src/file.c",
        "src/gc.c",
        "src/http.c",
        "src/http/base64.c",
        "src/http/cervlet.c",
        "src/http/client.c",
        "src/http/engine.c",
        "src/http/processor.c",
        "src/http/xml.c",
        "src/log.c",
        "src/md5.c",
        "src/md5_crypt.c",
        "src/monit.c",
        "src/net/Link.c",
        "src/net/net.c",
        "src/net/socket.c",
        "src/notification/Address.c",
        "src/notification/MMonit.c",
        "src/notification/SMTP.c",
        "src/process/ProcessTree.c",
        "src/process/SystemInfo.c",
        "src/process/sysdep_LINUX.c",
        "src/protocols/apache_status.c",
        "src/protocols/clamav.c",
        "src/protocols/default.c",
        "src/protocols/dns.c",
        "src/protocols/dwp.c",
        "src/protocols/fail2ban.c",
        "src/protocols/ftp.c",
        "src/protocols/generic.c",
        "src/protocols/gps.c",
        "src/protocols/http.c",
        "src/protocols/imap.c",
        "src/protocols/ldap2.c",
        "src/protocols/ldap3.c",
        "src/protocols/lmtp.c",
        "src/protocols/memcache.c",
        "src/protocols/mongodb.c",
        "src/protocols/mqtt.c",
        "src/protocols/mysql.c",
        "src/protocols/nntp.c",
        "src/protocols/ntp3.c",
        "src/protocols/pgsql.c",
        "src/protocols/pop.c",
        "src/protocols/postfix_policy.c",
        "src/protocols/protocol.c",
        "src/protocols/radius.c",
        "src/protocols/rdate.c",
        "src/protocols/redis.c",
        "src/protocols/rsync.c",
        "src/protocols/sieve.c",
        "src/protocols/sip.c",
        "src/protocols/smtp.c",
        "src/protocols/spamassassin.c",
        "src/protocols/ssh.c",
        "src/protocols/tns.c",
        "src/protocols/websocket.c",
        "src/sha1.c",
        "src/signal.c",
        "src/spawn.c",
        "src/ssl/Ssl.c",
        "src/state.c",
        "src/statistics/Statistics.c",
        "src/terminal/TextBox.c",
        "src/terminal/TextColor.c",
        "src/util.c",
        "src/validate.c",
    ],
)

# libmonit/Makefile.am libmonit_la_SOURCES.
filegroup(
    name = "libmonit_srcs",
    srcs = [
        "libmonit/src/Bootstrap.c",
        "libmonit/src/exceptions/Exception.c",
        "libmonit/src/exceptions/assert.c",
        "libmonit/src/io/Dir.c",
        "libmonit/src/io/File.c",
        "libmonit/src/io/InputStream.c",
        "libmonit/src/io/OutputStream.c",
        "libmonit/src/system/Command.c",
        "libmonit/src/system/Mem.c",
        "libmonit/src/system/Net.c",
        "libmonit/src/system/Random.c",
        "libmonit/src/system/System.c",
        "libmonit/src/system/Time.c",
        "libmonit/src/thread/Thread.c",
        "libmonit/src/util/Array.c",
        "libmonit/src/util/Fmt.c",
        "libmonit/src/util/List.c",
        "libmonit/src/util/Str.c",
        "libmonit/src/util/StringBuffer.c",
    ],
)

exports_files([
    "monitrc",
    "libmonit/src/xconfig.h.in",
    "src/config.h.in",
    "src/l.l",
    "src/lex.yy.c",
    "src/p.y",
    "system/bash/monit",
])

# The packaging files debian/monit.install ships, from the debian tarball that
# debian_source overlays on top of the orig tree.
filegroup(
    name = "conf_available",
    srcs = glob(
        ["debian/conf-available/*"],
        allow_empty = False,
    ),
)

filegroup(
    name = "conf_templates",
    srcs = glob(
        ["debian/templates/*"],
        allow_empty = False,
    ),
)

exports_files([
    "debian/monit.default",
    "debian/monit.init",
    "debian/monit.logrotate",
    "debian/monit.pam",
    "debian/monit.service",
    "debian/monit.bug-script",
    "debian/monit.lintian-overrides",
])
