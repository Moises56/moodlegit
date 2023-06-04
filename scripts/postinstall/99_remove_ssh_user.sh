#!/bin/bash
#
# Description: Disable the non-bitnami SSH user

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

# The bitnami user will be created via userdata, so we can disable the non-bitnami SSH user
if [[ "$SUDO_USER" != "root" && "$SUDO_USER" != "bitnami" ]]; then
    info "Disabling login for the '${SUDO_USER}' user"
    usermod -s /usr/sbin/nologin "$SUDO_USER"
    rm -rf /home/"$SUDO_USER"/.ssh
fi
