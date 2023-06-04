#!/bin/bash
#
# Description: Re-open all exposed TCP ports that were closed in a previous init script
# This was done to avoid issues with health checks succeeding for TCP/HTTP ports even when the application is not ready

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

info "Enabling incoming connections to exposed ports"
systemctl reload nftables.service

# Restart services that may have been affected by these changes
# Docker must be restarted (not reloaded) in order to re-apply the updated networking rules to containers
if [[ -d /var/lib/docker ]]; then
    info "Restarting Docker daemon"
    systemctl restart docker
fi
