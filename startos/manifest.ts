import { setupManifest } from '@start9labs/start-sdk'

export const manifest = setupManifest({
  id: 'canary',
  title: 'Canary',
  license: 'Elastic-2.0',
  wrapperRepo: 'https://github.com/schjonhaug/canary-startos',
  upstreamRepo: 'https://github.com/schjonhaug/canary',
  supportSite: 'https://github.com/schjonhaug/canary/issues',
  marketingSite: 'https://github.com/schjonhaug/canary',
  donationUrl: null,
  docsUrl: 'https://github.com/schjonhaug/canary-startos/blob/main/instructions.md',
  description: {
    short: 'Bitcoin wallet monitoring service with transaction notifications',
    long: `Canary is a self-hosted Bitcoin wallet monitoring service that provides:

- Watch-only wallet management using BDK (Bitcoin Development Kit)
- Real-time transaction notifications via ntfy.sh push notifications
- Support for multipath descriptors (P2WPKH, P2SH, P2TR, P2PKH)
- Deep scanning to detect funds at high address indexes
- Transaction analysis including RBF/CPFP detection
- Multi-language support (English and Norwegian)
- Balance alerts with configurable thresholds

Perfect for monitoring your cold storage wallets or watching family members' wallets.`,
  },
  volumes: ['main'],
  images: {
    main: {
      source: {
        dockerBuild: {
          dockerfile: './Dockerfile',
        },
      },
    },
  },
  hardwareRequirements: {},
  alerts: {
    install: `Canary requires an Electrum server connection to sync wallet data.
You can either:
1. Use the local Electrs service (recommended for privacy)
2. Configure an external Electrum server in the settings`,
    update: null,
    uninstall: `Your wallet data and notification history will be preserved in backups.
No Bitcoin funds are stored - this is a watch-only monitoring service.`,
    restore: `Your wallet configurations and notification settings have been restored.
Wallet data will re-sync from the Electrum server.`,
    start: null,
    stop: null,
  },
  dependencies: {},
})
