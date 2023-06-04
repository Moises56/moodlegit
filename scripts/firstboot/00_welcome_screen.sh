#!/bin/bash
#
# Description: Creates the welcome screen (pre-login banner), which appears right after connecting to the VM via console
# References: https://man7.org/linux/man-pages/man5/issue.5.html

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libcloud.sh
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libos.sh

IMAGE_FULLNAME="$(cloud_get_metadata "image_fullname")"
IMAGE_USERNAME="$(cloud_get_metadata "credential_username")"
IMAGE_PASSWORD="$(cloud_get_metadata "credential_password")"
IMAGE_EXPOSED_PORTS="$(cloud_get_metadata "exposed_ports")"
[[ "$IMAGE_PASSWORD" =~ ^credential: ]] && IMAGE_PASSWORD="$(cloud_generate_credential "${IMAGE_PASSWORD//credential:/}")"
OS_NAME="$(get_os_metadata --pretty-name)"
OS_HOSTNAME="$(cloud_get_machine_ip_address || true)"
DOCUMENTATION_URL="$(cloud_get_metadata documentation_url)"
SUPPORT_URL="$(cloud_get_metadata support_url)"

info "Adding login screen"

# Print Bitnami banner with general system information
cat > /etc/issue <<EOF
[0;36m
       ___ _ _                   _
      | _ |_) |_ _ _  __ _ _ __ (_)
      | _ \\\\ |  _| ' \\\\/ _\` | '  \\\\| |
      |___/_|\\\\__|_|_|\\\\__,_|_|_|_|_|
[0m
[0;36m
[1m*** Welcome to ${IMAGE_FULLNAME} ***
[1m*** Built using ${OS_NAME} - Kernel \r (\l) ***[0m
[1;33m
EOF

# Print networking information
if [[ -z "$OS_HOSTNAME" ]]; then
    cat >> /etc/issue <<EOF
[1m*** The machine could not configure the network interface ***
[1m*** Please visit https://docs.bitnami.com/virtual-machine/ for details ***
[0m
EOF
elif [[ " ${IMAGE_EXPOSED_PORTS} " = *" 80 "* || " ${IMAGE_EXPOSED_PORTS} " = *" 80:"* ]]; then
    cat >> /etc/issue <<< "[1m*** You can access the application at http://${OS_HOSTNAME} ***"
elif [[ " ${IMAGE_EXPOSED_PORTS} " = *" 443 "* || " ${IMAGE_EXPOSED_PORTS} " = *" 443:"* ]]; then
    cat >> /etc/issue <<< "[1m*** You can access the application at https://${OS_HOSTNAME} ***"
else
    cat >> /etc/issue <<< "[1m*** You can connect to the service using ${OS_HOSTNAME} ***"
fi

# Print credentials information
if [[ -n "$IMAGE_USERNAME" && -n "$IMAGE_PASSWORD" ]]; then
    cat >> /etc/issue <<< "[1m*** The default username is '${IMAGE_USERNAME}' and the default password is '${IMAGE_PASSWORD}' ***"
elif [[ -n "$IMAGE_USERNAME" ]]; then
    cat >> /etc/issue <<< "[1m*** The default username is '${IMAGE_USERNAME}' ***"
elif [[ -n "$IMAGE_PASSWORD" ]]; then
    cat >> /etc/issue <<< "[1m*** The default password is '${IMAGE_PASSWORD}' ***"
fi

# Print other useful information
cat >> /etc/issue <<EOF
[1m*** You can find out more at ${DOCUMENTATION_URL} ***
[1m*** If you find any issues, please visit ${SUPPORT_URL} ***
[1;31m
******************************************************************************
   To access the console, login with user 'bitnami' and password 'bitnami'
******************************************************************************
[0m
EOF

# Protect the credentials file from unwanted access
chmod 600 /etc/issue
