#!/bin/bash
#
# Description: Resize the root partition at '/' if the actual disk size is bigger

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libcloud.sh
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libos.sh

DISK_SIZE="$(get_root_disk_size)"
STORED_DISK_SIZE="$(cloud_get_metadata disk_size)"
DISK_DEVICE_ID="$(get_disk_device_id)"
ROOT_DISK_DEVICE_ID="$(get_root_disk_device_id)"
# Get the numeric partition ID, used by 'growpart'
DISK_PARTITION_ID="$(grep -Eo '[0-9]+$' <<< "$DISK_DEVICE_ID")"

if [[ -z "$DISK_SIZE" || -z "$STORED_DISK_SIZE" ]]; then
    if [[ -z "$DISK_SIZE" ]]; then
        warn "Unable to resize partition: The disk size could not be retrieved properly"
    fi
    if [[ -z "$STORED_DISK_SIZE" ]]; then
        warn "Unable to resize partition: The root partition size could not be retrieved properly"
    fi
elif [[ "$DISK_SIZE" -le "$STORED_DISK_SIZE" ]]; then
    debug "The partition does not need to be resized"
else
    info "Expanding the main partition"
    growpart "$ROOT_DISK_DEVICE_ID" "$DISK_PARTITION_ID" || true

    info "Resizing the file system"
    if fsck -N "$ROOT_DISK_DEVICE_ID" | grep -q fsck.xfs; then
        xfs_growfs /
    else
        resize2fs -f "$DISK_DEVICE_ID"
    fi
fi
