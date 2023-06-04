#!/bin/bash
#
# Description: Enable swap if the system is low on memory, remove it otherwise

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libcloud.sh
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libos.sh

SWAP_DIR="/mnt"
SWAP_FILE="${SWAP_DIR}/.bitnami.swap"
SWAP_SIZE="665600" # 650M

if [[ "$(get_machine_size "$@")" = "micro" ]]; then
    FREE_SPACE_FOR_SWAP="$(df -kP "$SWAP_DIR" | tail -1 | awk '{print $4}')"
    if ! swapon --show | grep -q "$SWAP_FILE"; then
        if [[ "$FREE_SPACE_FOR_SWAP" -gt "$SWAP_SIZE" ]]; then
            info "Generating swapfile"
            rm -f "$SWAP_FILE"
            dd if=/dev/zero of="$SWAP_FILE" bs=1K count="$SWAP_SIZE"
            chmod 600 "$SWAP_FILE"
            mkswap "$SWAP_FILE"
            swapon "$SWAP_FILE"
        else
            warn "There is not enough space to generate a swapfile, it will be skipped"
        fi
    fi
elif [[ -e "$SWAP_FILE" ]]; then
    info "Swap file is not needed, it will be removed"
    swapoff "$SWAP_FILE" || true
    rm -f "$SWAP_FILE" || true
fi
