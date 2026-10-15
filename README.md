# macOS Recovery Admin User Creator
Easily create and verify an admin user account on Intel-based Macs using Terminal in macOS Recovery Mode.

This repository provides two shell scripts to **create and verify an admin user account** on macOS while booted into **Recovery Mode**. Ideal for system administrators, repair techs, or advanced users needing to regain access or create fallback user accounts on Intel-based Macs.

## 🚀 Features

- Interactive password entry followed by automated creation of a new local admin user
- Checks the local directory database and refuses to overwrite an existing target account
- Selects the next unused local UID (at least 501)
- Sets login shell, home directory, and permissions
- Adds the user to the `admin` group (GID 80)
- Separate verification script checks:
  - Directory Services entry
  - Password status
  - Admin group membership
  - Home directory structure and permissions

## 📦 Contents

| File                   | Description                                      |
|------------------------|--------------------------------------------------|
| `create_adminuser.sh`  | Creates a new admin user                         |
| `check_adminuser.sh`   | Verifies user creation and configuration         |
| `README.md`            | Project overview and usage instructions          |
| `README.txt`           | Terminal-friendly version of instructions        |

## 🔧 Usage

1. Boot the target Mac into **Recovery Mode** (`Cmd + R` during startup).
2. Open **Terminal** from the menu bar (Utilities → Terminal).
3. Insert the USB drive containing these scripts.
4. Run the creation script:
```bash /Volumes/<YourUSB>/create_adminuser.sh```

5. (Optional) Run the verification script:
```bash /Volumes/<YourUSB>/check_adminuser.sh```

## 🔐 Password entry and legacy reference

* **Username**: `adminuser`
* **Password**: `Password123`

The password above is retained as a **historical reference only**. The creation script rejects it and requires a matching, hidden password entry of at least 12 characters. It never prints the new password. Existing accounts are left unchanged. Customize the username and full name in the script if needed.

Use `MOUNT_POINT="/Volumes/Your writable data volume" bash create_adminuser.sh` when the directory database is on a different volume. Use the same variable for the verifier. The selected volume must contain `var/db/dslocal/nodes/Default`; unlock and mount it first.

If a directory operation fails, the script stops and does not report success. A partial account may remain; inspect it before any retry. It will not automatically delete or overwrite that account.

Local tests mock directory operations; no macOS Recovery release has been validated by these tests. Creating a directory record does not establish FileVault unlock access, Secure Token enrollment, or successful login. The verifier checks metadata, not the password itself. `dscl` receives the password as a process argument during its short password-setting operation; use only a trusted Recovery session.

## 💡 Tip

Run from an interactive Recovery Terminal. Piped input is refused, and an existing target account is never overwritten. Do not run the creation script casually on a live installation.

## 📜 License

[MIT License](LICENSE)

## Offline checks

Run `bash -n create_adminuser.sh check_adminuser.sh` and `python3 -m unittest discover -s tests -v`. All account and filesystem mutation commands are mocked in tests.
