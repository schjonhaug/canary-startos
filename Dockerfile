ARG CANARY_VERSION=v1.4.0

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
FROM rust:1.88-slim AS rust-builder

WORKDIR /app

RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=source /src/backend/Cargo.toml /src/backend/Cargo.lock ./
COPY --from=source /src/backend/src ./src
COPY --from=source /src/backend/migrations ./migrations

RUN cargo build --release

# =============================================================================
# Stage 3: Build Next.js frontend
# =============================================================================
FROM node:22-alpine AS frontend-builder

RUN corepack enable && corepack prepare pnpm@9.15.4 --activate

WORKDIR /app

ARG NEXT_PUBLIC_CANARY_MODE=self-hosted
ARG NEXT_PUBLIC_API_URL=

ENV NEXT_PUBLIC_CANARY_MODE=$NEXT_PUBLIC_CANARY_MODE
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

COPY --from=source /src/frontend/package.json /src/frontend/pnpm-lock.yaml ./

RUN pnpm install --frozen-lockfile

COPY --from=source /src/frontend/ .

RUN NODE_OPTIONS="" pnpm next build

# =============================================================================
# Stage 4: Runtime image
# =============================================================================
FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    curl \
    tini \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js for frontend runtime
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install yq for reading Start9 config
ARG TARGETARCH
RUN curl -fsSL https://github.com/mikefarah/yq/releases/download/v4.44.1/yq_linux_${TARGETARCH} -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

COPY --from=rust-builder /app/target/release/canary /app/backend/canary
COPY --from=rust-builder /app/migrations /app/backend/migrations

COPY --from=frontend-builder /app/public /app/frontend/public
COPY --from=frontend-builder /app/.next/standalone /app/frontend/
COPY --from=frontend-builder /app/.next/static /app/frontend/.next/static

COPY scripts/docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
COPY scripts/check-api.sh /usr/local/bin/check-api.sh
COPY scripts/check-web.sh /usr/local/bin/check-web.sh
RUN chmod +x /usr/local/bin/*.sh

RUN mkdir -p /app/data

ENV CANARY_MODE=self-hosted
ENV CANARY_DATA_DIR=/app/data
ENV CANARY_BIND_ADDRESS=0.0.0.0:3000
ENV NODE_ENV=production
ENV PORT=3001
ENV HOSTNAME=0.0.0.0

EXPOSE 3000 3001

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/usr/local/bin/docker_entrypoint.sh"]
