import { matches, FileHelper } from '@start9labs/start-sdk'

const { object, literals, string } = matches

const shape = object({
  electrum: literals('fulcrum', 'electrs').nullable().onMismatch(null),
  adminPassword: string.optional().onMismatch(undefined),
  jwtSecret: string.optional().onMismatch(undefined),
})

export const storeJson = FileHelper.json(
  {
    volumeId: 'main',
    subpath: '/store.json',
  },
  shape,
)
