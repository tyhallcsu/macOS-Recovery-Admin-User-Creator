#!/bin/bash

# Script to create a new admin user from macOS Recovery Mode
# Usage: Run this script from Terminal in Recovery Mode

# Disable tracing before handling passwords, even when invoked with bash -x.
set +x

# Configuration
MOUNT_POINT="${MOUNT_POINT:-/Volumes/Macintosh HD}"
USERNAME="adminuser"
LEGACY_PASSWORD="Password123" # Historical reference only; never an account default.
PASSWORD=""
FULL_NAME="Admin User"

request_password() {
    local confirmation
    if [ ! -t 0 ]; then
        echo "Error: use an interactive terminal to enter the new password." >&2
        return 1
    fi
    printf 'New administrator password (at least 12 characters): ' >&2
    IFS= read -r -s PASSWORD || return 1
    printf '\nConfirm password: ' >&2
    IFS= read -r -s confirmation || return 1
    printf '\n' >&2
    if [ "${#PASSWORD}" -lt 12 ] || [ "$PASSWORD" = "$LEGACY_PASSWORD" ] || [ "$PASSWORD" != "$confirmation" ]; then
        PASSWORD=''
        echo "Error: passwords must match, contain at least 12 characters, and differ from the legacy default." >&2
        return 1
    fi
}

main() {
    set -euo pipefail
    trap 'unset PASSWORD' EXIT
    local db_path existing_users next_uid home_dir
    db_path="$MOUNT_POINT/var/db/dslocal/nodes/Default"
    if [ ! -d "$db_path" ]; then
        echo "Error: local directory database not found on the selected volume." >&2
        return 1
    fi
    existing_users=$(dscl -f "$db_path" localonly -list /Local/Default/Users UniqueID)
    if printf '%s\n' "$existing_users" | awk '{print $1}' | grep -Fxq "$USERNAME"; then
        echo "Error: target account already exists; its password and record will not be modified." >&2
        return 1
    fi
    next_uid=$(printf '%s\n' "$existing_users" | awk '$2 ~ /^[0-9]+$/ && $2 > max {max=$2} END {print (max < 500 ? 501 : max+1)}')
    request_password
    echo "Creating admin user: $USERNAME on $MOUNT_POINT (UID $next_uid)"
    dscl -f "$db_path" localonly -create "/Local/Default/Users/$USERNAME"
    dscl -f "$db_path" localonly -create "/Local/Default/Users/$USERNAME" UserShell /bin/zsh
    dscl -f "$db_path" localonly -create "/Local/Default/Users/$USERNAME" RealName "$FULL_NAME"
    dscl -f "$db_path" localonly -create "/Local/Default/Users/$USERNAME" UniqueID "$next_uid"
    dscl -f "$db_path" localonly -create "/Local/Default/Users/$USERNAME" PrimaryGroupID 20
    dscl -f "$db_path" localonly -create "/Local/Default/Users/$USERNAME" NFSHomeDirectory "/Users/$USERNAME"
    dscl -f "$db_path" localonly -passwd "/Local/Default/Users/$USERNAME" "$PASSWORD"
    unset PASSWORD
    dscl -f "$db_path" localonly -append /Local/Default/Groups/admin GroupMembership "$USERNAME"
    home_dir="$MOUNT_POINT/Users/$USERNAME"
    mkdir -p "$home_dir"/{Desktop,Documents,Downloads,Movies,Music,Pictures,Public,Library}
    chown -R "$next_uid:20" "$home_dir"
    chmod 755 "$home_dir"
    chmod 700 "$home_dir/Library"
    echo "Created $USERNAME. Restart and use the password you entered; it is not printed or saved by this script."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
