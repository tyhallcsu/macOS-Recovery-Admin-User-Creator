#!/bin/bash

# Script to create a new admin user from macOS Recovery Mode
# Usage: Run this script from Terminal in Recovery Mode

# Configuration
MOUNT_POINT="/Volumes/Macintosh HD"
USERNAME="adminuser"
PASSWORD="Password123"
FULL_NAME="Admin User"

echo "Creating admin user: $USERNAME"
echo "Mount point: $MOUNT_POINT"

# Check if the volume is mounted
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Error: $MOUNT_POINT not found. Make sure the disk is mounted."
    exit 1
fi

# Find the next available UID (starting from 501)
NEXT_UID=$(dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -list /Local/Default/Users UniqueID | awk '{print $2}' | sort -n | tail -1)
NEXT_UID=$((NEXT_UID + 1))

# If no users exist, start with 501
if [ -z "$NEXT_UID" ] || [ "$NEXT_UID" -lt 501 ]; then
    NEXT_UID=501
fi

echo "Assigning UID: $NEXT_UID"

# Create the user record
dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -create /Local/Default/Users/$USERNAME
dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -create /Local/Default/Users/$USERNAME UserShell /bin/zsh
dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -create /Local/Default/Users/$USERNAME RealName "$FULL_NAME"
dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -create /Local/Default/Users/$USERNAME UniqueID $NEXT_UID
dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -create /Local/Default/Users/$USERNAME PrimaryGroupID 20
dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -create /Local/Default/Users/$USERNAME NFSHomeDirectory /Users/$USERNAME

# Set the password
dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -passwd /Local/Default/Users/$USERNAME "$PASSWORD"

# Add user to admin group (GID 80)
dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -append /Local/Default/Groups/admin GroupMembership $USERNAME

# Create home directory structure
HOME_DIR="$MOUNT_POINT/Users/$USERNAME"
mkdir -p "$HOME_DIR"/{Desktop,Documents,Downloads,Movies,Music,Pictures,Public,Library}

# Set proper ownership and permissions
chown -R $NEXT_UID:20 "$HOME_DIR"
chmod 755 "$HOME_DIR"
chmod 700 "$HOME_DIR/Library"

echo "Successfully created admin user: $USERNAME"
echo "UID: $NEXT_UID"
echo "Home directory: /Users/$USERNAME"
echo "User has been added to admin group"
echo ""
echo "You can now restart and log in with:"
echo "Username: $USERNAME"
echo "Password: $PASSWORD"
echo ""
echo "IMPORTANT: Change the password after first login for security!"
