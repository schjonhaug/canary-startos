# Extract package info from manifest.ts
PKG_ID := canary
PKG_VERSION := $(shell node -e "const m = require('./build/index.js'); console.log(m.manifest.version.replace(':','.'));" 2>/dev/null || echo "0.1.0.0")
PKG_TITLE := $(shell node -e "const m = require('./build/index.js'); console.log(m.manifest.title);" 2>/dev/null || echo "Canary")
SDK_VERSION := $(shell npm list @start9labs/start-sdk --json 2>/dev/null | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).dependencies['@start9labs/start-sdk'].version)}catch(e){console.log('unknown')}})")
GIT_HASH := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_DIRTY := $(shell git diff --quiet 2>/dev/null || echo "-dirty")

# Colors
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
NC := \033[0m

.DELETE_ON_ERROR:

.PHONY: all aarch64 x86_64 arm x86 install clean check-deps check-init package

# Default target
all: package
	@echo ""
	@echo "$(GREEN)✅ Build Complete!$(NC)"
	@echo ""
	@echo "📦 $(PKG_TITLE)   v$(PKG_VERSION)"
	@echo "───────────────────────────"
	@echo " Filename:   $(PKG_ID).s9pk"
	@echo " Size:       $$(du -h $(PKG_ID).s9pk | cut -f1)"
	@echo " Arch:       universal"
	@echo " SDK:        $(SDK_VERSION)"
	@echo " Git:        $(GIT_HASH)$(GIT_DIRTY)"
	@echo ""

aarch64: BUILD=aarch64
aarch64: package
	@echo ""
	@echo "$(GREEN)✅ Build Complete!$(NC)"
	@echo ""
	@echo "📦 $(PKG_TITLE)   v$(PKG_VERSION)"
	@echo "───────────────────────────"
	@echo " Filename:   $(PKG_ID)_aarch64.s9pk"
	@echo " Size:       $$(du -h $(PKG_ID)_aarch64.s9pk | cut -f1)"
	@echo " Arch:       aarch64"
	@echo " SDK:        $(SDK_VERSION)"
	@echo " Git:        $(GIT_HASH)$(GIT_DIRTY)"
	@echo ""

x86_64: BUILD=x86_64
x86_64: package
	@echo ""
	@echo "$(GREEN)✅ Build Complete!$(NC)"
	@echo ""
	@echo "📦 $(PKG_TITLE)   v$(PKG_VERSION)"
	@echo "───────────────────────────"
	@echo " Filename:   $(PKG_ID)_x86_64.s9pk"
	@echo " Size:       $$(du -h $(PKG_ID)_x86_64.s9pk | cut -f1)"
	@echo " Arch:       x86_64"
	@echo " SDK:        $(SDK_VERSION)"
	@echo " Git:        $(GIT_HASH)$(GIT_DIRTY)"
	@echo ""

# Legacy aliases
arm: aarch64
x86: x86_64

# Install to StartOS device
install: check-init
	@if [ ! -f ~/.startos/config.yaml ]; then \
		echo "$(RED)Error: You must define 'host: http://server-name.local' in ~/.startos/config.yaml first.$(NC)"; \
		exit 1; \
	fi
	@HOST=$$(grep -E "^host:" ~/.startos/config.yaml | cut -d' ' -f2 | cut -d'/' -f3); \
	echo ""; \
	echo "$(YELLOW)🚀 Installing to $$HOST ...$(NC)"; \
	start-cli package install $(PKG_ID).s9pk

# Check dependencies
check-deps:
	@command -v start-cli >/dev/null 2>&1 || { echo "$(RED)Error: start-cli not found. Install from https://start9labs.github.io/start-cli$(NC)"; exit 1; }
	@command -v npm >/dev/null 2>&1 || { echo "$(RED)Error: npm not found. Please install Node.js$(NC)"; exit 1; }

# Initialize if needed
check-init: check-deps
	@if [ ! -d node_modules ]; then \
		echo "$(YELLOW)Installing npm dependencies...$(NC)"; \
		npm ci; \
	fi

# Build TypeScript
javascript/index.js: check-init $(shell find startos -name '*.ts')
	@echo "$(YELLOW)Building TypeScript...$(NC)"
	@BUILD=$(BUILD) npm run build

# Package
package: check-init javascript/index.js
	@echo "$(YELLOW)Packing s9pk...$(NC)"
	@BUILD=$(BUILD) start-cli s9pk pack

# Clean build artifacts
clean:
	rm -rf build javascript
	rm -rf node_modules
	rm -f $(PKG_ID).s9pk $(PKG_ID)_*.s9pk
	rm -f package-lock.json
