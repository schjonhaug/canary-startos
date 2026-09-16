import { T } from '@start9labs/start-sdk'
import { uiHostId as btcExplorerHostId } from 'bitcoin-explorer-startos/startos/interfaces'
import { mainHostId as mempoolHostId } from 'mempool-startos/startos/utils'
import { interfaceUrls } from './interfaceUrls'
import { sdk } from './sdk'

type ExplorerInterface = {
  packageId: 'mempool' | 'bitcoin-explorer'
  // Host id (the sdk.MultiHost.of group) and the interface id exported on it.
  hostId: string
  interfaceId: string
  envVar: 'CANARY_WALLET_MEMPOOL_URLS' | 'CANARY_WALLET_BTC_RPC_EXPLORER_URLS'
}

// Adding an explorer is an entry here and nothing else: package id, host id,
// interface id, and the env var Canary reads. Keep the browser-safety filter --
// only addresses a browser can actually reach are handed over.
const explorerInterfaces: ExplorerInterface[] = [
  {
    packageId: 'mempool',
    hostId: mempoolHostId,
    interfaceId: 'webui',
    envVar: 'CANARY_WALLET_MEMPOOL_URLS',
  },
  {
    packageId: 'bitcoin-explorer',
    hostId: btcExplorerHostId,
    interfaceId: 'ui',
    envVar: 'CANARY_WALLET_BTC_RPC_EXPLORER_URLS',
  },
]

async function getExplorerUrls(
  effects: T.Effects,
  { packageId, hostId, interfaceId }: ExplorerInterface,
): Promise<string[]> {
  return sdk.host
    .get(effects, { hostId, packageId }, (host) =>
      interfaceUrls(host, interfaceId),
    )
    .const()
    .catch(() => [])
}

export async function getLocalExplorerEnv(
  effects: T.Effects,
): Promise<Record<string, string>> {
  const env: Record<string, string> = {}

  for (const explorerInterface of explorerInterfaces) {
    const urls = await getExplorerUrls(effects, explorerInterface)
    if (urls.length > 0) {
      env[explorerInterface.envVar] = urls.join(',')
    }
  }

  if (Object.keys(env).length > 0) {
    env.CANARY_WALLET_TX_EXPLORER_PLATFORM = 'startos'
  }

  return env
}
