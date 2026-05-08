import { sdk } from '../sdk'
import { selectElectrum } from './selectElectrum'
import { showLoginCredentials } from './showLoginCredentials'

export const actions = sdk.Actions.of()
  .addAction(selectElectrum)
  .addAction(showLoginCredentials)
