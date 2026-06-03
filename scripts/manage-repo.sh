#!/bin/bash
# SpaghettiOS Repository Manager
#
# Manages the APT repository for SpaghettiOS using aptly.
#
# Usage:
#   ./scripts/manage-repo.sh init      - Initialize the repository
#   ./scripts/manage-repo.sh update    - Add packages to the repository
#   ./scripts/manage-repo.sh sign      - Sign the repository
#   ./scripts/manage-repo.sh publish   - Publish the repository
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$PROJECT_DIR/build/repo"
GPG_KEY="SpaghettiOS Archive Signing Key"
DIST="al-dente"
COMPONENTS="main contrib non-free"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

check_aptly() {
    if ! command -v aptly &>/dev/null; then
        log_error "aptly is not installed."
        log_error "Install it: sudo apt install aptly"
        exit 1
    fi
}

cmd_init() {
    check_aptly
    log_info "Initializing aptly root in $REPO_DIR..."
    mkdir -p "$REPO_DIR"

    aptly repo create \
        -distribution="$DIST" \
        -component="$COMPONENTS" \
        "spaghettios"

    log_info "Repository 'spaghettios' initialized."
    log_info "Now build packages and run: $0 update"
}

cmd_update() {
    check_aptly
    log_info "Adding packages to repository..."
    find "$PROJECT_DIR/build/packages" -name "*.deb" -not -path "*/debian/*" | while read -r pkg; do
        log_info "Adding: $(basename "$pkg")"
        aptly repo add "spaghettios" "$pkg"
    done
    log_info "Packages added. Run '$0 sign' to sign the repository."
}

cmd_sign() {
    check_aptly
    log_info "Signing repository with key '$GPG_KEY'..."
    aptly publish repo \
        -gpg-key="$GPG_KEY" \
        -distribution="$DIST" \
        "spaghettios"
    log_info "Repository signed and published to $REPO_DIR/public/"
}

cmd_publish() {
    check_aptly
    log_info "Publishing repository..."
    aptly publish update "$DIST"
    log_info "Repository published."
}

cmd_help() {
    echo "SpaghettiOS Repository Manager"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  init      - Initialize the APT repository"
    echo "  update    - Add .deb packages from build/packages/"
    echo "  sign      - Sign and publish the repository"
    echo "  publish   - Update the published repository"
    echo "  help      - Show this help"
}

case "${1:-help}" in
    init)    cmd_init ;;
    update)  cmd_update ;;
    sign)    cmd_sign ;;
    publish) cmd_publish ;;
    help|*)  cmd_help ;;
esac
