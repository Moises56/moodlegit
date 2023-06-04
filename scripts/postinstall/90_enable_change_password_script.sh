#!/bin/bash
#
# Description: Enables the 'change-password.sh' script to be executed at the first login

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

info "Enabling password change script"
chown bitnami:bitnami ~bitnami/change-password.sh
cat >> ~bitnami/.bashrc <<EOF
if [[ -f ~/change-password.sh ]]; then
    ~/change-password.sh
fi
EOF
