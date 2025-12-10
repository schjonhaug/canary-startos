import { FileHelper, matches } from '@start9labs/start-sdk'

const { object, string, literals } = matches

// Configuration store schema
export interface StoreConfig {
  network: 'mainnet' | 'testnet' | 'regtest'
  electrumSource: 'local' | 'external'
  externalElectrumUrl: string | undefined
  adminNotificationTopic: string | undefined
}

// Default configuration
export const defaultConfig: StoreConfig = {
  network: 'mainnet',
  electrumSource: 'local',
  externalElectrumUrl: 'ssl://electrum.blockstream.info:50002',
  adminNotificationTopic: undefined,
}

const storeShape = object({
  network: literals('mainnet', 'testnet', 'regtest').onMismatch('mainnet'),
  electrumSource: literals('local', 'external').onMismatch('local'),
  externalElectrumUrl: string
    .optional()
    .onMismatch('ssl://electrum.blockstream.info:50002'),
  adminNotificationTopic: string.optional().onMismatch(undefined),
})

export const Store = FileHelper.json(
  { volumeId: 'main', subpath: '/store.json' },
  storeShape,
)
