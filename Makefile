SHELL := /bin/bash
ROOT_DIR := $(CURDIR)

.PHONY: all clean build-iso build-packages repo-init repo-update repo-sign

all: build-packages repo-update build-iso

# ============================================================================
# ISO Build
# ============================================================================
build-iso:
	@echo "==> Building SpaghettiOS ISO..."
	@sudo bash scripts/build-iso.sh
	@echo "==> ISO built: build/iso/"

# ============================================================================
# Package Build
# ============================================================================
build-packages:
	@echo "==> Building custom SpaghettiOS packages..."
	@for pkg in build/packages/*/; do \
		echo "Building $$pkg..."; \
		(cd "$$pkg" && dpkg-buildpackage -us -uc -b); \
	done

# ============================================================================
# Repository Management
# ============================================================================
repo-init:
	@echo "==> Initializing APT repository..."
	@bash scripts/manage-repo.sh init

repo-update:
	@echo "==> Updating repository..."
	@bash scripts/manage-repo.sh update

repo-sign:
	@echo "==> Signing repository..."
	@bash scripts/manage-repo.sh sign

# ============================================================================
# Cleanup
# ============================================================================
clean:
	@echo "==> Cleaning build artifacts..."
	@rm -rf build/iso/*.iso build/iso/live-build
	@rm -rf build/packages/*/debian/.deb-builder
	@echo "Done."

distclean: clean
	@echo "==> Full cleanup..."
	@rm -rf build/repo
	@echo "Done."
