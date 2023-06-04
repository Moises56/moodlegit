#!/bin/bash
#
# Description: Reset the machine-id file, so it is unique at runtime
# References: https://www.freedesktop.org/software/systemd/man/machine-id.html

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

info "Resetting machine-id"
rm -rf /etc/machine-id
touch /etc/machine-id
