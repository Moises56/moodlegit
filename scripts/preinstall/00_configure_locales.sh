#!/bin/bash
#
# Description: Configures locales, to avoid warnings related to not being configured

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libfile.sh
. /opt/bitnami/scripts/liblog.sh

if [[ -f /etc/locale.gen ]]; then
    info "Configuring locales"
    replace_in_file /etc/locale.gen '#\s*(en_US\.UTF-8\s*.*)' '\1'
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
fi
