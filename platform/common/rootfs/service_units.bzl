"""systemd unit templates and the per-service variables to render them with.

slave.mk renders each container's unit up to three times (slave.mk:1815-1838):
  files/build_templates/<c>.service.j2               -> <c>.service
  files/build_templates/per_namespace/<c>.service.j2 -> <c>.service and <c>@.service
                                                        (multi_instance false/true)
  files/build_templates/share_image/<c>.service.j2   -> <c>-chassis.service

dhcp_relay.service, macsec.service and macsec@.service are deliberately NOT here:
they carry the "Managed by SONiC Package Manager. DO NOT EDIT!" banner and are
generated on the device from /usr/share/sonic/templates/sonic.service.j2 at
package-install time, not from a build template. Those three stay as the files
Make's image ships.

# unit name -> (template label, container name, multi_instance)
"""

SERVICE_UNITS = {
    'bgp.service': (
        '//files/build_templates:per_namespace/bgp.service.j2',
        'bgp',
        'false',
    ),
    'bgp@.service': (
        '//files/build_templates:per_namespace/bgp.service.j2',
        'bgp',
        'true',
    ),
    'bmp.service': (
        '//files/build_templates:per_namespace/bmp.service.j2',
        'bmp',
        'false',
    ),
    'bmp@.service': (
        '//files/build_templates:per_namespace/bmp.service.j2',
        'bmp',
        'true',
    ),
    'config-chassisdb.service': (
        '//files/build_templates:config-chassisdb.service.j2',
        'config-chassisdb',
        'false',
    ),
    'config-setup.service': (
        '//files/build_templates:config-setup.service.j2',
        'config-setup',
        'false',
    ),
    'dash-ha.service': (
        '//files/build_templates:per_namespace/dash-ha.service.j2',
        'dash-ha',
        'false',
    ),
    'dash-ha@.service': (
        '//files/build_templates:per_namespace/dash-ha.service.j2',
        'dash-ha',
        'true',
    ),
    'database-chassis.service': (
        '//files/build_templates:share_image/database.service.j2',
        'database',
        'false',
    ),
    'database.service': (
        '//files/build_templates:database.service.j2',
        'database',
        'false',
    ),
    'database@.service': (
        '//files/build_templates:per_namespace/database.service.j2',
        'database',
        'true',
    ),
    'eventd.service': (
        '//files/build_templates:eventd.service.j2',
        'eventd',
        'false',
    ),
    'gbsyncd.service': (
        '//files/build_templates:per_namespace/gbsyncd.service.j2',
        'gbsyncd',
        'false',
    ),
    'gbsyncd@.service': (
        '//files/build_templates:per_namespace/gbsyncd.service.j2',
        'gbsyncd',
        'true',
    ),
    'gnmi.service': (
        '//files/build_templates:gnmi.service.j2',
        'gnmi',
        'false',
    ),
    'lldp.service': (
        '//files/build_templates:per_namespace/lldp.service.j2',
        'lldp',
        'false',
    ),
    'lldp@.service': (
        '//files/build_templates:per_namespace/lldp.service.j2',
        'lldp',
        'true',
    ),
    'mgmt-framework.service': (
        '//files/build_templates:mgmt-framework.service.j2',
        'mgmt-framework',
        'false',
    ),
    'mux.service': (
        '//files/build_templates:mux.service.j2',
        'mux',
        'false',
    ),
    'nat.service': (
        '//files/build_templates:nat.service.j2',
        'nat',
        'false',
    ),
    'otel.service': (
        '//files/build_templates:otel.service.j2',
        'otel',
        'false',
    ),
    'pmon.service': (
        '//files/build_templates:pmon.service.j2',
        'pmon',
        'false',
    ),
    'radv.service': (
        '//files/build_templates:radv.service.j2',
        'radv',
        'false',
    ),
    'sflow.service': (
        '//files/build_templates:sflow.service.j2',
        'sflow',
        'false',
    ),
    'snmp.service': (
        '//files/build_templates:snmp.service.j2',
        'snmp',
        'false',
    ),
    'swss.service': (
        '//files/build_templates:per_namespace/swss.service.j2',
        'swss',
        'false',
    ),
    'swss@.service': (
        '//files/build_templates:per_namespace/swss.service.j2',
        'swss',
        'true',
    ),
    'syncd.service': (
        '//files/build_templates:per_namespace/syncd.service.j2',
        'syncd',
        'false',
    ),
    'syncd@.service': (
        '//files/build_templates:per_namespace/syncd.service.j2',
        'syncd',
        'true',
    ),
    'sysmgr.service': (
        '//files/build_templates:sysmgr.service.j2',
        'sysmgr',
        'false',
    ),
    'teamd.service': (
        '//files/build_templates:per_namespace/teamd.service.j2',
        'teamd',
        'false',
    ),
    'teamd@.service': (
        '//files/build_templates:per_namespace/teamd.service.j2',
        'teamd',
        'true',
    ),
}

# rules/config DEFAULT_USERNAME.
SONICADMIN_USER = "admin"

# slave.mk:1857-1863's $(SERVICES): the unit names the image actually installs.
# A container whose only template is per_namespace/<c>.service.j2 contributes
# just <c>@.service — the plain unit is rendered but not listed, which is what
# makes has_global_scope false for it in init_cfg.json.
INSTALLER_SERVICES = [
    'bgp@.service',
    'bmp@.service',
    'config-chassisdb.service',
    'config-setup.service',
    'dash-ha@.service',
    'database-chassis.service',
    'database.service',
    'database@.service',
    'dhcp_relay.service',
    'eventd.service',
    'gbsyncd@.service',
    'gnmi.service',
    'lldp@.service',
    'macsec@.service',
    'mgmt-framework.service',
    'mux.service',
    'nat.service',
    'otel.service',
    'pmon.service',
    'radv.service',
    'sflow.service',
    'snmp.service',
    'swss@.service',
    'syncd@.service',
    'sysmgr.service',
    'teamd@.service',
]
