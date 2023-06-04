[www]
include={{PHP_CONF_DIR}}/environment.conf
include={{PHP_CONF_DIR}}/common.conf
pm=dynamic
listen={{PHP_TMP_DIR}}/www.sock
listen.allowed_clients=127.0.0.1

; Memory settings adapted to the machine
; The file below will be overwritten after restarts
include={{PHP_CONF_DIR}}/memory.conf
