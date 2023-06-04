#!/bin/bash
#
# Description: Reset the cloud-init environment
# References: https://cloudinit.readthedocs.io/en/latest/topics/boot.html#manual-cache-cleaning

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

info "Resetting cloud-init environment"
cloud-init clean
