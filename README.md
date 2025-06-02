# macOS Recovery Admin User Creator
Easily create and verify an admin user account on Intel-based Macs using Terminal in macOS Recovery Mode.

This repository provides two robust shell scripts to **create and verify an admin user account** on macOS while booted into **Recovery Mode**. Ideal for system administrators, repair techs, or advanced users needing to regain access or create fallback user accounts on Intel-based Macs.

## 🚀 Features

- Fully automated creation of a new local admin user
- Safe operation from Recovery Mode with volume checks
- Dynamically assigns correct UID
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

## 🔐 Default Credentials

* **Username**: `adminuser`
* **Password**: `Password123`

You can customize these by editing the `create_adminuser.sh` script before deployment.

> ⚠️ For security, it is strongly recommended to change the password upon first login.

## 💡 Tip

You can rename the scripts to `.command` files and add `chmod +x` to make them double-clickable in Finder on a live system.

## 📜 License

[MIT License](LICENSE)
