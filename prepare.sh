#!/bin/bash
# prepare.sh - Sets up the Debian build environment for Start9 submission
# This script is run by Start9 on their Debian build box before running 'make'

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Preparing build environment for Canary...${NC}"

# Install system dependencies (per Start9 docs)
echo -e "${YELLOW}Installing system dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    openssl \
    libssl-dev \
    libc6-dev \
    clang \
    libclang-dev \
    ca-certificates \
    git \
    curl \
    wget \
    pkg-config \
    libdbus-1-dev \
    libavahi-client-dev \
    perl

# Install yq (YAML processor)
if ! command -v yq &> /dev/null; then
    echo -e "${YELLOW}Installing yq...${NC}"
    YQ_VERSION="v4.40.5"
    ARCH=$(dpkg --print-architecture)
    if [ "$ARCH" = "amd64" ]; then
        YQ_ARCH="amd64"
    else
        YQ_ARCH="arm64"
    fi
    wget -qO /tmp/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${YQ_ARCH}"
    sudo mv /tmp/yq /usr/local/bin/yq
    sudo chmod a+rx /usr/local/bin/yq
fi

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com | bash
    sudo usermod -aG docker "$USER"
    exec sudo su -l $USER
fi

# Setup docker buildx for multi-architecture builds
echo -e "${YELLOW}Setting up Docker buildx...${NC}"
docker buildx install 2>/dev/null || true
docker buildx create --use 2>/dev/null || true
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes -c yes

# Install Rust if not present
if ! command -v cargo &> /dev/null; then
    echo -e "${YELLOW}Installing Rust...${NC}"
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Install start-sdk if not present
if ! command -v start-sdk &> /dev/null; then
    echo -e "${YELLOW}Installing start-sdk...${NC}"

    # Clone start-os repository (using v0.3.5.1 for StartOS 0.3.5 compatibility)
    git clone --branch v0.3.5.1 https://github.com/Start9Labs/start-os.git /tmp/start-os
    cd /tmp/start-os
    git submodule update --init --recursive

    # Create required files for build
    echo "v0.3.5.1" > GIT_HASH.txt
    mkdir -p web/dist/static

    # Build SDK
    cd core
    cargo install --path=./startos --no-default-features --features=sdk,cli --locked

    # Create symlinks
    sudo ln -sf "$HOME/.cargo/bin/startbox" /usr/local/bin/start-sdk
    sudo ln -sf "$HOME/.cargo/bin/startbox" /usr/local/bin/start-cli

    # Initialize SDK
    start-sdk init

    # Cleanup
    cd /
    rm -rf /tmp/start-os

    echo -e "${GREEN}start-sdk installed successfully${NC}"
fi

# Verify installations
echo -e "${YELLOW}Verifying installations...${NC}"
echo "  Docker: $(docker --version)"
echo "  yq: $(yq --version)"
echo "  start-sdk: $(start-sdk --version 2>/dev/null || echo 'installed')"

echo ""
echo -e "${GREEN}Build environment ready!${NC}"
echo ""
echo "To build the package, run:"
echo "  make canary.s9pk"
