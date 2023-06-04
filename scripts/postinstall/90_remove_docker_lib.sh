#!/bin/bash
#
# If present, removes the Docker 'lib' directory during the VM first boot to optimize build time

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libcloud.sh
. /opt/bitnami/scripts/liblog.sh

# The objective of this script is to not include /var/lib/docker in the image.
# By default, installing docker.io will configure devicemapper storage plugin which relies in sparse files.
# Because of the sparse files, attempting to uncompress the image using 7z will cause the process to consume a lot of time and disk space.
# If removed, docker will recreate /var/lib/docker during its next initialization
# Additionally, docker will configure the storage plugin that better fits the host (overlay2 if available, devicemapper if not).
if [[ -d /var/lib/docker ]]; then
    systemctl stop docker
    rm -rf /var/lib/docker
fi
