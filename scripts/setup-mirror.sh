#!/bin/bash
# SpaghettiOS Mirror Setup
#
# Initializes the APT repository on the mirror server.
# Run this once after the mirror directories exist.
#
# Usage:
#   ./scripts/setup-mirror.sh
#

set -euo pipefail

MIRROR_HOST="ken@192.168.1.168"
MIRROR_ROOT="/var/www/mousecorp.xyz/spaghettios"
REPO_DIR="$MIRROR_ROOT/repo"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

log_info "Setting up SpaghettiOS mirror on $MIRROR_HOST..."

ssh "$MIRROR_HOST" bash << 'REMOTE'
set -euo pipefail

REPO_DIR="/var/www/mousecorp.xyz/spaghettios/repo"

# Create directory structure
mkdir -p "$REPO_DIR/dists/al-dente/main/binary-amd64"
mkdir -p "$REPO_DIR/dists/al-dente/main/source"
mkdir -p "$REPO_DIR/pool/main"

# Create apt-ftparchive config
cat > /tmp/apt-ftparchive.conf << 'CONF'
APT::FTPArchive::Release {
  Origin 'SpaghettiOS';
  Label 'SpaghettiOS';
  Suite 'al-dente';
  Codename 'al-dente';
  Architectures 'amd64 source';
  Components 'main';
  Description 'SpaghettiOS APT Repository';
};
CONF

# Generate or verify GPG key
if ! gpg --list-keys 'SpaghettiOS Archive Signing Key' &>/dev/null; then
    gpg --batch --pinentry-mode loopback --passphrase '' --quick-generate-key \
        'SpaghettiOS Archive Signing Key (SpaghettiOS) <devel@spaghettios.local>' rsa4096 default 0
fi

# Export public key
gpg --export --armor 'SpaghettiOS Archive Signing Key' > "$REPO_DIR/key.asc"
gpg --export 'SpaghettiOS Archive Signing Key' > "$REPO_DIR/key.gpg"

# Generate initial repo metadata
apt-ftparchive packages . > "$REPO_DIR/dists/al-dente/main/binary-amd64/Packages"
gzip -9 -c "$REPO_DIR/dists/al-dente/main/binary-amd64/Packages" > "$REPO_DIR/dists/al-dente/main/binary-amd64/Packages.gz"
apt-ftparchive release -c /tmp/apt-ftparchive.conf . > "$REPO_DIR/dists/al-dente/Release"

# Sign Release files
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
    --detach-sign --armor -o "$REPO_DIR/dists/al-dente/Release.gpg" "$REPO_DIR/dists/al-dente/Release"
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
    --clearsign -o "$REPO_DIR/dists/al-dente/InRelease" "$REPO_DIR/dists/al-dente/Release"

echo "Mirror setup complete."
echo "Public key: $REPO_DIR/key.asc"
echo "Repository: $REPO_DIR"
REMOTE

log_info "Mirror setup complete on $MIRROR_HOST"
