#!/bin/bash
# SpaghettiOS Bootstrap Script
#
# Bootstraps a minimal SpaghettiOS system using debootstrap and
# configures the custom repository and branding.
#
# Usage:
#   sudo ./scripts/bootstrap.sh /target/directory
#
# This script creates a chroot environment that can be:
#   - Used as a base for container images
#   - Converted into a disk image
#   - Used for package development
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

TARGET="${1:-}"
CODENAME="bookworm"
MIRROR="http://deb.debian.org/debian"
VARIANT="minbase"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

if [ -z "$TARGET" ]; then
    log_error "Usage: $0 /target/directory"
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run as root (for debootstrap and chroot)."
    exit 1
fi

if [ -d "$TARGET" ] && [ -n "$(ls -A "$TARGET" 2>/dev/null)" ]; then
    log_error "Target directory $TARGET is not empty."
    exit 1
fi

log_info "Bootstrapping SpaghettiOS base system to $TARGET..."
log_info "Using Debian $CODENAME from $MIRROR"

# Bootstrap the base system
debootstrap --variant="$VARIANT" --arch=amd64 \
    --include=apt-transport-https,ca-certificates,curl,gnupg \
    "$CODENAME" "$TARGET" "$MIRROR"

# Set up SpaghettiOS repository
log_info "Configuring SpaghettiOS repository..."
mkdir -p "$TARGET/usr/share/keyrings"
if [ -f "$PROJECT_DIR/build/packages/spaghettios-release/key.asc" ]; then
    cp "$PROJECT_DIR/build/packages/spaghettios-release/key.asc" \
       "$TARGET/usr/share/keyrings/spaghettos-archive-keyring.gpg"
fi

cat > "$TARGET/etc/apt/sources.list.d/spaghettios.list" << APTEOF
deb [signed-by=/usr/share/keyrings/spaghettos-archive-keyring.gpg] http://mousecorp.xyz/spaghettios/repo al-dente main
APTEOF

# Create os-release
log_info "Setting up branding..."
cp "$PROJECT_DIR/branding/os-release" "$TARGET/usr/lib/os-release"
cp "$PROJECT_DIR/branding/login/issue" "$TARGET/etc/issue"
cp "$PROJECT_DIR/branding/login/issue.net" "$TARGET/etc/issue.net"

# Set hostname
echo "spaghettios" > "$TARGET/etc/hostname"
echo "127.0.0.1 localhost" > "$TARGET/etc/hosts"
echo "127.0.1.1 spaghettios" >> "$TARGET/etc/hosts"

# Run apt update in chroot
log_info "Updating package lists..."
chroot "$TARGET" apt-get update

# Install SpaghettiOS base
log_info "Installing SpaghettiOS base packages..."
chroot "$TARGET" apt-get install -y spaghettios-base || {
    log_warn "spaghettios-base not available (expected until repo is set up)."
    log_warn "Installing standard Debian base packages instead..."
    chroot "$TARGET" apt-get install -y --no-install-recommends \
        systemd systemd-sysv udev dbus sudo adduser bash
}

# Clean up
log_info "Cleaning up..."
chroot "$TARGET" apt-get clean
rm -rf "$TARGET/var/lib/apt/lists/*"
rm -f "$TARGET/etc/machine-id"
rm -f "$TARGET/var/log/"*.log

log_info "=== SpaghettiOS bootstrap complete! ==="
log_info "Target: $TARGET"
log_info ""
log_info "You can now enter the chroot:"
log_info "  sudo chroot $TARGET /bin/bash"
log_info ""
log_info "Or tar it up for a container:"
log_info "  sudo tar --numeric-owner -czf spaghettios-base.tar.gz -C $TARGET ."
