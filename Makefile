# StartOS 0.3.5 Makefile for Canary
PKG_VERSION := $(shell yq e ".version" manifest.yaml)
PKG_ID := $(shell yq e ".id" manifest.yaml)
TS_FILES := $(shell find ./scripts -name '*.ts')

# Colors
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
NC := \033[0m

.DELETE_ON_ERROR:

.PHONY: all arm x86 verify install clean

# Default target - build for both architectures
all: verify
	@echo ""
	@echo "$(GREEN)Build Complete!$(NC)"
	@echo ""
	@echo "Package: $(PKG_ID).s9pk"
	@echo "Version: $(PKG_VERSION)"
	@echo "Size:    $$(du -h $(PKG_ID).s9pk | cut -f1)"
	@echo ""

# Build for ARM64 only
arm: docker-images/aarch64.tar scripts/embassy.js
	@echo "$(YELLOW)Packing s9pk (aarch64)...$(NC)"
	start-sdk pack
	@echo "$(GREEN)Build Complete (aarch64)!$(NC)"

# Build for x86_64 only
x86: docker-images/x86_64.tar scripts/embassy.js
	@echo "$(YELLOW)Packing s9pk (x86_64)...$(NC)"
	start-sdk pack
	@echo "$(GREEN)Build Complete (x86_64)!$(NC)"

# Verify and pack
verify: $(PKG_ID).s9pk
	@start-sdk verify s9pk $(PKG_ID).s9pk
	@echo "$(GREEN)Verification passed!$(NC)"

# Create the s9pk package
$(PKG_ID).s9pk: manifest.yaml instructions.md LICENSE icon.png scripts/embassy.js docker-images/aarch64.tar docker-images/x86_64.tar
	@echo "$(YELLOW)Packing s9pk...$(NC)"
	start-sdk pack

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

# Bundle Deno scripts
scripts/embassy.js: $(TS_FILES)
	@echo "$(YELLOW)Bundling Deno scripts...$(NC)"
	deno run --allow-read --allow-write --allow-env --allow-net scripts/bundle.ts

# Install to StartOS device
install:
ifeq (,$(wildcard ~/.embassy/config.yaml))
	@echo "$(RED)Error: You must define 'host: http://server-name.local' in ~/.embassy/config.yaml first$(NC)"
else
	@echo "$(YELLOW)Installing to StartOS...$(NC)"
	start-cli package install $(PKG_ID).s9pk
endif

# Clean build artifacts
clean:
	rm -rf docker-images
	rm -f scripts/embassy.js
	rm -f $(PKG_ID).s9pk
