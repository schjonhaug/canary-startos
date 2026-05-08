import { T } from '@start9labs/start-sdk'
import { randomBytes } from 'crypto'

import { storeJson } from './fileModels/store.json'

const ADMIN_PASSWORD_LENGTH = 32
const JWT_SECRET_LENGTH = 64
const SECRET_CHARS =
  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'

export type CanaryCredentials = {
  adminPassword: string
  jwtSecret: string
}

function generateSecret(length: number): string {
  const bytes = randomBytes(length)
  return Array.from(
    bytes,
    (byte) => SECRET_CHARS[byte % SECRET_CHARS.length],
  ).join('')
}

export async function ensureCredentials(
  effects: T.Effects,
): Promise<CanaryCredentials> {
  const store = await storeJson.read().once()
  const adminPassword =
    store?.adminPassword || generateSecret(ADMIN_PASSWORD_LENGTH)
  const jwtSecret = store?.jwtSecret || generateSecret(JWT_SECRET_LENGTH)

  if (
    store?.adminPassword !== adminPassword ||
    store?.jwtSecret !== jwtSecret
  ) {
    await storeJson.merge(effects, {
      adminPassword,
      jwtSecret,
    })
  }

  return {
    adminPassword,
    jwtSecret,
  }
}
