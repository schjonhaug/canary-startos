import { sdk } from './sdk'
import { webUiPort, apiPort } from './utils'

export const main = sdk.setupMain(async ({ effects, started }) => {
  console.info('Starting Canary Bitcoin Wallet Manager...')

  // Create mounts
  const mounts = sdk.Mounts.of().mountVolume({
    volumeId: 'main',
    subpath: null,
    mountpoint: '/app/data',
    readonly: false,
  })

  // Create subcontainer
  const subcontainer = await sdk.SubContainer.of(
    effects,
    { imageId: 'main' },
    mounts,
    'canary',
  )

  return sdk.Daemons.of(effects, started)
    .addDaemon('primary', {
      subcontainer,
      exec: {
        command: ['/usr/local/bin/docker_entrypoint.sh'],
        env: {
          CANARY_MODE: 'self-hosted',
          CANARY_DATA_DIR: '/app/data',
          CANARY_BIND_ADDRESS: `0.0.0.0:${apiPort}`,
          NODE_ENV: 'production',
          PORT: String(webUiPort),
          HOSTNAME: '0.0.0.0',
        },
      },
      ready: {
        display: 'Backend API',
        fn: () =>
          sdk.healthCheck.checkPortListening(effects, apiPort, {
            successMessage: 'The Canary API is responding',
            errorMessage: 'Backend API not responding',
          }),
      },
      requires: [],
    })
    .addHealthCheck('web-ui', {
      ready: {
        display: 'Web Interface',
        fn: () =>
          sdk.healthCheck.checkPortListening(effects, webUiPort, {
            successMessage: 'The Canary web interface is ready',
            errorMessage: 'Web interface not responding',
          }),
      },
      requires: ['primary'],
    })
})
