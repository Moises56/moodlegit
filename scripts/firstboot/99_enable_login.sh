#!/bin/bash
#
# Description: Enable login screen

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

rm -f /etc/no-login-console /etc/systemd/system/getty@tty1.service.d/wait-for-cloud-init.conf
