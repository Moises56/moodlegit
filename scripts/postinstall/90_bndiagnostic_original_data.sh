#!/bin/bash
#
# Description: Generates bndiagnostic files with the original configuration files bundled in the image

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

if [[ -d /opt/gitlab ]]; then
    info "Skipping Bndiagnostic original configuration data generation"
    exit
fi

info "Generating Bndiagnostic original configuration data"
/opt/bitnami/bndiagnostic-tool --mode unattended --build_run 1

# Remove log file from bndiagnostic, which gets copied to the 'installer-logs' folder
rm -rf /opt/bitnami/bndiagnostic/original-data/installer-logs
