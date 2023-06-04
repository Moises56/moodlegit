#!/bin/bash
#
# Description: Creates the motd banner, used when connecting to the instance via console or SSH
# References: https://man7.org/linux/man-pages/man5/motd.5.html

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libcloud.sh
. /opt/bitnami/scripts/liblog.sh

IMAGE_FULLNAME="$(cloud_get_metadata image_fullname)"
IMAGE_VERSION="$(cloud_get_metadata image_version)"
DOCUMENTATION_URL="$(cloud_get_metadata documentation_url)"
SUPPORT_URL="$(cloud_get_metadata support_url)"

info "Adding motd banner"
cat >>/etc/motd <<EOF
       ___ _ _                   _
      | _ |_) |_ _ _  __ _ _ __ (_)
      | _ \ |  _| ' \/ _\` | '  \| |
      |___/_|\__|_|_|\__,_|_|_|_|_|

  -> Welcome to ${IMAGE_FULLNAME} ${IMAGE_VERSION}
  -> Documentation:   ${DOCUMENTATION_URL}
  -> Bitnami Support: ${SUPPORT_URL}
EOF
