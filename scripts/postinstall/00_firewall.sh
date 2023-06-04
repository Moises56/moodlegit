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

# Parse port strings, e.g.:
# * Single port - 80 will include 80 (supported by nftables)
# * Lists - 4000-4002 will include 4000, 4001 and 4002 (supported by nftables)
# * Port maps - 8080:80 will include 8080 (not directly supported, need to extract the origin port)
PORTS_TO_EXPOSE=()
for port in "${IMAGE_EXPOSED_PORTS[@]}"; do
    if [[ "$port" =~ ^([0-9]+):([0-9]+)$ ]]; then
        PORTS_TO_EXPOSE+=("${BASH_REMATCH[1]}")
    else
        PORTS_TO_EXPOSE+=("$port")
    fi
done

info "Blocking incoming connections via nftables firewall"
debug "The following ports will still be accessible for public access: ${PORTS_TO_EXPOSE[*]}"
cat > /etc/nftables.conf <<EOF
#!/usr/sbin/nft -f

flush ruleset

table inet firewall {
    chain inbound_ipv4 {
        # accepting ping (icmp-echo-request) for diagnostic purposes.
        # However, it also lets probes discover this host is alive.
        # This sample accepts them within a certain rate limit:
        icmp type echo-request limit rate 5/second accept
    }
    chain inbound_ipv6 {
        # accept neighbour discovery otherwise connectivity breaks
        #
        icmpv6 type { nd-neighbor-solicit, nd-router-advert, nd-neighbor-advert } accept

        # accepting ping (icmpv6-echo-request) for diagnostic purposes.
        # However, it also lets probes discover this host is alive.
        # This sample accepts them within a certain rate limit:
        icmpv6 type echo-request limit rate 5/second accept
    }
    chain inbound {
        # By default, drop all traffic unless it meets a filter
        # criteria specified by the rules that follow below.
        type filter hook input priority 0; policy drop;

        # Allow traffic from established and related packets, drop invalid
        ct state vmap { established : accept, related : accept, invalid : drop }

        # Allow loopback traffic.
        iifname lo accept

        # Jump to chain according to layer 3 protocol using a verdict map
        meta protocol vmap { ip : jump inbound_ipv4, ip6 : jump inbound_ipv6 }

        # Allow selected ports for IPv4 and IPv6.
        tcp dport { $(sed -E 's/\s+/, /g' <<< "${PORTS_TO_EXPOSE[*]}") } accept

        # Uncomment to enable logging of denied inbound traffic
        # log prefix "[nftables] Inbound Denied: " counter drop
    }
    chain forward {
        # Drop everything (assumes this device is not a router)
        type filter hook forward priority 0; policy drop;
    }
    # no need to define output chain, default policy is accept if undefined.
}
EOF

info "Enabling firewall service"
systemctl enable nftables.service
