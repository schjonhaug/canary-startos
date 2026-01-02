import { selectElectrum } from './actions/selectElectrum'
import { storeJson } from './fileModels/store.json'
import { sdk } from './sdk'

export const setDependencies = sdk.setupDependencies(async ({ effects }) => {
  const electrum = await storeJson.read((s) => s.electrum).const(effects)

  if (electrum === 'fulcrum') {
    return {
      fulcrum: {
        kind: 'running',
        versionRange: '>=2.1.0:3-beta.1',
        healthChecks: ['primary', 'sync-progress'],
      },
    }
  } else if (electrum === 'electrs') {
    return {
      electrs: {
        kind: 'running',
        versionRange: '>=0.11.0:1-beta.1',
        healthChecks: ['electrs', 'sync'],
      },
    }
  } else {
    await sdk.action.createOwnTask(effects, selectElectrum, 'critical', {
      reason: 'Canary requires an Electrum server to look up addresses',
    })
    return {}
  }
})
