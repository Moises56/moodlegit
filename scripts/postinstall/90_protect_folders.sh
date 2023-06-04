#!/bin/bash
#
# Description: Protect internal folders used by initialization scripts from external access (they store credentials)

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libfs.sh
. /opt/bitnami/scripts/liblog.sh

info "Protecting internal folders from external access"
configure_permissions_ownership /var/lib/bitnami -d 700 -f 600 -u root -g root
