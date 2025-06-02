#!/bin/bash

# Script to verify the admin user was created successfully
# Run this from Terminal in Recovery Mode after running the creation script

# Configuration (should match your creation script)
MOUNT_POINT="/Volumes/Macintosh HD"
USERNAME="adminuser"

echo "=== Admin User Verification Script ==="
echo "Checking user: $USERNAME"
echo "Mount point: $MOUNT_POINT"
echo ""

if [ ! -d "$MOUNT_POINT" ]; then
    echo "❌ ERROR: $MOUNT_POINT not found. Make sure the disk is mounted."
    exit 1
fi

echo "✅ Volume is mounted at $MOUNT_POINT"
echo ""

USER_EXISTS=$(dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -list /Local/Default/Users | grep "^$USERNAME$")
if [ -n "$USER_EXISTS" ]; then
    echo "✅ User '$USERNAME' exists in directory services"
else
    echo "❌ User '$USERNAME' NOT found in directory services"
    exit 1
fi

echo ""
echo "--- User Details ---"
UID=$(dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -read /Local/Default/Users/$USERNAME UniqueID 2>/dev/null | awk '{print $2}')
GID=$(dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -read /Local/Default/Users/$USERNAME PrimaryGroupID 2>/dev/null | awk '{print $2}')
SHELL=$(dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -read /Local/Default/Users/$USERNAME UserShell 2>/dev/null | awk '{print $2}')
HOME=$(dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -read /Local/Default/Users/$USERNAME NFSHomeDirectory 2>/dev/null | awk '{print $2}')
REALNAME=$(dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -read /Local/Default/Users/$USERNAME RealName 2>/dev/null | cut -d' ' -f2-)

[ -n "$UID" ] && echo "✅ UID: $UID" || echo "❌ UID not set"
[ -n "$GID" ] && echo "✅ Primary GID: $GID" || echo "❌ Primary GID not set"
[ -n "$SHELL" ] && echo "✅ Shell: $SHELL" || echo "❌ Shell not set"
[ -n "$HOME" ] && echo "✅ Home Directory: $HOME" || echo "❌ Home Directory not set"
[ -n "$REALNAME" ] && echo "✅ Real Name: $REALNAME" || echo "❌ Real Name not set"

echo ""
echo "--- Password Verification ---"
PASSWD_HASH=$(dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -read /Local/Default/Users/$USERNAME AuthenticationAuthority 2>/dev/null)
[ -n "$PASSWD_HASH" ] && echo "✅ Password is set" || echo "❌ Password not set"

echo ""
echo "--- Admin Privileges Verification ---"
ADMIN_MEMBERS=$(dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -read /Local/Default/Groups/admin GroupMembership 2>/dev/null)
echo "$ADMIN_MEMBERS" | grep -q "$USERNAME" && echo "✅ User '$USERNAME' is member of admin group" || echo "❌ User '$USERNAME' is NOT member of admin group"

echo ""
echo "--- Home Directory Verification ---"
HOME_DIR="$MOUNT_POINT/Users/$USERNAME"
if [ -d "$HOME_DIR" ]; then
    echo "✅ Home directory exists: $HOME_DIR"
    for dir in Desktop Documents Downloads Movies Music Pictures Public Library; do
        [ -d "$HOME_DIR/$dir" ] && echo "✅ $dir directory exists" || echo "⚠️  $dir directory missing"
    done
    PERMS=$(stat -f "%p" "$HOME_DIR" 2>/dev/null | tail -c 4)
    [ "$PERMS" = "0755" ] || [ "$PERMS" = "755" ] && echo "✅ Home directory permissions are correct (755)" || echo "⚠️  Home directory permissions: $PERMS (should be 755)"
else
    echo "❌ Home directory does not exist: $HOME_DIR"
fi

echo ""
echo "--- System Users Overview ---"
echo "All local users found:"
dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -list /Local/Default/Users | grep -v "^_" | while read user; do
    user_uid=$(dscl -f "$MOUNT_POINT/var/db/dslocal/nodes/Default" localonly -read /Local/Default/Users/$user UniqueID 2>/dev/null | awk '{print $2}')
    if [ "$user_uid" -ge 500 ] 2>/dev/null; then
        [ "$user" = "$USERNAME" ] && echo "✅ $user (UID: $user_uid) - NEWLY CREATED" || echo "   $user (UID: $user_uid)"
    fi
done

echo ""
echo "=== Verification Complete ==="
echo ""
echo "If all checks show ✅, the user was created successfully!"
echo "You can now restart and log in with:"
echo "Username: $USERNAME"
echo "Password: Password123"
echo ""
echo "REMEMBER: Change the password after first login!"
