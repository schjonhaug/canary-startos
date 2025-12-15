import { sdk } from './sdk'

export const setDependencies = sdk.setupDependencies(async ({ effects }) => {
  return {
    electrs: {
      kind: 'running' as const,
      healthChecks: [],
      versionRange: '*',
    },
  }
})
