#!/bin/bash
#
# Description: Adds all 'bin' and 'sbin' folders inside '/opt/bitnami' to the PATH environment variable, for all users

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/liblog.sh

NEW_PATH=""
while IFS= read -r -d '' path; do
    info "Adding ${path} to PATH"
    NEW_PATH="${NEW_PATH:+"${NEW_PATH}:"}${path}"
done < <(find /opt/bitnami -maxdepth 3 -type d \( -name bin -o -name sbin \) -print0)

if [[ -z "$NEW_PATH" ]]; then
    warn "No paths were added to PATH"
    exit
fi

for rcfile in /root/{.bashrc,.profile} /home/*/{.bashrc,.profile} /etc/skel/{.bashrc,.profile}; do
    [[ -f "$rcfile" ]] && cat >>"$rcfile" <<EOF

# Bitnami environment settings
PATH="${NEW_PATH}:\$PATH"
EOF
done

cat >/etc/sudoers.d/99-bitnami-paths <<EOF
Defaults secure_path="${NEW_PATH}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
EOF

cat >/etc/profile.d/99-bitnami-paths.sh <<EOF
# Bitnami environment settings
PATH="${NEW_PATH}:\$PATH"
EOF
