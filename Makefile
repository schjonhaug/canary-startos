# StartOS 0.3.5 Makefile for Canary
PKG_VERSION := $(shell yq e ".version" manifest.yaml)
PKG_ID := $(shell yq e ".id" manifest.yaml)

# Colors
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
NC := \033[0m

# Detect OS for SDK usage:
# - Linux: use native start-sdk (installed via prepare.sh)
# - macOS: use Docker-based SDK
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    START_SDK = start-sdk
else
    # macOS/other: use Docker-based SDK
    START_SDK = docker run --rm -v "$$(pwd):/pkg" -w /pkg start9-sdk:local
endif

.DELETE_ON_ERROR:

.PHONY: all arm x86 pack install clean sdk verify

# Default target - build for both architectures
all: $(PKG_ID).s9pk
	@echo ""
	@echo "$(GREEN)Build Complete!$(NC)"
	@echo ""
	@echo "Package: $(PKG_ID).s9pk"
	@echo "Version: $(PKG_VERSION)"
	@echo "Size:    $$(du -h $(PKG_ID).s9pk | cut -f1)"
	@echo ""

# Build for ARM64 only
arm: docker-images/aarch64.tar
	@echo "$(YELLOW)Packing s9pk (aarch64)...$(NC)"
	$(START_SDK) pack
	@echo "$(GREEN)Build Complete (aarch64)!$(NC)"

# Build for x86_64 only
x86: docker-images/x86_64.tar
	@echo "$(YELLOW)Packing s9pk (x86_64)...$(NC)"
	$(START_SDK) pack
	@echo "$(GREEN)Build Complete (x86_64)!$(NC)"

# Main package target - what Start9 expects to run: make canary.s9pk
$(PKG_ID).s9pk: sdk docker-images/aarch64.tar docker-images/x86_64.tar
	@echo "$(YELLOW)Packing s9pk...$(NC)"
	$(START_SDK) pack

# Alias for explicit pack command
pack: $(PKG_ID).s9pk

# Build the start-sdk Docker image (for macOS only)
sdk:
ifeq ($(UNAME_S),Linux)
	@echo "$(GREEN)Using native start-sdk$(NC)"
else
	@if ! docker image inspect start9-sdk:local >/dev/null 2>&1; then \
		echo "$(YELLOW)Building start-sdk Docker image (first time only)...$(NC)"; \
		docker build -t start9-sdk:local -f sdk.Dockerfile .; \
	fi
endif

# Build Docker image for x86_64
docker-images/x86_64.tar: Dockerfile scripts/docker_entrypoint.sh scripts/check-api.sh scripts/check-web.sh
	@echo "$(YELLOW)Building Docker image (x86_64)...$(NC)"
	mkdir -p docker-images
	docker buildx build \
		--tag start9/$(PKG_ID)/main:$(PKG_VERSION) \
		--build-arg CANARY_VERSION=v$(PKG_VERSION) \
		--platform=linux/amd64 \
		-o type=docker,dest=docker-images/x86_64.tar .

# Build Docker image for ARM64
docker-images/aarch64.tar: Dockerfile scripts/docker_entrypoint.sh scripts/check-api.sh scripts/check-web.sh
	@echo "$(YELLOW)Building Docker image (aarch64)...$(NC)"
	mkdir -p docker-images
	docker buildx build \
		--tag start9/$(PKG_ID)/main:$(PKG_VERSION) \
		--build-arg CANARY_VERSION=v$(PKG_VERSION) \
		--platform=linux/arm64 \
		-o type=docker,dest=docker-images/aarch64.tar .

# Verify the package
verify: $(PKG_ID).s9pk
	@echo "$(YELLOW)Verifying package...$(NC)"
	$(START_SDK) verify s9pk $(PKG_ID).s9pk
	@echo "$(GREEN)Verification passed!$(NC)"

# Install to StartOS device
install:
ifeq (,$(wildcard ~/.embassy/config.yaml))
	@echo "$(RED)Error: You must define 'host: http://server-name.local' in ~/.embassy/config.yaml first$(NC)"
else
	@echo "$(YELLOW)Installing to StartOS...$(NC)"
	$(START_SDK) package install $(PKG_ID).s9pk
endif

# Clean build artifacts
clean:
	rm -rf docker-images
	rm -f $(PKG_ID).s9pk
