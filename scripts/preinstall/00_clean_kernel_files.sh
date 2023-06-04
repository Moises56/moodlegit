#!/bin/bash
#
# Description: Clean old kernels

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

# Helper functions
get_kernels_to_remove() {
    find /boot -type f -name 'initrd.img-*' -exec basename {} \; | sed 's/^initrd\.img/linux-image/' | sort | head -n -1 | xargs
}
get_latest_kernel_version() {
    find /boot -type f -name 'initrd.img-*' -exec basename {} \; | sed 's/^initrd\.img-//' | sort | tail -n 1
}

# Clean old and unused kernels
read -r -a KERNELS_TO_REMOVE <<< "$(get_kernels_to_remove)"
if [[ "${#KERNELS_TO_REMOVE[@]}" -gt 0 ]]; then
    info "Removing old kernels: ${KERNELS_TO_REMOVE[*]}"
    DEBIAN_FRONTEND=noninteractive apt-get autoremove --purge -y "${KERNELS_TO_REMOVE[@]}"
    update-grub2
fi

# Strip kernel modules and regenerate initrd, to reduce their size
info "Optimizing kernel modules and initrd"
find "/lib/modules/$(get_latest_kernel_version)" -name '*.ko' -exec strip --strip-unneeded {} +
sudo update-initramfs -c -k "$(get_latest_kernel_version)"
