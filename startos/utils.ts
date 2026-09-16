import { T } from '@start9labs/start-sdk'
import {
  electrumHostId as electrsHostId,
  port as electrsPort,
} from 'electrs-startos/startos/utils'
import {
  electrumPort as fulcrumPort,
  mainHostId as fulcrumHostId,
} from 'fulcrum-startos/startos/utils'
import { sdk } from './sdk'

export const serverPort = 3001
export const uiPort = 3000

// Each supported Electrum server's host id and internal (plaintext) electrum
// port, imported from the server package so canary tracks its binding without
// hardcoding. Keyed by package id (also the dependency id in dependencies.ts).
const electrumBinding = {
  fulcrum: { hostId: fulcrumHostId, internalPort: fulcrumPort },
  electrs: { hostId: electrsHostId, internalPort: electrsPort },
} as const

/**
 * The selected Electrum server's `tcp://<bridge ip>:<port>` for
 * `CANARY_WALLET_ELECTRUM_URL` (replaces `${electrum}.startos:50001`). A reactive
 * `.const()` on just the bridge address (doctrine v3): a server update is 0
 * restarts, install/uninstall/port-change is one healing restart. Resolves
 * null until the selected server's binding exists — main.ts throws until then
 * and the `.const()` heals when it appears.
 */
export const getElectrumUrl = async (
  effects: T.Effects,
  electrum: keyof typeof electrumBinding,
) => {
  // Both servers bind electrum as `secure: null` with `addSsl`, publishing a
  // plaintext and a TLS bridge address; we speak `tcp://`, so pin the plaintext.
  const addr = await sdk.host
    .getBridgeAddress(effects, {
      packageId: electrum,
      ...electrumBinding[electrum],
      ssl: false,
    })
    .const()
  return addr && `tcp://${addr}`
}
