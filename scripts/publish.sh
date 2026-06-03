#!/bin/bash
# SpaghettiOS Publish Script
#
# Uploads built packages and ISO to the mirror server.
#
# Usage:
#   ./scripts/publish.sh           # Upload packages and ISO
#   ./scripts/publish.sh --iso     # Upload ISO only
#   ./scripts/publish.sh --pkgs    # Upload packages only
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

MIRROR_HOST="ken@192.168.1.168"
MIRROR_ROOT="/var/www/mousecorp.xyz/spaghettios"
REPO_DIR="$MIRROR_ROOT/repo"
ISO_DIR="$MIRROR_ROOT/iso"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

upload_packages() {
    log_info "Uploading packages to mirror..."
    PKG_DIR="$PROJECT_DIR/build/packages"
    if [ -z "$(find "$PKG_DIR" -name "*.deb" 2>/dev/null | head -1)" ]; then
        log_warn "No .deb packages found in $PKG_DIR"
        log_info "Run 'make build-packages' first or place .deb files in build/packages/"
        return
    fi
    ssh "$MIRROR_HOST" "mkdir -p $REPO_DIR/pool/main"
    rsync -avz --progress "$PKG_DIR"/**/*.deb "$MIRROR_HOST:$REPO_DIR/pool/main/" 2>/dev/null || \
    find "$PKG_DIR" -name "*.deb" -exec scp {} "$MIRROR_HOST:$REPO_DIR/pool/main/" \;
    log_info "Packages uploaded. Updating repo metadata..."
    ssh "$MIRROR_HOST" "cd $REPO_DIR && apt-ftparchive packages . > dists/al-dente/main/binary-amd64/Packages && gzip -9 -c dists/al-dente/main/binary-amd64/Packages > dists/al-dente/main/binary-amd64/Packages.gz && apt-ftparchive release -c /tmp/apt-ftparchive.conf . > dists/al-dente/Release && gpg --batch --yes --pinentry-mode loopback --passphrase '' --detach-sign --armor -o dists/al-dente/Release.gpg dists/al-dente/Release && gpg --batch --yes --pinentry-mode loopback --passphrase '' --clearsign -o dists/al-dente/InRelease dists/al-dente/Release"
    log_info "Repository updated."
}

upload_iso() {
    log_info "Uploading ISO to mirror..."
    ISO_FILE=$(find "$PROJECT_DIR/build/iso" -name "SpaghettiOS-*.iso" -type f 2>/dev/null | head -1)
    if [ -z "$ISO_FILE" ]; then
        log_warn "No SpaghettiOS ISO found in build/iso/"
        return
    fi
    ssh "$MIRROR_HOST" "mkdir -p $ISO_DIR"
    scp "$ISO_FILE" "$MIRROR_HOST:$ISO_DIR/"
    log_info "ISO uploaded to $ISO_DIR/"
}

case "${1:-all}" in
    --iso|iso)     upload_iso ;;
    --pkgs|pkgs)   upload_packages ;;
    --all|all|*)   upload_packages; upload_iso ;;
esac

log_info "Done."
