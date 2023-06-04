#!/bin/bash
#
# Description: Remove unused machine management scripts

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

# Remove 'bitnami-config-hostname' service and 'configure_app_domain' script if there are no scripts to configure the hostname
if [[ ! -d /opt/bitnami/scripts/updatehost || "$(find /opt/bitnami/scripts/updatehost -type f -printf . | wc -c)" -eq 0 ]]; then
    info "Removing bitnami-config-hostname service as there are no hostname configuration scripts"
    rm /etc/systemd/system/bitnami-config-hostname.service /opt/bitnami/configure_app_domain
    rm -rf /opt/bitnami/scripts/updatehost
fi

# Remove 'bitnami-config-resize' service if there are no scripts to configure the hostname
if [[ ! -d /opt/bitnami/scripts/resize || "$(find /opt/bitnami/scripts/resize -type f -printf . | wc -c)" -eq 0 ]]; then
    info "Removing bitnami-config-resize service as there are no resize configuration scripts"
    rm /etc/systemd/system/bitnami-config-resize.service
    rm -rf /opt/bitnami/scripts/resize
fi

# Remove 'ctlscript.sh' if there are no other Bitnami-managed services apart from 'bitnami', 'bitnami-config-hostname' and 'bitnami-config-resize'
if [[ "$(find /etc/systemd/system -type f -name 'bitnami.*.service' -printf . | wc -c)" -eq 0 ]]; then
    info "Removing ctlscript.sh script as there are no services to manage"
    rm /opt/bitnami/ctlscript.sh
fi
