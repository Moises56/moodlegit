#!/bin/bash
#
# Description: Stores environment variables passed via user-data, to a 'user-data-env.sh' file

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libcloud.sh
. /opt/bitnami/scripts/liblog.sh

USER_DATA="$(cloud_get_user_data)"
USER_DATA_ENV_FILE="/var/lib/bitnami/user-data-env.sh"

if [[ -f "$USER_DATA_ENV_FILE" ]]; then
    exit
fi

if [[ -n "$USER_DATA" ]]; then
    info "Parsing environment variables specified within the user-data"
    USER_DATA_ENV="$(grep -E '^\s*export\s+(\w+=.*)$' <<< "$USER_DATA" || true)"
    if [[ -n "$USER_DATA_ENV" ]]; then
        echo "#!/bin/bash" > "$USER_DATA_ENV_FILE"
        echo "$USER_DATA_ENV" >> "$USER_DATA_ENV_FILE"
    else
        debug "No environment variables were detected within the user-data"
    fi
else
    info "No user-data was provided in the deployment template"
fi
