#!/bin/bash
# SpaghettiOS ISO Builder
#
# Builds a live ISO using live-build with SpaghettiOS branding and packages.
#
# Usage:
#   ./scripts/build-iso.sh [--clean] [--debug]
#
# Requirements:
#   - live-build
#   - debootstrap
#   - xorriso
#   - isolinux, syslinux-utils
#   - grub-pc-bin, grub-efi-amd64-bin
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build/iso"
LB_DIR="$BUILD_DIR/live-build"

CODENAME="bookworm"
DISTRO="SpaghettiOS"
VERSION="1.0"
ARCH="amd64"
MIRROR="http://deb.debian.org/debian"
MIRROR_SECURITY="http://security.debian.org/debian-security"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
fi

cleanup() {
    log_info "Cleaning up previous build..."
    rm -rf "$LB_DIR"
}

build_iso() {
    log_info "Starting SpaghettiOS ISO build (${DISTRO} ${VERSION}, ${ARCH})..."

    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    # Initialize live-build configuration
    lb config \
        --parent-distribution "$CODENAME" \
        --distribution "$CODENAME" \
        --architectures "$ARCH" \
        --archive-areas "main contrib non-free" \
        --debian-installer false \
        --bootappend-live "boot=live components quiet splash hostname=spaghettios" \
        --iso-application "${DISTRO} ${VERSION}" \
        --iso-preparer "${DISTRO} Developers" \
        --iso-publisher "${DISTRO} Developers" \
        --iso-volume "${DISTRO} ${VERSION}" \
        --mirror-bootstrap "$MIRROR" \
        --mirror-chroot "$MIRROR" \
        --mirror-chroot-security "$MIRROR_SECURITY" \
        --mirror-binary "$MIRROR" \
        --mirror-binary-security "$MIRROR_SECURITY" \
        --keyring-packages "debian-archive-keyring" \
        --clean

    # Set hostname and hosts in the live image
    mkdir -p "$LB_DIR/config/includes.chroot/etc"
    echo "spaghettios" > "$LB_DIR/config/includes.chroot/etc/hostname"
    cat > "$LB_DIR/config/includes.chroot/etc/hosts" << 'EOF'
127.0.0.1	localhost
127.0.1.1	spaghettios
EOF

    # Copy custom package lists
    log_info "Copying package lists..."
    if [ -d "$PROJECT_DIR/config/package-lists" ]; then
        cp -r "$PROJECT_DIR/config/package-lists/"* "$LB_DIR/config/package-lists/" 2>/dev/null || true
    fi

    # Copy custom hooks
    log_info "Copying hooks..."
    if [ -d "$PROJECT_DIR/config/hooks" ]; then
        cp -r "$PROJECT_DIR/config/hooks/"* "$LB_DIR/config/hooks/" 2>/dev/null || true
        chmod +x "$LB_DIR/config/hooks/"* 2>/dev/null || true
    fi

    # Copy archive configs
    log_info "Copying archive configs..."
    if [ -d "$PROJECT_DIR/config/archives" ]; then
        cp -r "$PROJECT_DIR/config/archives/"* "$LB_DIR/config/archives/" 2>/dev/null || true
    fi

    # Build the ISO
    log_info "Running live-build (this will take a while)..."
    $SUDO lb build 2>&1 | tee "$BUILD_DIR/build.log"

    # Rename the resulting ISO
    if [ -f "$LB_DIR/live-image-${ARCH}.hybrid.iso" ]; then
        mv "$LB_DIR/live-image-${ARCH}.hybrid.iso" \
           "$BUILD_DIR/${DISTRO}-${VERSION}-${ARCH}.iso"
        log_info "ISO built successfully:"
        log_info "  $BUILD_DIR/${DISTRO}-${VERSION}-${ARCH}.iso"
    else
        log_error "ISO build failed. Check $BUILD_DIR/build.log for details."
        exit 1
    fi
}

# Parse arguments
CLEAN=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean) CLEAN=true; shift ;;
        --debug) set -x; shift ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
done

if [ "$CLEAN" = true ]; then
    cleanup
fi

build_iso
