#!/bin/bash
#
# Description: Creates the admin user, if it does not exist already, using cloud-init
# Reference: https://cloudinit.readthedocs.io/en/latest/topics/modules.html#users-and-groups

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

if [[ "$SUDO_USER" != "root" && "$SUDO_USER" != "bitnami" ]]; then
    # Creates admin user from '10_bitnami.cfg'
    info "Creating admin user"
    cloud-init single --name cc_users_groups
fi
