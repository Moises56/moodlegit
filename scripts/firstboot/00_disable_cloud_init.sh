#!/bin/bash
#
# Description: Disables cloud-init to avoid "waiting for configuration file took 90.x seconds" warnings
# Reference: https://bugs.launchpad.net/cloud-init/+bug/1835205

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

touch /etc/cloud/cloud-init.disabled
