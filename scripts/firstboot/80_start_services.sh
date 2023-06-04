#!/bin/bash
#
# Description: Starts all Bitnami-managed services

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

SERVICES_TO_START=("bitnami.service")

# Execute resize scripts if defined
# This service will be executed before starting all application services (so that the services are launched with the new configuration)
if [[ -f /etc/systemd/system/bitnami-config-resize.service ]]; then
    info "Memory configuration scripts will be executed"
    SERVICES_TO_START+=("bitnami-config-resize.service")
fi

# Execute hostname configuration scripts if defined
# This service will be executed after all other application services have been started (since they require the app to be working)
if [[ -f /etc/systemd/system/bitnami-config-hostname.service ]]; then
    info "Hostname configuration scripts will be executed"
    SERVICES_TO_START+=("bitnami-config-hostname.service")
fi

info "Starting all services"
systemctl start "${SERVICES_TO_START[@]}"
