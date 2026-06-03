# SpaghettiOS

A Debian-based Linux distribution themed around spaghetti.

> _"Life is a combination of magic and pasta." — Federico Fellini_

## 🍝 About

SpaghettiOS is a fork of Debian that brings the warmth, comfort, and delightful
messiness of spaghetti to your desktop. It aims to be as stable as Debian but
with a fun pasta-themed experience.

## Build Requirements

- Debian 12 (Bookworm) or later
- `live-build` — for ISO generation
- `aptly` — for repository management
- `debootstrap` — for bootstrapping
- `make` — for build automation

## Quick Start

```bash
# Install dependencies (Debian 12+)
sudo apt install live-build aptly debootstrap make xorriso \
  isolinux syslinux-utils grub-pc-bin grub-efi-amd64-bin

# Build the ISO
make build-iso

# The resulting ISO will be in build/iso/SpaghettiOS-amd64.iso
```

## Project Structure

```
SpaghettiOS/
├── branding/         # OS branding assets
│   ├── grub/        # GRUB theme
│   ├── plymouth/    # Boot splash
│   ├── wallpaper/   # Desktop backgrounds
│   ├── desktop/     # Desktop theme configs
│   └── login/       # Login screen branding
├── build/
│   ├── iso/         # ISO build scripts
│   ├── packages/    # Custom package build recipes
│   └── repo/        # Repository management
├── config/
│   ├── package-lists/  # Package selection lists
│   ├── hooks/          # Live-build hooks
│   └── archives/       # APT repository configurations
└── scripts/         # Build utility scripts
```

## Building Packages

```bash
# Build all custom packages
make packages

# Build a specific package
cd build/packages/spaghettios-base && dpkg-buildpackage -us -uc
```

## Managing the Repository

```bash
# Initialize the APT repository
make repo-init

# Add built packages to the repository
make repo-update

# Sign the repository
make repo-sign
```

## License

This project is licensed under the GNU General Public License v2,
following Debian's licensing model.
