"""Feature flags for files/build_templates/init_cfg.json.j2.

slave.mk exports each INCLUDE_* / ENABLE_* from rules/config before rendering.
Values here are those defaults for the vs image; the three empty ones are unset
in rules/config, which is what makes the template emit buffer_model=traditional,
default_bgp_status=up and default_pfcwd_status=disable — matching Make's output.
All of init_cfg.json matches Make's byte-for-byte except the FEATURE entries for
dhcp_relay and macsec. Those two in Make's file still contain UNRENDERED jinja
(e.g. "state": "{% if not (DEVICE_METADATA ... %}enabled{% else %}...") and carry
sonic-package-manager's extra keys, because the package manager rewrites them on
the device at install time — the same three units it also regenerates. The values
rendered here are the correct build-time output.
"""

INIT_CFG_FLAGS = {
    # rules/config:393.
    "BUILD_REDUCE_IMAGE_SIZE": "n",
    "default_buffer_model": "",
    "enable_auto_tech_support": "y",
    "enable_pfcwd_on_start": "",
    "include_dhcp_server": "n",
    "include_iccpd": "n",
    "include_kubernetes": "n",
    "include_lldp": "y",
    "include_macsec": "y",
    "include_mgmt_framework": "y",
    "include_mux": "y",
    "include_nat": "y",
    "include_p4rt": "n",
    "include_restapi": "n",
    "include_router_advertiser": "y",
    "include_sflow": "y",
    "include_snmp": "y",
    "include_system_eventd": "y",
    "include_system_gnmi": "y",
    "include_system_otel": "y",
    "include_system_telemetry": "n",
    "include_teamd": "y",
    "shutdown_bgp_on_start": "",
}

