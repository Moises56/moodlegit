#!/bin/bash
#
# Bitnami installation configuration

export BITNAMI_METADATA_DIR="/var/lib/bitnami"
export BITNAMI_SERVICE_MANAGER="systemd"

# Load environment variables specified in user-data
# shellcheck disable=SC1090,SC1091
[[ ! -f "${BITNAMI_METADATA_DIR}/user-data-env.sh" ]] || . "${BITNAMI_METADATA_DIR}/user-data-env.sh"
