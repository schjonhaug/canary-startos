import { sdk } from './sdk'
import { webUiPort, apiPort } from './utils'

export const setInterfaces = sdk.setupInterfaces(async ({ effects }) => {
  // Web UI multi-host (port 3001)
  const webUiMulti = sdk.MultiHost.of(effects, 'web-ui-multi')
  const webUiOrigin = await webUiMulti.bindPort(webUiPort, {
    protocol: 'http',
  })

  // Web UI interface
  const webUi = sdk.createInterface(effects, {
    name: 'Web UI',
    id: 'web-ui',
    description: 'The main web interface for managing your Bitcoin wallets',
    type: 'ui',
    masked: false,
    schemeOverride: null,
    username: null,
    path: '',
    query: {},
  })

  // Export Web UI
  const webUiReceipt = await webUiOrigin.export([webUi])

  // API multi-host (port 3000)
  const apiMulti = sdk.MultiHost.of(effects, 'api-multi')
  const apiOrigin = await apiMulti.bindPort(apiPort, {
    protocol: 'http',
  })

  // API interface
  const api = sdk.createInterface(effects, {
    name: 'API',
    id: 'api',
    description:
      'REST API for wallet management (used internally by the web interface)',
    type: 'api',
    masked: false,
    schemeOverride: null,
    username: null,
    path: '',
    query: {},
  })

  // Export API
  const apiReceipt = await apiOrigin.export([api])

  return [webUiReceipt, apiReceipt]
})
