#!/bin/bash
#
# Description: Configures the default SSH daemon to disable by default, and require public key (by disabling password authentication)

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libfile.sh
. /opt/bitnami/scripts/liblog.sh

########################
# Helper function to set a configuration in the 'sshd_config' file
# Arguments:
#   $1 - configuration key
#   $2 - value to set
# Returns:
#   None
#########################
sshd_config() {
    local -r key="${1:?missing key}"
    local -r value="${2:?missing value}"
    local -r file="/etc/ssh/sshd_config"
    debug "Setting '${key}' to '${value}' in ${file}"
    local -r pattern="^#?${key} .*"
    if grep -qE "$pattern" "$file"; then
        replace_in_file "$file" "$pattern" "${key} ${value}"
    else
        error "Could not find configuration '${key}' in ${file}"
        return 1
    fi
}

info "Disabling SSH password authentication"
sshd_config PasswordAuthentication no

info "Disabling SSH root login"
sshd_config PermitRootLogin no

info "Configuring SSH idle timeout"
sshd_config ClientAliveInterval 180

info "Disabling SSH"
touch /etc/ssh/sshd_not_to_be_run
