/* Hand-written replacement for autoheader-generated config.h.
 * Mirrors what `./configure --user=root --group=root --enable-dbus --enable-zmq`
 * would produce on Debian trixie with libnl 3.7.0. Consumed by expand_template
 * (no @VAR@ placeholders remain).
 *
 * NOTE: ZeroMQ is default-enabled upstream (configure.ac: --disable-zmq
 * [default=enabled]); the SONiC Make build has libzmq3-dev in its sysroot so
 * ENABLE_ZMQ is defined and both libteamdctl.so and teamd link libzmq.so.5.
 * cli_zmq.c and teamd_zmq.c are guarded by #ifdef ENABLE_ZMQ. */

#define PACKAGE "libteam"
#define PACKAGE_NAME "libteam"
#define PACKAGE_TARNAME "libteam"
#define PACKAGE_VERSION "1.31"
#define PACKAGE_STRING "libteam 1.31"
#define PACKAGE_BUGREPORT "jiri@resnulli.us"
#define PACKAGE_URL ""
#define VERSION "1.31"

/* System logging via syslog(). */
#define ENABLE_LOGGING 1

/* D-Bus API (libteamdctl cli_dbus.c + teamd_dbus.c). */
#define ENABLE_DBUS 1

/* ZeroMQ API (libteamdctl cli_zmq.c + teamd teamd_zmq.c). Default-enabled
 * upstream; the SONiC Make build links libzmq.so.5, so we match it. */
#define ENABLE_ZMQ 1

/* Default daemon user/group. */
#define TEAMD_USER "root"
#define TEAMD_GROUP "root"

/* libnl 3.7.0 provides all three of these in libnl-route-3. */
#define HAVE_RTNL_LINK_GET_PHYS_ID 1
#define HAVE_RTNL_LINK_SET_CARRIER 1
#define HAVE_RTNL_LINK_GET_CARRIER 1

#define HAVE_STDINT_H 1
#define HAVE_STDLIB_H 1
#define STDC_HEADERS 1
