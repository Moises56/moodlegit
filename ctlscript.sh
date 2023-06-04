#!/bin/bash
#
# Description: Wrapper to easily manage all Bitnami systemd services

BITNAMI_PREFIX=bitnami

if [[ "$(id -u)" != "0" ]]; then
    echo "This script must be run as a superuser"
    exit 1
fi

help() {
    cat <<EOF
usage: $0 [command]
       $0 [command] [service]

Commands:
  help                               show help menu
  start                              start the service(s)
  stop                               stop  the service(s)
  restart                            restart or start the service(s)
  status                             show the status of the service(s)
EOF
}

# Prints the list of Bitnami services that are currently enabled
get_enabled_services() {
    systemctl list-unit-files --no-legend --state=enabled "${BITNAMI_PREFIX}.*.service" | grep -Eo 'bitnami\.[^.]+\.service\s*.*' | awk '{ print $1 }'
}

# Prints service status from systemd
get_service_status() {
    systemctl list-units --no-legend --type=service --all --full "${BITNAMI_PREFIX}.${1:-*}.service" | grep -Eo 'bitnami\.[^.]+\.service\s*.*' | awk '{
        print $1, ($4 == "running" ? "already" : "not"), "running";
    }' | sed -E "s/${BITNAMI_PREFIX}\.([^ ]+)\.service/\1/"
}

STATUS_CODE=0
if [[ "$1" = "help" ]]; then
    help
elif [[ ! "$1" =~ ^(start|stop|restart|status)$ ]]; then
    echo "Unknown option ${1}"
    help
    STATUS_CODE=1
elif [[ -z "$2" ]]; then
    if [[ "$1" =~ ^(start|stop|restart)$ ]]; then
        echo "${1}$([[ "$1" = "stop" ]] && echo "p")ing services..."
        systemctl "$1" "${BITNAMI_PREFIX}.service"
    elif [[ "$1" = "status" ]]; then
        get_service_status
    else
        help
        STATUS_CODE="1"
    fi
else
    if ! grep -q -E "^${BITNAMI_PREFIX}\\.${2}\\.service$" <<< "$(get_enabled_services)"; then
        echo "Unknown service ${2}"
        STATUS_CODE="1"
    elif [[ "$1" =~ ^(start|stop|restart)$ ]]; then
        systemctl "$1" "${BITNAMI_PREFIX}.${2}.service"
        STATUS_CODE="$?"
    elif [[ "$1" = "status" ]]; then
        get_service_status "$2"
    else
        help
        STATUS_CODE="1"
    fi
fi

exit "$STATUS_CODE"
