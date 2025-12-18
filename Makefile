# StartOS 0.3.5 Makefile for Canary
PKG_VERSION := $(shell yq e ".version" manifest.yaml)
PKG_ID := $(shell yq e ".id" manifest.yaml)

# Colors
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
NC := \033[0m

# start-sdk runs in Docker since it requires Linux
define START_SDK
docker run --rm -v "$$(pwd):/pkg" -w /pkg start9-sdk:local $(1)
endef

.DELETE_ON_ERROR:

.PHONY: all arm x86 pack install clean sdk

# Default target - build for both architectures
all: pack
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
	$(call START_SDK,pack)
	@echo "$(GREEN)Build Complete (aarch64)!$(NC)"

# Build for x86_64 only
x86: docker-images/x86_64.tar
	@echo "$(YELLOW)Packing s9pk (x86_64)...$(NC)"
	$(call START_SDK,pack)
	@echo "$(GREEN)Build Complete (x86_64)!$(NC)"

# Pack with both architectures
pack: sdk docker-images/aarch64.tar docker-images/x86_64.tar
	@echo "$(YELLOW)Packing s9pk...$(NC)"
	$(call START_SDK,pack)

# Build the start-sdk Docker image (one-time setup)
sdk:
	@if ! docker image inspect start9-sdk:local >/dev/null 2>&1; then \
		echo "$(YELLOW)Building start-sdk Docker image (first time only)...$(NC)"; \
		docker build -t start9-sdk:local -f sdk.Dockerfile .; \
	fi

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

# Install to StartOS device
install:
ifeq (,$(wildcard ~/.embassy/config.yaml))
	@echo "$(RED)Error: You must define 'host: http://server-name.local' in ~/.embassy/config.yaml first$(NC)"
else
	@echo "$(YELLOW)Installing to StartOS...$(NC)"
	$(call START_SDK,package install $(PKG_ID).s9pk)
endif

# Clean build artifacts
clean:
	rm -rf docker-images
	rm -f $(PKG_ID).s9pk
