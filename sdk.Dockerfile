# Dockerfile for start-sdk (StartOS 0.3.5)
# This builds the SDK once and caches it for future use

FROM rust:1.75-slim-bookworm

RUN apt-get update && apt-get install -y \
    git \
    libssl-dev \
    pkg-config \
    libdbus-1-dev \
    libavahi-client-dev \
    build-essential \
    perl \
    && rm -rf /var/lib/apt/lists/*

# Clone and build start-sdk
RUN git clone --depth 1 --branch v0.3.5.1 --recurse-submodules \
    https://github.com/Start9Labs/start-os.git /tmp/start-os \
    && cd /tmp/start-os \
    && echo "v0.3.5.1" > GIT_HASH.txt \
    && cd core \
    && mkdir -p ../web/dist/static \
    && cargo install --path=./startos --no-default-features --features=sdk,cli --locked \
    && rm -rf /tmp/start-os

# Create symlinks and initialize
RUN ln -sf /usr/local/cargo/bin/startbox /usr/local/cargo/bin/start-sdk \
    && ln -sf /usr/local/cargo/bin/startbox /usr/local/cargo/bin/start-cli \
    && mkdir -p /etc/embassy \
    && start-sdk init

WORKDIR /pkg
ENTRYPOINT ["start-sdk"]
