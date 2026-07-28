"""Per-container variables for files/build_templates/docker_image_ctl.j2.

slave.mk exports docker_container_name / docker_image_name / docker_image_run_opt
once per container before running `j2` over the template (slave.mk:1808-1842).
docker_image_run_opt is the accumulated $(<DOCKER>)_RUN_OPT from each
rules/docker-*.mk plus the image-type additions.

Values were recovered from the rendered scripts in Make's own image, so the
output is diffable against it rather than reconstructed by hand.

25 of the 27 render byte-identical to Make's. dhcp_relay.sh and macsec.sh differ
in two ways that both indicate Make's copies are stale rather than a variable
being wrong: they are missing the `--tmpfs /tmp` / `--tmpfs /var/tmp` lines that
mount_default_tmpfs=y produces (slave.mk:1811 sets it unconditionally for every
container, and no rules/*.mk overrides it), and they are the only two files in
the set with no trailing newline. Rendering them the same way as the other 25 is
the correct behaviour.
"""

# script name -> (container name, image name, run options)
CONTAINER_CTL = {
    "bgp": (
        'bgp',
        'docker-fpm-frr',
        '-t --cap-add=NET_ADMIN --cap-add=SYS_ADMIN -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro',
    ),
    "bmp": (
        'bmp',
        'docker-sonic-bmp',
        '-t -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro -v /var/run/dbus:/var/run/dbus:rw',
    ),
    "bmp_watchdog": (
        'bmp_watchdog',
        'docker-bmp-watchdog',
        '-t --privileged --pid=host -v /lib/systemd/system:/lib/systemd/system:rw -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro',
    ),
    "dash-ha": (
        'dash-ha',
        'docker-dash-ha',
        '-t -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro',
    ),
    "dash_engine": (
        'dash_engine',
        'docker-dash-engine',
        '--privileged -t',
    ),
    "database": (
        'database',
        'docker-database',
        '-t --security-opt apparmor=unconfined --security-opt=systempaths=unconfined -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro',
    ),
    "dhcp_relay": (
        'dhcp_relay',
        'docker-dhcp-relay',
        '-t -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro --tmpfs /tmp/ --tmpfs /var/tmp/',
    ),
    "eventd": (
        'eventd',
        'docker-eventd',
        '-t -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro',
    ),
    "gbsyncd": (
        'gbsyncd',
        'docker-gbsyncd-vs',
        '--privileged -t -v /host/machine.conf:/etc/machine.conf -v /etc/sonic:/etc/sonic:ro',
    ),
    "gnmi-sidecar": (
        'gnmi-sidecar',
        'docker-gnmi-sidecar',
        '-t --pid=host --cap-add=SYS_ADMIN --cap-add=SYS_PTRACE --cap-add=DAC_OVERRIDE --security-opt apparmor=unconfined --security-opt seccomp=unconfined -v /lib/systemd/system:/lib/systemd/system:rw -v /etc/audit:/etc/audit:rw -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro',
    ),
    "gnmi": (
        'gnmi',
        'docker-sonic-gnmi',
        '-t -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro -v /var/run/dbus:/var/run/dbus:rw -v /:/mnt/host:ro -v /tmp:/mnt/host/tmp:rw -v /var/tmp:/mnt/host/var/tmp:rw --pid=host --cap-add=SYS_ADMIN --cap-add=SYS_BOOT --cap-add=SYS_PTRACE --cap-add=NET_ADMIN --cap-add=DAC_OVERRIDE --security-opt apparmor=unconfined --security-opt seccomp=unconfined --userns=host -v /var/run/gnmi:/var/run/gnmi:rw',
    ),
    "gnmi_watchdog": (
        'gnmi_watchdog',
        'docker-gnmi-watchdog',
        '-t --pid=host -v /lib/systemd/system:/lib/systemd/system:rw -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro',
    ),
    "lldp": (
        'lldp',
        'docker-lldp',
        '-t --cap-add=NET_ADMIN -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro',
    ),
    "macsec": (
        'macsec',
        'docker-macsec',
        '-t -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro',
    ),
    "mgmt-framework": (
        'mgmt-framework',
        'docker-sonic-mgmt-framework',
        '-t -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro  -v /etc:/host_etc:ro -v /var/run/dbus:/var/run/dbus:rw --mount type=bind,source=/var/platform/,target=/mnt/platform/',
    ),
    "mux": (
        'mux',
        'docker-mux',
        '-t -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro ',
    ),
    "nat": (
        'nat',
        'docker-nat',
        '-t --cap-add=NET_ADMIN -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro ',
    ),
    "otel": (
        'otel',
        'docker-sonic-otel',
        '-t -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro -v /:/mnt/host:ro -v /tmp:/mnt/host/tmp:rw -v /var/tmp:/mnt/host/var/tmp:rw --pid=host --userns=host',
    ),
    "pmon": (
        'pmon',
        'docker-platform-monitor',
        '--cap-add=SYS_RAWIO --cap-add=SYS_ADMIN -t --security-opt apparmor=unconfined --security-opt=systempaths=unconfined -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro  -v /host/reboot-cause:/host/reboot-cause:rw -v /host/pmon/stormond:/usr/share/stormond:rw -v /var/run/platform_cache:/var/run/platform_cache:ro -v /usr/share/sonic/device/pddf:/usr/share/sonic/device/pddf:ro -v /var/lock/pddf-locks:/var/lock/pddf-locks:rw -v /sys/:/sys/:rw',
    ),
    "radv": (
        'radv',
        'docker-router-advertiser',
        '-t -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro',
    ),
    "restapi-sidecar": (
        'restapi-sidecar',
        'docker-restapi-sidecar',
        '-t --privileged --pid=host -v /lib/systemd/system:/lib/systemd/system:rw -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro',
    ),
    "sflow": (
        'sflow',
        'docker-sflow',
        '-t --cap-add=NET_ADMIN --cap-add=SYS_ADMIN -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro ',
    ),
    "snmp": (
        'snmp',
        'docker-snmp',
        '-t -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro',
    ),
    "swss": (
        'swss',
        'docker-orchagent',
        '-t --cap-add=NET_ADMIN --security-opt apparmor=unconfined --security-opt=systempaths=unconfined -v /etc/network/interfaces:/etc/network/interfaces:ro -v /etc/localtime:/etc/localtime:ro  -v /etc/network/interfaces.d/:/etc/network/interfaces.d/:ro -v /host/machine.conf:/host/machine.conf:ro -v /etc/sonic:/etc/sonic:ro -v /var/log/swss:/var/log/swss:rw -v /zmq_swss:/zmq_swss:rw',
    ),
    "syncd": (
        'syncd',
        'docker-syncd-vs',
        '--privileged -t -v /host/machine.conf:/etc/machine.conf -v /etc/sonic:/etc/sonic:ro',
    ),
    "sysmgr": (
        'sysmgr',
        'docker-sysmgr',
        '-v /var/run/dbus:/var/run/dbus:rw   -v /etc/sonic:/etc/sonic:ro  ',
    ),
    "teamd": (
        'teamd',
        'docker-teamd',
        '-t --cap-add=NET_ADMIN -v /etc/sonic:/etc/sonic:ro -v /etc/localtime:/etc/localtime:ro ',
    ),
}

# slave.mk:1726 — CONFIGURED_PLATFORM with the arch suffix stripped.
SONIC_ASIC_PLATFORM = "vs"

# Image-wide variables the template's {% if %} branches read. Values are the
# rules/config defaults for this image: INSTALL_DEBUG_TOOLS is commented out (so
# empty), ENABLE_ASAN defaults to n, and slave.mk:1811 hardcodes
# mount_default_tmpfs=y for every container.
COMMON_CTL_VARS = {
    "install_debug_image": "",
    "enable_asan": "n",
    "mount_default_tmpfs": "y",
}

