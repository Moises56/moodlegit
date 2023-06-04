#!/bin/bash
#
# Description: Fills the empty disk space with zeros, to reduce the resulting image size

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

info "Zero-ing out free space to reduce resulting image size, this may take a while..."
# Note: This command is always expected to fail with an error: "dd: error writing '/zerofile': No space left on device"
dd if=/dev/zero of=/zerofile bs=1M || true
rm /zerofile
