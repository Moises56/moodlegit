#!/bin/bash
#
# Description: Store the base root disk size metadata in the image

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libcloud.sh
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libos.sh

info "Storing root disk size metadata"
cloud_set_metadata disk_size "$(get_root_disk_size)"
