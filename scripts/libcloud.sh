#!/bin/bash
#
# Bitnami Cloud library

# shellcheck disable=SC1091,SC2001

# Load Generic Libraries
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libos.sh
. /opt/bitnami/scripts/libvalidations.sh

########################
# Set a metadata value
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#########################
cloud_set_metadata() {
    local -r root_data_dir="/var/lib/bitnami/metadata"
    local -r key="${1:?missing key}"
    local -r value="${2:?missing value}"
    local data_dir
    data_dir="$(dirname "${root_data_dir}/${key}")"
    if [[ "$data_dir" != "$root_data_dir" ]]; then
        mkdir -p "$root_data_dir"
    fi
    mkdir -p "$data_dir"
    cat >"${root_data_dir}/${key}" <<<"$value"
    chmod -R 600 "$root_data_dir"
}

########################
# Get a metadata value
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   The metadata value
#########################
cloud_get_metadata() {
    local -r data_dir="/var/lib/bitnami/metadata"
    local -r key="${1:?missing key}"
    if [[ -f "${data_dir}/${key}" ]]; then
        cat "${data_dir}/${key}"
    fi
}

########################
# Generate random password
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#########################
cloud_generate_credential() {
    local -r key="${1:?missing key}"
    local length="${2:-}"
    local password
    # Password requirements
    # Using alphanumeric by default, since only a few require special characters
    local password_type="alphanumeric"
    # Set a default length, if it was not specified
    if [[ -z "$length" ]]; then
        if [[ "$key" = "bitnami_application_password" ]]; then
            # Limit the amount of characters of the main instance password for usability reasons
            length="12"
            # Process password requirements from image metadata (e.g. 'alphanumeric+special')
            if [[ -n "$(cloud_get_metadata "credential_requirements")" ]]; then
                password_type="$(cloud_get_metadata "credential_requirements")"
            fi
        else
            length="64"
        fi
    fi
    # Try to get from user-data
    password="$(cloud_get_value_from_user_data "$key")"
    # Try to get from metadata store
    if [[ -z "$password" ]]; then
        password="$(cloud_get_metadata "credentials/${key}")"
    fi
    # Generate it if it was not specified in the user-data, nor in the metadata store
    if [[ -z "$password" ]]; then
        warn "The ${key} option was not provided with user-data, a random value will be generated for it"
        # Generate a new random password following the password requirements
        while [[ "+${password_type}+" = *"+numeric+"* && ! "$password" =~ [0-9] ]] \
            || [[ "+${password_type}+" = *"+lowercase+"* && ! "$password" =~ [a-z] ]] \
            || [[ "+${password_type}+" = *"+uppercase+"* && ! "$password" =~ [a-z] ]] \
            || [[ "+${password_type}+" = *"+alphanumeric+"* && ! "$password" =~ [0-9] ]] \
            || [[ "+${password_type}+" = *"+alphanumeric+"* && ! "$password" =~ [a-z] ]] \
            || [[ "+${password_type}+" = *"+alphanumeric+"* && ! "$password" =~ [A-Z] ]] \
            || [[ "+${password_type}+" = *"+special+"* && ! "$password" =~ [!@#$%^] ]]
        do
            password="$(generate_random_string -t "$password_type" -c "$length")"
        done
    fi
    cloud_set_metadata "credentials/${key}" "$password"
    echo "$password"
}

########################
# Get a parameter from user data
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   The value of the parameter
#########################
cloud_get_value_from_user_data() {
    local -r parameter="${1:?missing parameter}"
    local user_data
    user_data="$(cloud_get_user_data)"
    local line
    line="$(grep -E "^(\s*#\s*|^)(${parameter})\s*=" <<<"$user_data" | head -1)"
    if [[ -z "$line" ]]; then
        return 1
    fi
    # remove a leading '#' (if it is the first non-whitespace character), trailing spaces and quote marks around values
    echo "$line" | sed -E -e "s/^\s*#\s*//g" -e "s/${parameter}\s*=\s*//g" -e "s/\s*$//g" -e "s/^\"(.*)\"$/\1/"
}

########################
# Get OVF environment parameter
# Globals:
#   None
# Arguments:
#   $1 - Parameter key
# Returns:
#   The contents of the parameter
#########################
cloud_get_ovf_env_parameter() {
    local parameter_key="${1:?missing parameter key}"
    local ovf_env ovf_env_parameters
    if ovf_env="$(vmtoolsd --cmd 'info-get guestinfo.ovfEnv' 2>/dev/null)"; then
        ovf_env_parameters="$(xmllint --format --xpath "//*[local-name() = 'PropertySection']/*[local-name() = 'Property']" - <<< "$ovf_env")"
        local -r user_data_pattern=".*key=\"${parameter_key}\"[^>]*value=\"([^\"]+)\".*"
        if grep -Eqs "$user_data_pattern" <<< "$ovf_env_parameters"; then
            grep -Eo "$user_data_pattern" <<< "$ovf_env_parameters" | sed -E "s/${user_data_pattern}/\1/g"
        fi
    fi
}

########################
# Get user data
# Globals:
#   None
# Arguments:
#   $1 - Path to the user data file
# Returns:
#   The contents of the user data
#########################
cloud_get_user_data() {
    local -r user_data_file="${1:-"/var/lib/bitnami/user-data.txt"}"
    local -r timestamp_file="${user_data_file}.timestamp"
    local boot_time
    boot_time="$(get_boot_time)"
    if [[ ! -f "$timestamp_file" || "$(cat "$timestamp_file")" != "$boot_time" ]]; then
        cloud_get_ovf_env_parameter user-data | base64 -d > "$user_data_file"
        cat <<<"$boot_time" >"$timestamp_file"
    fi
    if [[ -f "$user_data_file" ]]; then
        cat "$user_data_file"
    fi
}

########################
# Get a machine IP address
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   The machine IP address
#########################
cloud_get_machine_ip_address() {
    ip route get 1 | sed -n -E 's/.* src ([^ ]+).*/\1/p'
}

########################
# Generates a 'firstboot-env.sh' file from a 'firstboot-env.txt' input file
# Globals:
#   None
# Arguments:
#   $1..$n - Environment variables declarations, e.g. NAME=value
# Returns:
#   Path to the 'firstboot-env.sh' file
#########################
cloud_firstboot_environment_file() {
    local -r firstboot_env_file_input="/var/lib/bitnami/firstboot-env.txt"
    local -r firstboot_env_file_output="/var/lib/bitnami/firstboot-env.sh"
    if [[ ! -f "$firstboot_env_file_output" ]]; then
        local -r env_var_pattern="^([^=]+)=(.*)"
        local env_var_name env_var_value env_var_value_generator
        echo "#!/bin/bash" > "$firstboot_env_file_output"
        echo ". /opt/bitnami/scripts/bitnami-env.sh" >> "$firstboot_env_file_output"
        while read -r line; do
            if grep -Eq "$env_var_pattern" <<< "$line"; then
                env_var_name="$(sed -E "s/${env_var_pattern}/\1/" <<< "$line")"
                env_var_value="$(sed -E "s/${env_var_pattern}/\2/" <<< "$line")"
                if [[ "$env_var_value" =~ ^credential: ]]; then
                    env_var_value_generator="$(sed 's/^credential://g' <<< "$env_var_value")"
                    env_var_value="$(cloud_generate_credential "$env_var_value_generator")"
                fi
                # Escape the value, so it can be parsed as a variable even with quotes set
                # In addition, use single quotes to avoid shell expansion
                env_var_value="${env_var_value//\'/\'\\\'\'}"
                echo "export ${env_var_name}='${env_var_value}'"
            fi
        done <<< "$(cat "$firstboot_env_file_input")" >> "$firstboot_env_file_output"
        # Note: Using 'cat' to avoid envvars being skipped when the input file lacks a newline in the end of the file
    fi
    echo "$firstboot_env_file_output"
}

########################
# Execute all first-boot scripts
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#########################
cloud_execute_firstboot_scripts() {
    if grep -Eq "^\s*SKIP_FIRST_BOOT\s*=\s*([\"']?)(1|true|yes)\1\s*$" <<< "$(cloud_get_user_data /dev/null)"; then
        warn "Skipping initialization due to SKIP_FIRST_BOOT=1"
        # Reset cloud-init environment, so that it gets re-executed in the next boot
        cloud-init clean
        # Temporarily enable login screen so that the user can connect to the machine
        mv /etc/no-login-console /etc/no-login-console.back
        sleep 5
        mv /etc/no-login-console.back /etc/no-login-console
    elif [[ -d "/opt/bitnami/scripts/firstboot" ]]; then
        # shellcheck disable=SC1090
        . "$(cloud_firstboot_environment_file)"
        # In case of error in any script, exit with 255 so xargs can interpret it as a stop signal
        if ! find /opt/bitnami/scripts/firstboot -type f -name '*.sh' -print0 | sort -z | xargs -0 -I@ bash -c "bash -e @ || exit 255"; then
            if [[ -d "/opt/bitnami/scripts/firstboot-failure" ]]; then
                find /opt/bitnami/scripts/firstboot-failure -type f -name '*.sh' -print0 | sort -z | xargs -0 -I@ bash -c "bash -e @ || exit 255"
            else
                debug "There are no first-boot-failure scripts to execute"
            fi
            exit 1
        fi
    else
        debug "There are no first-boot scripts to execute"
    fi
}

########################
# Execute all pre-start scripts
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#########################
cloud_execute_prestart_scripts() {
    if [[ -d "/opt/bitnami/scripts/prestart" ]]; then
        # In case of error in any script, exit with 255 so xargs can interpret it as a stop signal
        find /opt/bitnami/scripts/prestart -type f -name '*.sh' -print0 | sort -z | xargs -0 -I@ bash -c "bash -e @ || exit 255"
    else
        debug "There are no pre-start scripts to execute"
    fi
}

########################
# Execute all application scripts for updating memory configurations
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#########################
cloud_execute_resize_config_scripts() {
    local current_memory_amount previous_memory_amount
    current_memory_amount="$(get_total_memory)"
    if [[ -z "$current_memory_amount" ]]; then
        error "Could not detect total memory amount"
        return 1
    fi
    previous_memory_amount="$(cloud_get_metadata memory)"
    if [[ "$current_memory_amount" != "$previous_memory_amount" ]]; then
        info "Updating memory configurations to ${current_memory_amount}M"
        # In case of error in any script, exit with 255 so xargs can interpret it as a stop signal
        find /opt/bitnami/scripts/resize -type f -name '*.sh' -print0 | sort -z | xargs -0 -I@ bash -c "bash -e @ --memory '${current_memory_amount}' || exit 255"
        cloud_set_metadata memory "$current_memory_amount"
    else
        debug "The total memory amount has not changed"
    fi
}

########################
# Execute all application scripts for updating the machine hostname/domain
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#########################
cloud_execute_hostname_config_scripts() {
    local current_hostname previous_hostname
    if [[ -f /opt/bitnami/.app_domain_disabled ]]; then
        warn "Automatic application hostname configuration has been disabled by the user"
        return
    fi
    if [[ -f /opt/bitnami/.app_domain ]]; then
        info "The application domain has been configured by the user"
        current_hostname="$(cat /opt/bitnami/.app_domain)"
    else
        current_hostname="$(cloud_get_machine_ip_address || true)"
    fi
    if [[ -z "$current_hostname" ]]; then
        error "Could not detect current machine hostname"
        return 1
    fi
    previous_hostname="$(cloud_get_metadata hostname)"
    if [[ "$current_hostname" != "$previous_hostname" ]]; then
        info "Updating application hostname to ${current_hostname}"
        # In case of error in any script, exit with 255 so xargs can interpret it as a stop signal
        find /opt/bitnami/scripts/updatehost -type f -name '*.sh' -print0 | sort -z | xargs -0 -I@ bash -c "bash -e @ '${current_hostname}' || exit 255"
        cloud_set_metadata hostname "$current_hostname"
    else
        debug "The hostname has not changed"
    fi
    if [[ -f /opt/bitnami/.app_domain_disabling ]]; then
        rm -f /opt/bitnami/.app_domain_disabling
        touch /opt/bitnami/.app_domain_disabled
    fi
}
