import { FileHelper, z } from '@start9labs/start-sdk'
import { sdk } from '../sdk'

const shape = z.object({
  electrum: z.enum(['fulcrum', 'electrs']).nullable().catch(null),
  adminPassword: z.string().optional().catch(undefined),
  jwtSecret: z.string().optional().catch(undefined),
})

export const storeJson = FileHelper.json(
  {
    base: sdk.volumes.main,
    subpath: '/store.json',
  },
  shape,
)
