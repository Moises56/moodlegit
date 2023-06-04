#!/bin/bash
#
# Description: Clean the system before distribution

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

# Remove package manager cache
# Note that 'apt-get clean' does not properly clean up the lists (100MB+)
info "Cleaning up package manager caches"
rm -rf /var/lib/apt/lists /var/cache/apt

# Remove log files, some of which take up significant space even in new installations (e.g. journal)
info "Cleaning up log files"
rm -rf /var/log/journal/*
find /var/log -type f -delete

# Remove doc and locale files
rm -rf /usr/share/doc/* /usr/share/locale/*
