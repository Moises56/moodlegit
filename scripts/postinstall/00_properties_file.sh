#!/bin/bash
#
# Description: Generates a properties.ini file in /opt/bitnami, useful for Bitnami tools like bndiagnostic and bncert

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libcloud.sh
. /opt/bitnami/scripts/liblog.sh

IMAGE_NAME="$(cloud_get_metadata image_name)"
IMAGE_FULLNAME="$(cloud_get_metadata image_fullname)"
IMAGE_VERSION="$(cloud_get_metadata image_version)"

info "Generating /opt/bitnami/properties.ini file"
cat > /opt/bitnami/properties.ini <<EOF
[General]
base_stack_key=${IMAGE_NAME}
base_stack_name=${IMAGE_FULLNAME}
base_stack_version=${IMAGE_VERSION}
installdir=/opt/bitnami
EOF
