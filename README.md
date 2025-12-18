# Canary for StartOS

This repository contains the StartOS wrapper for [Canary](https://github.com/schjonhaug/canary), a self-hosted Bitcoin wallet monitoring service.

## Development

### Prerequisites

- [Deno](https://deno.land/) - for bundling TypeScript scripts
- [start-sdk](https://github.com/Start9Labs/start-os/tree/master/core) - StartOS SDK
- [Docker](https://www.docker.com/) with buildx support
- [yq](https://github.com/mikefarah/yq) - YAML processor

```bash
# macOS
brew install deno yq
brew install --cask docker

# Install start-sdk (see Start9 docs)
```

### Building

```bash
# Clean previous build and rebuild for all architectures
make clean && make

# Build for specific architecture only (faster)
make arm   # aarch64 - Server Pure/Lite
make x86   # x86_64 - Server Pro
```

The build process:
1. Bundles Deno scripts into `scripts/embassy.js`
2. Builds Docker images for target architecture(s)
3. Packs everything into `canary.s9pk`
4. Verifies the package

### Sideloading

#### Option 1: Via CLI

```bash
# Configure your StartOS server in ~/.embassy/config.yaml
# host: http://your-server.local

make install
```

#### Option 2: Via Web UI

1. Open StartOS web interface
2. Go to System > Sideload Service
3. Upload the `canary.s9pk` file

## Structure

```
canary-startos/
├── startos/                    # StartOS SDK TypeScript files
│   ├── actions/                # User actions (Configuration)
│   │   ├── index.ts
│   │   └── config.ts
│   ├── fileModels/             # Persistent data schemas
│   │   └── store.json.ts
│   ├── init/                   # Initialization orchestration
│   │   └── index.ts
│   ├── install/                # Version management
│   │   ├── versions/
│   │   │   ├── index.ts
│   │   │   └── v0.1.0.0.ts
│   │   └── versionGraph.ts
│   ├── backups.ts              # Backup configuration
│   ├── dependencies.ts         # Service dependencies
│   ├── index.ts                # Main exports
│   ├── interfaces.ts           # Network interfaces
│   ├── main.ts                 # Daemon and health checks
│   ├── manifest.ts             # Service manifest
│   ├── sdk.ts                  # SDK initialization
│   └── utils.ts                # Shared constants
├── scripts/
│   ├── docker_entrypoint.sh    # Container startup
│   ├── check-api.sh            # Backend health check
│   └── check-web.sh            # Frontend health check
├── Dockerfile                  # Multi-stage build
├── Makefile                    # Build automation
├── package.json                # Node.js dependencies
├── tsconfig.json               # TypeScript configuration
├── instructions.md             # User documentation
├── icon.png                    # Service icon
├── LICENSE                     # License file
└── README.md                   # This file
```

## Configuration Options

The service exposes these configuration options via the Configuration action in the StartOS UI:

- **Bitcoin Network**: mainnet, testnet, or regtest
- **Electrum Server**: Local Electrs (recommended) or external server
- **External Electrum URL**: Custom Electrum server URL (when using external)
- **Admin Notification Topic**: ntfy.sh topic for admin alerts

## Dependencies

Canary works best with **Electrs** for local blockchain data access. When configured to use the local Electrs server, it provides maximum privacy by keeping your wallet addresses on your own server.

## Testing

After installation, verify:

1. The service starts without errors (check logs)
2. Both health checks pass (Backend API and Web Interface)
3. The web UI is accessible via Tor or LAN
4. Wallet syncing works with your Electrum server

## Releasing a New Version

1. Update version in `startos/install/versions/`
2. Create a new version file (e.g., `v0.2.0.0.ts`)
3. Update `versions/index.ts` to point to the new version
4. Tag the upstream Canary repo with the same version
5. Build and test: `make clean && make`
6. Submit to Start9 registry

## Links

- **Upstream**: https://github.com/schjonhaug/canary
- **Issues**: https://github.com/schjonhaug/canary/issues
- **Start9 Docs**: https://docs.start9.com/developer-docs/
