#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/bitnami/scripts/libphp.sh
. /opt/bitnami/scripts/libos.sh

# Load PHP-FPM environment
. /opt/bitnami/scripts/php-env.sh

machine_size="$(get_machine_size "$@")"
ln -sf "memory/memory-${machine_size}.conf" "${PHP_CONF_DIR}/memory.conf"
