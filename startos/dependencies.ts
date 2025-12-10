import { sdk } from './sdk'

export const setDependencies = sdk.setupDependencies(async ({ effects }) => {
  // Dependencies will be set dynamically based on user configuration
  // When 'local' electrum source is selected, electrs becomes a dependency
  return {}
})
