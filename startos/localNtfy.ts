import { T, utils } from '@start9labs/start-sdk'
import {
  uiHostId as ntfyUiHostId,
  uiInterfaceId as ntfyUiInterfaceId,
} from 'ntfy-startos/startos/utils'
import { storeJson } from './fileModels/store.json'
import { sdk } from './sdk'

export const ntfyPublisherId = 'canary'
export const ntfyTopic = 'canary'

export type NtfyProvisioning = {
  publishUrl: string
  token: string
  topic: string
}

const ntfyCurrentDependency = {
  kind: 'exists' as const,
  // First revision with dependent actions and bridge publish URLs.
  versionRange: '>=2.26.3:0',
}

export async function isNtfyInstalled(effects: T.Effects): Promise<boolean> {
  return sdk.host
    .get(
      effects,
      { packageId: 'ntfy', hostId: ntfyUiHostId },
      (host) => host !== null,
    )
    .const()
}

export async function ntfyDependency(
  effects: T.Effects,
): Promise<{ ntfy: typeof ntfyCurrentDependency } | Record<string, never>> {
  return (await isNtfyInstalled(effects)) ? { ntfy: ntfyCurrentDependency } : {}
}

function ntfyBridgeUrl(host: utils.FilledHost | null): string | null {
  const iface =
    host &&
    Object.values(host.bindings)
      .flatMap((binding) => Object.values(binding.interfaces))
      .find((candidate) => candidate.id === ntfyUiInterfaceId)

  return (
    iface?.addressInfo
      .filter({ kind: 'bridge', predicate: (address) => !address.ssl })
      .format('urlstring')[0] ?? null
  )
}

async function getNtfyPublishUrl(effects: T.Effects): Promise<string | null> {
  return sdk.host
    .get(effects, { packageId: 'ntfy', hostId: ntfyUiHostId }, ntfyBridgeUrl)
    .const()
}

function parseProvisioningResult(
  result: T.ActionResult | null,
): NtfyProvisioning | null {
  if (
    !result ||
    result.version !== '1' ||
    !result.result ||
    result.result.type !== 'group'
  ) {
    return null
  }

  // ntfy translates member names; its publisher result has a fixed field order.
  const [urlMember, tokenMember, topicMember] = result.result.value
  const value = (member: T.ActionResultMember | undefined) =>
    member?.type === 'single' ? member.value : null
  const publishUrl = value(urlMember)
  const token = value(tokenMember)
  const topic = value(topicMember)

  if (!publishUrl || !token || !topic) {
    return null
  }

  return { publishUrl, token, topic }
}

async function provisionNtfy(
  effects: T.Effects,
): Promise<NtfyProvisioning | null> {
  // withInput keys its saved spec by eventId; run calls must reuse it as
  // procedureId, which is missing from the generated effect parameter type.
  const prev = await effects.action
    .getInput({
      packageId: 'ntfy',
      actionId: 'provision-publisher',
    })
    .catch((error) => {
      console.warn('Failed to load ntfy Provision Publisher input', error)
      return null
    })

  if (!prev?.eventId) {
    console.warn('ntfy Provision Publisher did not return an event id')
    return null
  }

  const result = await effects.action
    .run({
      packageId: 'ntfy',
      actionId: 'provision-publisher',
      procedureId: prev.eventId,
      input: {
        packageId: ntfyPublisherId,
        topic: ntfyTopic,
      },
    } as Parameters<T.Effects['action']['run']>[0])
    .catch((error) => {
      console.warn('Failed to provision local ntfy publisher', error)
      return null
    })

  return parseProvisioningResult(result)
}

// No reactive reads: restore must clear the old token only once, before watchers.
export const clearRestoredNtfy = sdk.setupOnInit(async (effects, kind) => {
  if (kind === 'restore') {
    await storeJson.merge(effects, { ntfy: undefined })
  }
})

// Runs after dependency registration on every reactive pass. Cache successes;
// do not loop on an unparseable result: the action has already minted a token.
export const watchLocalNtfy = sdk.setupOnInit(async (effects) => {
  const status = await sdk.getStatus(effects, { packageId: 'ntfy' }).const()
  const storedNtfy = await storeJson.read((s) => s.ntfy).once()

  if (status === null) {
    if (storedNtfy) {
      await storeJson.merge(effects, { ntfy: undefined })
    }
    return
  }

  if (storedNtfy || !status.started) {
    return
  }

  const provisioned = await provisionNtfy(effects)
  if (provisioned) {
    await storeJson.merge(effects, { ntfy: provisioned })
    return
  }

  console.warn(
    'Local ntfy is running but Provision Publisher did not return credentials',
  )
})

// Saved application settings take precedence over these package defaults.
export async function getLocalNtfyEnv(
  effects: T.Effects,
  storedNtfy: NtfyProvisioning | undefined,
): Promise<Record<string, string>> {
  const publishUrl =
    (await getNtfyPublishUrl(effects)) ?? storedNtfy?.publishUrl
  if (!publishUrl) {
    return {}
  }

  const env: Record<string, string> = {
    CANARY_WALLET_NTFY_SERVER_URL: publishUrl,
  }

  if (storedNtfy) {
    env.CANARY_WALLET_NTFY_TOKEN = storedNtfy.token
    env.CANARY_WALLET_NTFY_TOPIC = storedNtfy.topic
  }

  return env
}
