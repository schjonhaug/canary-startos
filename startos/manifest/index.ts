import { setupManifest } from '@start9labs/start-sdk'
import { long, short } from './i18n'

export const manifest = setupManifest({
  id: 'canary',
  title: 'Canary Wallet',
  license: 'Elastic-2.0',
  packageRepo: 'https://github.com/Start9-Community/canary-startos',
  upstreamRepo: 'https://github.com/schjonhaug/canary/',
  marketingUrl: 'https://canarybitcoin.com',
  donationUrl: 'https://canarybitcoin.com/donations',
  description: { short, long },
  volumes: ['main'],
  images: {
    frontend: {
      source: {
        dockerTag: 'schjonhaug/canary-frontend:v1.7.2',
      },
    },
    backend: {
      source: {
        dockerTag: 'schjonhaug/canary-backend:v1.7.2',
      },
    },
  },
})
