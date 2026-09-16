import { storeJson } from './fileModels/store.json'
import { getFrontendOriginEnv } from './frontendOrigins'
import { i18n } from './i18n'
import { getLocalExplorerEnv } from './localExplorers'
import { getLocalNtfyEnv } from './localNtfy'
import { sdk } from './sdk'
import { getElectrumUrl, serverPort, uiPort } from './utils'

export const main = sdk.setupMain(async ({ effects }) => {
  /**
   * ======================== Setup (optional) ========================
   *
   * In this section, we fetch any resources or run any desired preliminary commands.
   */
  console.info('Starting Canary Wallet!')

  const store = await storeJson.read().const(effects)
  if (!store) {
    throw new Error('No store.json')
  }
  const electrum = store.electrum
  if (!electrum) {
    throw new Error('No Electrum server selected')
  }
  const electrumUrl = await getElectrumUrl(effects, electrum)
  if (!electrumUrl) {
    throw new Error('Electrum server bridge address not yet available')
  }
  const mountpoint = '/app/data'
  const frontendOriginEnv = await getFrontendOriginEnv(effects)
  const localExplorerEnv = await getLocalExplorerEnv(effects)
  const localNtfyEnv = await getLocalNtfyEnv(effects, store.ntfy)
  const backendSub = sdk.SubContainer.of(
    effects,
    { imageId: 'backend' },
    sdk.Mounts.of().mountVolume({
      volumeId: 'main',
      subpath: null,
      mountpoint,
      readonly: false,
    }),
    'backend-sub',
  )

  /**
   * ======================== Daemons ========================
   *
   * In this section, we create one or more daemons that define the service runtime.
   *
   * Each daemon defines its own health check, which can optionally be exposed to the user.
   */
  return sdk.Daemons.of(effects)
    .addOneshot('chown', {
      subcontainer: backendSub,
      exec: {
        command: ['chown', '-R', 'canary-wallet:canary-wallet', mountpoint],
        user: 'root',
      },
      requires: [],
    })
    .addDaemon('server', {
      subcontainer: backendSub,
      exec: {
        command: sdk.useEntrypoint(),
        env: {
          CANARY_WALLET_NETWORK: 'mainnet',
          CANARY_WALLET_ELECTRUM_URL: electrumUrl,
          CANARY_WALLET_BIND_ADDRESS: `0.0.0.0:${serverPort}`,
          CANARY_WALLET_DATA_DIR: mountpoint,
          CANARY_WALLET_MODE: 'self-hosted',
          CANARY_WALLET_SELF_HOSTED_ADMIN_PASSWORD: store.adminPassword,
          CANARY_WALLET_SYNC_INTERVAL: '60',
          JWT_SECRET: store.jwtSecret,
          ...frontendOriginEnv,
          ...localExplorerEnv,
          ...localNtfyEnv,
        },
      },
      ready: {
        display: 'Server',
        gracePeriod: 60000,
        fn: () =>
          sdk.healthCheck.checkWebUrl(
            effects,
            `http://localhost:${serverPort}/api/block-headers/current`,
            {
              successMessage: i18n('The server is ready'),
              errorMessage: i18n('The server is not ready'),
            },
          ),
      },
      requires: ['chown'],
    })
    .addDaemon('web', {
      subcontainer: sdk.SubContainer.of(
        effects,
        { imageId: 'frontend' },
        null,
        'web-sub',
      ),
      exec: {
        command: sdk.useEntrypoint(),
        env: {
          API_URL: `http://localhost:${serverPort}`,
        },
      },
      ready: {
        display: i18n('Web interface'),
        fn: () =>
          sdk.healthCheck.checkPortListening(effects, uiPort, {
            successMessage: i18n('The web interface is ready'),
            errorMessage: i18n('The web interface is not ready'),
          }),
      },
      requires: [],
    })
})
