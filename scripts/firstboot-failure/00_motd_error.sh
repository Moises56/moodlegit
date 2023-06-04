#!/bin/bash
#
# Description: Adds an error box in the motd banner, indicating initialization scripts failures and how to proceed
# References: https://man7.org/linux/man-pages/man5/motd.5.html

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

info "Appending error message to motd banner"
cat >>/etc/motd <<EOF

┌──────────────────────────────────────────────────────────────────────────────┐
│ !!!!! IMPORTANT: An error occurred when initializing this installation !!!!! │
│ Please check the initialization logs to get more information:                │
│                                                                              │
│   sudo cat /var/log/cloud-init-output.log                                    │
│                                                                              │
│ Please try and re-create this installation. If that does not fix your issue, │
│ open a Bitnami support ticket at https://github.com/bitnami/vms/issues       │
└──────────────────────────────────────────────────────────────────────────────┘

EOF
