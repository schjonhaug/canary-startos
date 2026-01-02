import { matches, FileHelper } from '@start9labs/start-sdk'

const { object, literals } = matches

const shape = object({
  electrum: literals('fulcrum', 'electrs').nullable().onMismatch(null),
})

export const storeJson = FileHelper.json(
  {
    volumeId: 'main',
    subpath: '/store.json',
  },
  shape,
)
