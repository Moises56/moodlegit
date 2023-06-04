#!/bin/bash
#
# Description: Block incoming connections to all TCP ports except for SSH
# This will avoid health checks for ports to succeed while the application is initialized
# References: https://wiki.nftables.org/wiki-nftables/index.php/Simple_rule_management

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

info "Blocking incoming connections to web server ports (while the machine is being initialized)"

# Obtain the handle number for the rule blocking ports
PORT_RULE_HANDLE_NUMBER="$(nft -a list chain inet firewall inbound | grep 'tcp dport' | head -n 1 | grep -Eo '# handle [0-9]+' | grep -Eo '[0-9]+' || true)"
if [[ -z "$PORT_RULE_HANDLE_NUMBER" ]]; then
    warn "Failed to block incoming connections to ports (while the machine is being initialized)"
else
    # Replace the current rule to block incoming to all ports except SSH
    nft replace rule inet firewall inbound handle "$PORT_RULE_HANDLE_NUMBER" tcp dport ssh accept
fi
