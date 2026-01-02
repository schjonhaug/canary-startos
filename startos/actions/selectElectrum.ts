import { storeJson } from '../fileModels/store.json'
import { sdk } from '../sdk'

const { InputSpec, Value } = sdk

const inputSpec = InputSpec.of({
  electrum: Value.select({
    name: 'Electrum Server',
    values: {
      fulcrum: 'Fulcrum',
      electrs: 'Electrs',
    },
    default: 'fulcrum',
  }),
})

export const selectElectrum = sdk.Action.withInput(
  'select-electrum',

  async ({ effects }) => ({
    name: 'Select Electrum Server',
    description: 'Select which Electrum server to use for address lookups',
    warning: null,
    allowedStatuses: 'any',
    group: null,
    visibility: 'enabled',
  }),

  // form input specification
  inputSpec,

  // optionally pre-fill the input form
  async ({ effects }) => ({
    electrum: (await storeJson.read((s) => s.electrum).once()) || undefined,
  }),

  // the execution function
  async ({ effects, input }) =>
    storeJson.merge(effects, { electrum: input.electrum }),
)
