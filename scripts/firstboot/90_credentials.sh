#!/bin/bash
#
# Creates the 'bitnami_credentials' file with the application's credentials, and prints them to the system log

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libcloud.sh
. /opt/bitnami/scripts/liblog.sh

IMAGE_FULLNAME="$(cloud_get_metadata "image_fullname")"
IMAGE_USERNAME="$(cloud_get_metadata "credential_username")"
IMAGE_PASSWORD="$(cloud_get_metadata "credential_password")"
[[ "$IMAGE_PASSWORD" =~ ^credential: ]] && IMAGE_PASSWORD="$(cloud_generate_credential "${IMAGE_PASSWORD//credential:/}")"
DOCUMENTATION_URL="$(cloud_get_metadata documentation_url)"

# Create credentials file
BITNAMI_CREDENTIALS_FILE=~bitnami/bitnami_credentials
cat > "$BITNAMI_CREDENTIALS_FILE" <<< "Welcome to ${IMAGE_FULLNAME}"

if [[ -n "$IMAGE_USERNAME" || -n "$IMAGE_PASSWORD" ]]; then
    cat >> "$BITNAMI_CREDENTIALS_FILE" <<EOF

******************************************************************************
EOF

    # Print credentials information
    if [[ -n "$IMAGE_USERNAME" && -n "$IMAGE_PASSWORD" ]]; then
        cat >> "$BITNAMI_CREDENTIALS_FILE" <<< "The default username is '${IMAGE_USERNAME}' and the default password is '${IMAGE_PASSWORD}'."
    elif [[ -n "$IMAGE_USERNAME" ]]; then
        cat >> "$BITNAMI_CREDENTIALS_FILE" <<< "The default username is '${IMAGE_USERNAME}'."
    elif [[ -n "$IMAGE_PASSWORD" ]]; then
        cat >> "$BITNAMI_CREDENTIALS_FILE" <<< "The default password is '${IMAGE_PASSWORD}'."
    fi

    cat >> "$BITNAMI_CREDENTIALS_FILE" <<EOF
******************************************************************************

EOF
    if [[ -n "$IMAGE_PASSWORD" ]]; then
        cat >> "$BITNAMI_CREDENTIALS_FILE" <<EOF
You can also use this password to access the databases and any other component the stack includes.

EOF
    fi
else
    info "No application credentials were generated"
fi

cat >> "$BITNAMI_CREDENTIALS_FILE" <<< "Please refer to ${DOCUMENTATION_URL} for more details."

# Protect the credentials file from unwanted access
chown bitnami:bitnami "$BITNAMI_CREDENTIALS_FILE"
chmod 600 "$BITNAMI_CREDENTIALS_FILE"

# Print credentials so they appear in the system log
if [[ -n "$IMAGE_PASSWORD" ]]; then
    cat 2>&1 <<EOF
##############################################################

    Setting Bitnami application password to '${IMAGE_PASSWORD}'
EOF
    if [[ -n "$IMAGE_USERNAME" ]]; then
        cat 2>&1 <<EOF
    (the default application username is '${IMAGE_USERNAME}')
EOF
    fi
    cat 2>&1 <<EOF

##############################################################
EOF
fi
