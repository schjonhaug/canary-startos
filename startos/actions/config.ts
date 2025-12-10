import { sdk } from '../sdk'
import { Store, defaultConfig } from '../fileModels/store.json'

const { InputSpec, Value } = sdk

const configSpec = InputSpec.of({
  network: Value.select({
    name: 'Bitcoin Network',
    description: 'The Bitcoin network to monitor wallets on',
    default: 'mainnet',
    values: {
      mainnet: 'Mainnet (Production)',
      testnet: 'Testnet (Testing)',
      regtest: 'Regtest (Local Development)',
    },
  }),
  electrumSource: Value.select({
    name: 'Electrum Server',
    description: 'Where to get blockchain data from',
    warning:
      'Using an external Electrum server may expose your wallet addresses to third parties.',
    default: 'local',
    values: {
      local: 'Local Electrs (Recommended)',
      external: 'External Server',
    },
  }),
  externalElectrumUrl: Value.text({
    name: 'External Electrum URL',
    description:
      "URL of external Electrum server (only used if 'External Server' is selected above)",
    required: false,
    default: 'ssl://electrum.blockstream.info:50002',
    patterns: [
      {
        regex: '^(tcp|ssl)://[^\\s]+:\\d+$',
        description:
          'Must be a valid Electrum URL (tcp:// or ssl:// followed by host:port)',
      },
    ],
  }),
  adminNotificationTopic: Value.text({
    name: 'Admin Notification Topic',
    description:
      'ntfy.sh topic for admin notifications (optional). Subscribe at https://ntfy.sh/your-topic',
    required: false,
    default: null,
  }),
})

export const config = sdk.Action.withInput(
  // id
  'config',

  // metadata
  async () => ({
    name: 'Configuration',
    description: 'Configure Canary settings',
    warning: null,
    allowedStatuses: 'any' as const,
    group: null,
    visibility: 'enabled' as const,
  }),

  // form input specification
  configSpec,

  // pre-fill the input form
  async () => {
    const store = await Store.read().once()
    return {
      network: store?.network ?? defaultConfig.network,
      electrumSource: store?.electrumSource ?? defaultConfig.electrumSource,
      externalElectrumUrl:
        store?.externalElectrumUrl ?? defaultConfig.externalElectrumUrl,
      adminNotificationTopic:
        store?.adminNotificationTopic ?? defaultConfig.adminNotificationTopic,
    }
  },

  // the execution function
  async ({ effects, input }) => {
    const newConfig = {
      network: input.network,
      electrumSource: input.electrumSource,
      externalElectrumUrl: input.externalElectrumUrl || undefined,
      adminNotificationTopic: input.adminNotificationTopic || undefined,
    }

    // Save configuration to store
    await Store.write(effects, newConfig)

    return {
      version: '1' as const,
      title: 'Configuration Saved',
      message:
        'Your configuration has been saved. The service may need to be restarted for changes to take effect.',
      result: {
        type: 'single' as const,
        value: JSON.stringify(newConfig, null, 2),
        copyable: false,
        qr: false,
        masked: false,
      },
    }
  },
)
