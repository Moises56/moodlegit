#!/bin/bash
#
# Description: Configure the networking with user-defined settings, provided when deploying the OVF

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libcloud.sh
. /opt/bitnami/scripts/liblog.sh

# Helper functions
NETWORK_CONF_UPDATED=false
assert_interface_name() {
    # Ensure that the interface name was properly detected
    # Only executing when making use of it, to avoid errors when this feature was not enabled
    if [[ -z "$DEFAULT_NETWORK_INTERFACE_NAME" ]]; then
        error "Could not detect interface name from /sys/class/net"
        return 1
    fi
    NETWORK_CONF_UPDATED=true
}

# Configure network interfaces
DEFAULT_NETWORK_INTERFACE_NAME="$(find /sys/class/net -mindepth 1 -maxdepth 1 -name 'e*' -exec basename {} \; | head -n1)"
DEFAULT_NETWORK_INTERFACE_CONF_FILE="/etc/network/interfaces.d/${DEFAULT_NETWORK_INTERFACE_NAME}"
USER_DEFINED_NETWORK_IP0="$(cloud_get_ovf_env_parameter network.ip0)"
USER_DEFINED_NETWORK_GATEWAY="$(cloud_get_ovf_env_parameter network.gateway)"
if [[ -n "$USER_DEFINED_NETWORK_IP0" ]]; then
    assert_interface_name
    rm -f "$DEFAULT_NETWORK_INTERFACE_CONF_FILE"
    cat >> "$DEFAULT_NETWORK_INTERFACE_CONF_FILE" <<EOF
auto ${DEFAULT_NETWORK_INTERFACE_NAME}
iface ${DEFAULT_NETWORK_INTERFACE_NAME} inet static
    address ${USER_DEFINED_NETWORK_IP0}
EOF
    if [[ -n "$USER_DEFINED_NETWORK_GATEWAY" ]]; then
        cat >> "$DEFAULT_NETWORK_INTERFACE_CONF_FILE" <<EOF
    gateway ${USER_DEFINED_NETWORK_GATEWAY}
EOF
    fi
fi

# Configure DNS
DNS_CONF_FILE="/etc/dhcp/dhclient.conf"
USER_DEFINED_NETWORK_DNS="$(cloud_get_ovf_env_parameter network.dns)"
USER_DEFINED_NETWORK_DOMAIN="$(cloud_get_ovf_env_parameter network.domain)"
USER_DEFINED_NETWORK_SEARCHPATH="$(cloud_get_ovf_env_parameter network.searchpath)"
if [[ -n "$USER_DEFINED_NETWORK_DNS" || -n "$USER_DEFINED_NETWORK_DOMAIN" || -n "$USER_DEFINED_NETWORK_SEARCHPATH" ]]; then
    assert_interface_name
    # Add nameservers
    read -r -a dns_servers <<< "$(tr ',;' ' ' <<< "$USER_DEFINED_NETWORK_DNS")"
    if [[ "${#dns_servers[@]}" -le 0 ]]; then
        error "Could not detect any DNS server from the following string: ${USER_DEFINED_NETWORK_DNS}"
    fi
    echo "supersede domain-name-servers $(sed -E 's/ +/, /g' <<< "${dns_servers[*]}")" >> "$DNS_CONF_FILE"
    # Add search domains
    read -r -a search_domains <<< "$(tr ',;' ' ' <<< "$USER_DEFINED_NETWORK_SEARCHPATH")"
    if [[ -n "$USER_DEFINED_NETWORK_DOMAIN" ]]; then
        echo "supersede domain-name \"${USER_DEFINED_NETWORK_DOMAIN}\"" >> "$DNS_CONF_FILE"
        search_domains=("$USER_DEFINED_NETWORK_DOMAIN" "${search_domains[@]}")
    fi
    if [[ "${#search_domains[@]}" -gt 0 ]]; then
        echo "supersede domain-search \"${search_domains[*]}\"" >> "$DNS_CONF_FILE"
    fi
fi

if "$NETWORK_CONF_UPDATED"; then
    # Disable cloud-init network configuration capabilities, in order to avoid config being reloaded after a reboot
    echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
    rm -f /etc/network/interfaces.d/50-cloud-init
    sudo ip addr flush "$DEFAULT_NETWORK_INTERFACE_NAME"
    sudo systemctl restart networking
fi
