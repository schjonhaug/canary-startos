# Canary for StartOS

This repository contains the StartOS wrapper for [Canary](https://github.com/schjonhaug/canary), a self-hosted Bitcoin wallet monitoring service.

## Development

### Prerequisites

**macOS:**
```bash
brew install yq
brew install --cask docker
```

**Debian/Ubuntu (Start9 build environment):**
```bash
./prepare.sh
```

### Building

```bash
# Clean previous build and rebuild for all architectures
make clean && make

# Or explicitly build the s9pk file
make canary.s9pk

# Build for specific architecture only (faster for testing)
make arm   # aarch64 - Server Pure/Lite
make x86   # x86_64 - Server Pro

# Verify the package
make verify
```

The build process:
1. **Linux**: Uses native `start-sdk` (installed via prepare.sh)
2. **macOS**: Builds start-sdk Docker image (first time only, ~2 min)
3. Builds Docker images for target architecture(s)
4. Packs everything into `canary.s9pk`

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
├── scripts/
│   ├── docker_entrypoint.sh    # Container startup
│   ├── check-api.sh            # Backend health check
│   └── check-web.sh            # Frontend health check
├── Dockerfile                  # Multi-stage build
├── Makefile                    # Build automation
├── prepare.sh                  # Debian build environment setup
├── sdk.Dockerfile              # start-sdk Docker build (macOS)
├── manifest.yaml               # StartOS service manifest
├── instructions.md             # User documentation
├── icon.png                    # Service icon (256x256)
└── LICENSE                     # License file
```

## Dependencies

Canary requires **Electrs** for blockchain data access. When using the local Electrs server, it provides maximum privacy by keeping your wallet addresses on your own server.

## Testing Checklist

After sideloading, verify:

- [ ] Service starts without errors (check logs)
- [ ] Both health checks pass (Backend API and Web Interface)
- [ ] Web UI is accessible via Tor or LAN
- [ ] Wallet syncing works with Electrs
- [ ] Push notifications work via ntfy
- [ ] Backup and restore work correctly

## Submitting to Start9 Registry

1. Ensure all tests pass
2. Push latest changes to GitHub
3. Email submissions@start9.com with:
   - Link to this repository
   - Version number being submitted
4. Wait for Start9 to build and test on their Debian system
5. When approved, confirm to publish to production

## Links

- **Upstream**: https://github.com/schjonhaug/canary
- **Wrapper**: https://github.com/schjonhaug/canary-startos
- **Issues**: https://github.com/schjonhaug/canary/issues
- **Start9 Docs**: https://docs.start9.com/0.3.5.x/developer-docs/
