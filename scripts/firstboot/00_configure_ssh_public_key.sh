#!/bin/bash
#
# Description: Configure the SSH public key for the 'bitnami' user provided when deploying the OVF, and enable SSH if configured

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libcloud.sh
. /opt/bitnami/scripts/liblog.sh

SSH_KEY="$(cloud_get_ovf_env_parameter va-ssh-public-key)"

if [[ -n "$SSH_KEY" ]]; then
    info "Configuring SSH key provided in deployment template"
    su bitnami -c "mkdir -p ~/.ssh; chmod 700 ~/.ssh; echo '$SSH_KEY' >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys"

    # Remove forced password update script for CI/CD integration
    rm -f ~bitnami/change-password.sh

    info "Enabling SSH"
    rm -f /etc/ssh/sshd_not_to_be_run
    systemctl start ssh
fi
