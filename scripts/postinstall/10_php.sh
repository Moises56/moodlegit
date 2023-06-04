#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/bitnami/scripts/libphp.sh
. /opt/bitnami/scripts/libfs.sh

# Load PHP-FPM environment variables
. /opt/bitnami/scripts/php-env.sh

# PHP OPcache optimizations
php_conf_set "opcache.interned_strings_buffer" "$PHP_DEFAULT_OPCACHE_INTERNED_STRINGS_BUFFER"
php_conf_set "opcache.memory_consumption" "$PHP_DEFAULT_OPCACHE_MEMORY_CONSUMPTION"
php_conf_set "opcache.file_cache" "$PHP_DEFAULT_OPCACHE_FILE_CACHE"

# PHP-FPM configuration
php_conf_set "listen" "$PHP_FPM_DEFAULT_LISTEN_ADDRESS" "${PHP_CONF_DIR}/php-fpm.d/www.conf"

# TMP dir configuration
php_conf_set "upload_tmp_dir" "${PHP_BASE_DIR}/tmp"
php_conf_set "session.save_path" "${PHP_TMP_DIR}/session"

# Ensure directories used by PHP-FPM exist and have proper ownership and permissions
for dir in "$PHP_CONF_DIR" "${PHP_BASE_DIR}/tmp" "$PHP_TMP_DIR" "$PHP_FPM_LOGS_DIR" "${PHP_TMP_DIR}/session"; do
    ensure_dir_exists "$dir"
    chmod -R g+rwX "$dir"
done

# Load additional required libraries
# shellcheck disable=SC1091
. /opt/bitnami/scripts/libos.sh

info "Creating PHP-FPM daemon user"
ensure_user_exists "$PHP_FPM_DAEMON_USER" --group "$PHP_FPM_DAEMON_GROUP"

# Ensure directories used by PHP-FPM have proper ownership and permissions
# Note that the log directory should only be writable by 'root' since the service is started by it (like Apache or NGINX)
chown -R "${PHP_FPM_DAEMON_USER}:${PHP_FPM_DAEMON_GROUP}" "$PHP_TMP_DIR"

# Render configuration file for the main 'www' PHP-FPM pool
template_dir="${BITNAMI_ROOT_DIR}/scripts/bitnami-templates/php"
render-template "${template_dir}/www.conf.tpl" >"${PHP_CONF_DIR}/php-fpm.d/www.conf"

# Enable extra service management configuration
if [[ "$BITNAMI_SERVICE_MANAGER" = "monit" ]]; then
    generate_monit_conf "php-fpm" "$PHP_FPM_PID_FILE" /opt/bitnami/scripts/php/start.sh /opt/bitnami/scripts/php/stop.sh
elif [[ "$BITNAMI_SERVICE_MANAGER" = "systemd" ]]; then
    # Use 'simple' type to start service in foreground and consider started while it is running
    generate_systemd_conf "php-fpm" \
        --name "PHP-FPM" \
        --exec-start "${PHP_FPM_SBIN_DIR}/php-fpm --pid ${PHP_FPM_PID_FILE} --fpm-config ${PHP_FPM_CONF_FILE} -c ${PHP_CONF_DIR}" \
        --exec-reload "kill -USR2 \$MAINPID" \
        --pid-file "$PHP_FPM_PID_FILE"
else
    error "Unsupported service manager ${BITNAMI_SERVICE_MANAGER}"
    exit 1
fi
generate_logrotate_conf "php-fpm" "$PHP_FPM_LOG_FILE"

# Create configuration files for setting PHP-FPM optimization parameters depending on the instance size
# Default to micro configuration until a resize is performed
ensure_dir_exists "${PHP_CONF_DIR}/memory"
ln -sf "memory/memory-micro.conf" "${PHP_CONF_DIR}/memory.conf"
read -r -a supported_machine_sizes <<< "$(get_supported_machine_sizes)"
for machine_size in "${supported_machine_sizes[@]}"; do
    case "$machine_size" in
        micro)
            max_children=15
            start_servers=10
            min_spare_servers=10
            max_spare_servers=10
            max_requests=5000
            ;;
        small)
            max_children=30
            start_servers=20
            min_spare_servers=20
            max_spare_servers=22
            max_requests=5000
            ;;
        medium)
            max_children=60
            start_servers=40
            min_spare_servers=40
            max_spare_servers=45
            max_requests=5000
            ;;
        large)
            max_children=120
            start_servers=80
            min_spare_servers=80
            max_spare_servers=90
            max_requests=5000
            ;;
        xlarge)
            max_children=200
            start_servers=130
            min_spare_servers=130
            max_spare_servers=150
            max_requests=5000
            ;;
        2xlarge)
            max_children=400
            start_servers=260
            min_spare_servers=260
            max_spare_servers=300
            max_requests=5000
            ;;
        *)
            error "Unknown machine size '${machine_size}'"
            exit 1
            ;;
        esac
    cat >"${PHP_CONF_DIR}/memory/memory-${machine_size}.conf" <<EOF
; Bitnami memory configuration for PHP-FPM
;
; Note: This will be modified on server size changes

pm.max_children=${max_children}
pm.start_servers=${start_servers}
pm.min_spare_servers=${min_spare_servers}
pm.max_spare_servers=${max_spare_servers}
pm.max_requests=${max_requests}
EOF
done

# Allow the "bitnami" user to write to commonly-used PHP files, for improved developer experience
if user_exists "bitnami"; then
    chown bitnami "$PHP_CONF_FILE"
fi
