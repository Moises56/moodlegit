#!/bin/bash
#
# Description: Sets a flag to indicate that the first boot failed

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libcloud.sh

cloud_set_metadata "first_boot_status" "false"
