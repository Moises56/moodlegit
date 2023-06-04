#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/bitnami/scripts/libphp.sh
. /opt/bitnami/scripts/liblog.sh

# Load PHP environment
. /opt/bitnami/scripts/php-env.sh

# To determine the main database type, we first check if "mariadb" folder exists
# This is because mysql-client folder name is "mysql", even if MariaDB is the main database
if [[ -d "${BITNAMI_ROOT_DIR}/mariadb" ]]; then
    database_type="mariadb"
elif [[ -d "${BITNAMI_ROOT_DIR}/mysql" ]]; then
    database_type="mysql"
else
    error "Could not find a valid MySQL or MariaDB database in '${BITNAMI_ROOT_DIR}'."
    exit 1
fi
socket_file="${BITNAMI_ROOT_DIR}/${database_type}/tmp/mysql.sock"
php_conf_set "mysqli.default_socket" "$socket_file"
php_conf_set "pdo_mysql.default_socket" "$socket_file"
