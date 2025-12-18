# Start9 combined Dockerfile for Canary
# Builds both Rust backend and Next.js frontend in a single image

ARG CANARY_VERSION=v1.1.0

# =============================================================================
# Stage 1: Clone Canary source
# =============================================================================
FROM alpine:3.20 AS source

ARG CANARY_VERSION

RUN apk add --no-cache git

WORKDIR /src
RUN git clone --depth 1 --branch ${CANARY_VERSION} https://github.com/schjonhaug/canary.git .

# =============================================================================
# Stage 2: Build Rust backend
# =============================================================================
FROM rust:1.85-slim AS rust-builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy backend source from cloned repo
COPY --from=source /src/backend/Cargo.toml /src/backend/Cargo.lock ./
COPY --from=source /src/backend/src ./src
COPY --from=source /src/backend/migrations ./migrations

# Build the Rust application
RUN cargo build --release

# =============================================================================
# Stage 3: Build Node.js xpub-tools dependencies
# =============================================================================
FROM node:20-slim AS node-tools-builder

WORKDIR /app/xpub-tools

# Copy xpub-tools project files
COPY --from=source /src/backend/xpub-tools/package.json /src/backend/xpub-tools/package-lock.json* ./
COPY --from=source /src/backend/xpub-tools/scripts ./scripts

# Install dependencies
RUN npm ci --only=production

# =============================================================================
# Stage 4: Build Next.js frontend
# =============================================================================
FROM node:22-alpine AS frontend-builder

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Build args for Next.js
ARG NEXT_PUBLIC_CANARY_MODE=self-hosted
ARG NEXT_PUBLIC_API_URL=

# Set environment variables for build
ENV NEXT_PUBLIC_CANARY_MODE=$NEXT_PUBLIC_CANARY_MODE
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

# Copy frontend package files
COPY --from=source /src/frontend/package.json /src/frontend/pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy frontend source code
COPY --from=source /src/frontend/ .

# Build Next.js (standalone output)
RUN pnpm next build

# =============================================================================
# Stage 5: Runtime image
# =============================================================================
FROM debian:bookworm-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    curl \
    tini \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 for frontend runtime
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Copy Rust backend binary
COPY --from=rust-builder /app/target/release/canary /app/backend/canary

# Copy backend migrations
COPY --from=rust-builder /app/migrations /app/backend/migrations

# Copy Node.js xpub-tools
COPY --from=node-tools-builder /app/xpub-tools /app/backend/xpub-tools

# Copy Next.js standalone build
COPY --from=frontend-builder /app/public /app/frontend/public
COPY --from=frontend-builder /app/.next/standalone /app/frontend/
COPY --from=frontend-builder /app/.next/static /app/frontend/.next/static

# Copy Start9 scripts (health checks and entrypoint)
COPY scripts/docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
COPY scripts/check-api.sh /usr/local/bin/check-api.sh
COPY scripts/check-web.sh /usr/local/bin/check-web.sh
RUN chmod +x /usr/local/bin/*.sh

# Create data directory for persistent storage
RUN mkdir -p /app/data

# Environment defaults for Start9
ENV CANARY_MODE=self-hosted
ENV CANARY_DATA_DIR=/app/data
ENV CANARY_BIND_ADDRESS=0.0.0.0:3000
ENV NODE_ENV=production
ENV PORT=3001
ENV HOSTNAME=0.0.0.0

# Expose ports
# Backend API: 3000
# Frontend: 3001
EXPOSE 3000 3001

# Use tini as init system
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]

# Start via entrypoint script
CMD ["/usr/local/bin/docker_entrypoint.sh"]
