#!/bin/bash
#
# Description: Enables all Bitnami-managed services

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

info "Enabling all services"
systemctl enable /etc/systemd/system/bitnami*.service
