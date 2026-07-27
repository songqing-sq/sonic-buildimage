# The docker image set baked into the Bazel sonic-vs.bin /var/lib/docker store.
#
# Derived from the Make ground truth: the repositories.json inside
# target/sonic-vs.bin's dockerfs.tar.gz lists exactly these 27 images
# (= SONIC_INSTALL_DOCKER_IMAGES for the vs platform with rules/config
# defaults: frr routing stack, macsec/sflow/snmp/nat/mux/otel/mgmt-framework/
# bmp/gnmi + watchdog/sidecar images, dash-engine/dash-ha, sysmgr).
#
# Make tags every image twice (:latest + :<build_version>); the runtime
# container-start machinery (docker_image_ctl.j2) resolves :latest, so the
# Bazel store ships :latest.
VS_DOCKERS = {
    "//dockers/docker-bmp-watchdog:docker-bmp-watchdog": "docker-bmp-watchdog:latest",
    "//dockers/docker-dash-ha:docker-dash-ha": "docker-dash-ha:latest",
    "//dockers/docker-database:docker-database": "docker-database:latest",
    "//dockers/docker-dhcp-relay:docker-dhcp-relay": "docker-dhcp-relay:latest",
    "//dockers/docker-eventd:docker-eventd": "docker-eventd:latest",
    "//dockers/docker-fpm-frr:docker-fpm-frr": "docker-fpm-frr:latest",
    "//dockers/docker-gnmi-sidecar:docker-gnmi-sidecar": "docker-gnmi-sidecar:latest",
    "//dockers/docker-gnmi-watchdog:docker-gnmi-watchdog": "docker-gnmi-watchdog:latest",
    "//dockers/docker-lldp:docker-lldp": "docker-lldp:latest",
    "//dockers/docker-macsec:docker-macsec": "docker-macsec:latest",
    "//dockers/docker-mux:docker-mux": "docker-mux:latest",
    "//dockers/docker-nat:docker-nat": "docker-nat:latest",
    "//dockers/docker-orchagent:docker-orchagent": "docker-orchagent:latest",
    "//dockers/docker-platform-monitor:docker-platform-monitor": "docker-platform-monitor:latest",
    "//dockers/docker-restapi-sidecar:docker-restapi-sidecar": "docker-restapi-sidecar:latest",
    "//dockers/docker-router-advertiser:docker-router-advertiser": "docker-router-advertiser:latest",
    "//dockers/docker-sflow:docker-sflow": "docker-sflow:latest",
    "//dockers/docker-snmp:docker-snmp": "docker-snmp:latest",
    "//dockers/docker-sonic-bmp:docker-sonic-bmp": "docker-sonic-bmp:latest",
    "//dockers/docker-sonic-gnmi:docker-sonic-gnmi": "docker-sonic-gnmi:latest",
    "//dockers/docker-sonic-mgmt-framework:docker-sonic-mgmt-framework": "docker-sonic-mgmt-framework:latest",
    "//dockers/docker-sonic-otel:docker-sonic-otel": "docker-sonic-otel:latest",
    "//dockers/docker-sysmgr:docker-sysmgr": "docker-sysmgr:latest",
    "//dockers/docker-teamd:docker-teamd": "docker-teamd:latest",
    "//platform/vs/docker-dash-engine:docker-dash-engine": "docker-dash-engine:latest",
    "//platform/vs/docker-gbsyncd-vs:docker-gbsyncd-vs": "docker-gbsyncd-vs:latest",
    "//platform/vs/docker-syncd-vs:docker-syncd-vs": "docker-syncd-vs:latest",
}
