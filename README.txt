Admin User Creation & Verification Scripts for macOS Recovery Mode

1. Boot into macOS Recovery (hold Cmd + R while booting).
2. Open Terminal from the menu bar (Utilities > Terminal).
3. Insert the USB drive containing these scripts.

To create the user:
  bash create_adminuser.sh

To verify the user:
  bash check_adminuser.sh

Legacy credentials (historical reference; the password is rejected for new accounts):
  Username: adminuser
  Password: Password123

The creation script now asks for a matching password of at least 12 characters.
It does not print it, and never overwrites an existing account.
Use an interactive Recovery Terminal. MOUNT_POINT can select the writable data
volume containing var/db/dslocal/nodes/Default. Use the same value for both scripts.
Local mocked tests do not validate Recovery compatibility, login or FileVault access.
See README.md for failure handling and limitations.
