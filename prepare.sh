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

# Install system dependencies
echo -e "${YELLOW}Installing system dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y \
    git \
    curl \
    wget \
    build-essential \
    libssl-dev \
    pkg-config \
    libdbus-1-dev \
    libavahi-client-dev \
    perl

# Install yq (YAML processor)
if ! command -v yq &> /dev/null; then
    echo -e "${YELLOW}Installing yq...${NC}"
    YQ_VERSION="v4.40.5"
    wget -qO /tmp/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
    sudo mv /tmp/yq /usr/local/bin/yq
    sudo chmod +x /usr/local/bin/yq
fi

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    sudo usermod -aG docker $USER
fi

# Setup docker buildx for multi-architecture builds
echo -e "${YELLOW}Setting up Docker buildx...${NC}"
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes -c yes

# Install Rust if not present
if ! command -v cargo &> /dev/null; then
    echo -e "${YELLOW}Installing Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Install start-sdk if not present
if ! command -v start-sdk &> /dev/null; then
    echo -e "${YELLOW}Installing start-sdk...${NC}"

    # Clone start-os repository
    git clone --depth 1 --branch v0.3.5.1 --recurse-submodules \
        https://github.com/Start9Labs/start-os.git /tmp/start-os

    cd /tmp/start-os
    echo "v0.3.5.1" > GIT_HASH.txt
    cd core

    # Create required directory for build
    mkdir -p ../web/dist/static

    # Build and install SDK
    cargo install --path=./startos --no-default-features --features=sdk,cli --locked

    # Create symlinks
    sudo ln -sf "$HOME/.cargo/bin/startbox" /usr/local/bin/start-sdk
    sudo ln -sf "$HOME/.cargo/bin/startbox" /usr/local/bin/start-cli

    # Initialize SDK
    start-sdk init

    # Cleanup
    cd /
    rm -rf /tmp/start-os
fi

echo -e "${GREEN}Build environment ready!${NC}"
echo ""
echo "To build the package, run:"
echo "  make canary.s9pk"
