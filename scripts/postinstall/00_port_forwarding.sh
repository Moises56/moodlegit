#!/bin/bash
#
# Description: Configure the firewall to block incoming connections to non-exposed ports
# References: https://wiki.nftables.org/wiki-nftables/index.php/Simple_ruleset_for_a_server

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libcloud.sh
. /opt/bitnami/scripts/liblog.sh

read -r -a IMAGE_EXPOSED_PORTS <<< "$(cloud_get_metadata "exposed_ports")"
if [[ "${#IMAGE_EXPOSED_PORTS[@]}" -le 0 ]]; then
    error "Could not detect any ports to expose"
    exit 1
fi

# Obtain ports to forward from image exposed ports, with format "origin:target" (e.g. 8080:80 will map port 8080 to 80)
PORTS_TO_FORWARD=()
for port in "${IMAGE_EXPOSED_PORTS[@]}"; do
    if [[ "$port" =~ ^([0-9]+):([0-9]+)$ ]]; then
        PORTS_TO_FORWARD+=("$port")
    fi
done

if [[ "${#PORTS_TO_FORWARD[@]}" -le 0 ]]; then
    info "No port forwardings will be configured"
    exit
fi

info "Enabling port forwarding"
debug "The following ports forwardings will be configured: ${PORTS_TO_FORWARD[*]}"

# Enable port forwarding in the kernel configuration
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/95-IPv4-forwarding.conf
sysctl -p /etc/sysctl.d/95-IPv4-forwarding.conf

# Enable nftables configuration
cat >> /etc/nftables.conf <<EOF

table ip nat {
    chain prerouting {
        # Enable a pre-routing chain in the NAT table
        type nat hook prerouting priority -100;
EOF
for port in "${PORTS_TO_FORWARD[@]}"; do
    INCOMING_PORT="${port%%:*}"
    FORWARD_PORT="${port##*:}"
    cat >> /etc/nftables.conf <<EOF

        # Forward port ${INCOMING_PORT} to port ${FORWARD_PORT}
        tcp dport ${INCOMING_PORT} redirect to :${FORWARD_PORT}
EOF
done
cat >> /etc/nftables.conf <<EOF
    }
}
EOF
