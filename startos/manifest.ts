import { setupManifest } from '@start9labs/start-sdk'

export const manifest = setupManifest({
  id: 'canary',
  title: 'Canary',
  license: 'Elastic-2.0',
  wrapperRepo: 'https://github.com/schjonhaug/canary-startos/',
  upstreamRepo: 'https://github.com/schjonhaug/canary/',
  supportSite: 'https://github.com/schjonhaug/canary/issues/',
  marketingSite: 'https://github.com/schjonhaug/canary/',
  donationUrl: null,
  docsUrl:
    'https://github.com/schjonhaug/canary-startos/blob/master/instructions.md',
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
    frontend: {
      source: {
        dockerTag: 'schjonhaug/canary-frontend:v1.2.0',
      },
    },
    backend: {
      source: {
        dockerTag: 'schjonhaug/canary-backend:v1.2.0',
      },
    },
  },
  dependencies: {
    fulcrum: {
      optional: true,
      description: 'Used for syncing wallet data from the Bitcoin blockchain',
      metadata: {
        icon: 'https://raw.githubusercontent.com/remcoros/fulcrum-startos/refs/heads/update/040-new/icon.png',
        title: 'Fulcrum',
      },
    },
    electrs: {
      optional: true,
      description: 'Used for syncing wallet data from the Bitcoin blockchain',
      metadata: {
        icon: 'https://raw.githubusercontent.com/Start9Labs/electrs-startos/refs/heads/master/icon.png',
        title: 'Electrs',
      },
    },
  },
})
