import { sdk } from '../sdk'
import { selectElectrum } from './selectElectrum'

export const actions = sdk.Actions.of().addAction(selectElectrum)
