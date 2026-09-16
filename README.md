<p align="center">
  <img src="icon.svg" alt="Canary Wallet Logo" width="21%">
</p>

# Canary Wallet on StartOS

> Everything not listed in this document should behave the same as upstream
> Canary Wallet. If a feature, setting, or behavior is not mentioned here, the
> upstream documentation is accurate and fully applicable — see the
> Documentation section of `instructions.md` for links.

[Canary Wallet](https://github.com/schjonhaug/canary-wallet/) is a Bitcoin wallet watcher: it tracks addresses and descriptors and tells you when they move, reading everything from an Electrum server rather than from a third party. This package runs it in self-hosted mode, wires it to whichever Electrum server you run, and points its transaction links at your own block explorers if you have any.

- **Upstream repo:** <https://github.com/schjonhaug/canary-wallet/>
- **Wrapper repo:** <https://github.com/Start9-Community/canary-startos>

---

## Table of Contents

- [Image and Container Runtime](#image-and-container-runtime)
- [Volume and Data Layout](#volume-and-data-layout)
- [File Models](#file-models)
- [Dependencies](#dependencies)
- [Network Access and Interfaces](#network-access-and-interfaces)
- [Installation and First-Run Flow](#installation-and-first-run-flow)
- [Actions](#actions)
- [Tasks](#tasks)
- [Health Checks](#health-checks)
- [Backups and Restore](#backups-and-restore)
- [Limitations and Differences](#limitations-and-differences)
- [Quick Reference for AI Consumers](#quick-reference-for-ai-consumers)

---

## Image and Container Runtime

Two upstream images, unmodified — the application ships its front end and back end separately, and so does this package.

| Property      | Value                                                       |
| ------------- | ----------------------------------------------------------- |
| Images        | `schjonhaug/canary-wallet-frontend`, `schjonhaug/canary-wallet-backend`   |
| Architectures | As published upstream; the manifest declares no restriction |
| Entrypoint    | Each image's own, via `sdk.useEntrypoint()`                 |

| Subcontainer  | Purpose                                                             |
| ------------- | ------------------------------------------------------------------- |
| `backend-sub` | The server — the only one with a volume, and where the work happens |
| `web-sub`     | The front end, which mounts nothing                                 |

The two share the service network namespace, so the front end reaches the server over loopback and neither the server's port nor anything else is exported.

## Volume and Data Layout

One volume, mounted into the back end only. Before the server starts, an
idempotent root oneshot restores ownership of the mounted volume to the
image's unprivileged `canary` user; StartOS presents service volumes as
root-owned when they are mounted.

| Volume | Mount Point | Purpose                                       |
| ------ | ----------- | --------------------------------------------- |
| `main` | `/app/data` | The application's data, and the package store |

The front end is stateless and mounts nothing — everything worth keeping is written by the server into this one directory.

## File Models

One model, holding the things upstream cannot decide for itself.

| File         | Format | Modelled                | Written by            |
| ------------ | ------ | ----------------------- | --------------------- |
| `store.json` | JSON   | Yes — `FileHelper.json` | Init, both actions, and the ntfy watcher |

- **`electrum`** — which Electrum server to use, `fulcrum` or `electrs`, or unset. This one field drives the dependency, the task, and the server's Electrum URL all at once.
- **`adminPassword`** — the web login password, set by an action and passed to the server as environment.
- **`jwtSecret`** — the session signing secret. It has a **generated default** rather than being seeded explicitly, so it exists from the first read and never needs an install step.
- **`ntfy`** — cached output of ntfy's Provision Publisher (`publishUrl`, `token`, `topic`). Written by init when ntfy is running, and cleared on backup restore or when ntfy is uninstalled. The action mints a new token on every run, so the cache is what makes auto-provisioning survive restarts.

All four are read reactively, so changing any of them re-runs `main` and the server restarts with the new value.

Canary Wallet's own settings are its business and live in the same volume; the package neither seeds nor rewrites them.

## Dependencies

**Five are declared optional.** Exactly one Electrum server is required — which one depends on your choice — and ntfy becomes a current dependency only while it is installed.

| Dependency       | Role                                                              |
| ---------------- | ----------------------------------------------------------------- |
| Fulcrum          | Required, `kind: 'running'`, when selected as the Electrum server |
| Electrs          | Required, `kind: 'running'`, when selected as the Electrum server |
| Mempool          | Never required — used only for explorer links, if installed       |
| Bitcoin Explorer | Never required — used only for explorer links, if installed       |
| ntfy             | Declared `kind: 'exists'`, only while ntfy itself is installed    |

**Canary Wallet cannot run without an Electrum server.** The choice is not defaulted, because the two are not interchangeable in cost — so until one is selected, the package declares no Electrum dependency and raises a task instead. Once selected, that server becomes a hard `running` dependency with its own health checks required, and the other is not. An installed ntfy service is declared independently of that choice.

The selected server's address is resolved over the internal bridge, pinned to the **plaintext** leg: both Fulcrum and Electrs publish a plaintext and a TLS address on that binding, and Canary Wallet speaks the plaintext protocol. Until the selected server's binding exists the address resolves to nothing and the service refuses to start, healing on its own once it appears.

**Mempool and Bitcoin Explorer are a different kind of optional.** They are never depended on; the package simply looks for them and, if present, hands Canary Wallet their browser-reachable addresses so transaction links point at your own explorer instead of a public one. Nothing breaks when they are absent — the links just go elsewhere.

Only addresses a browser can actually open are passed: the internal bridge and loopback are filtered out, and anything that is not HTTP or HTTPS is dropped.

**ntfy is optional until it is installed.** Detection via the UI host is not enough to call Provision Publisher: that action is `access: 'dependent'`, so the package adds ntfy to `current_dependencies` whenever the host exists, and drops it again when ntfy is removed. The declared floor is the first ntfy release whose Provision Publisher accepts dependent callers and returns a bridge publish URL. It does not require ntfy to remain running or healthy. Dependency registration and publisher provisioning share one reactive handler, so registration completes before provisioning even when ntfy is installed later.

When ntfy is running, init calls Provision Publisher with publisher id `canary-wallet` and topic `canary-wallet`, caches the returned token, and `setupMain` passes `CANARY_WALLET_NTFY_SERVER_URL`, `CANARY_WALLET_NTFY_TOKEN`, and `CANARY_WALLET_NTFY_TOPIC`. Those are defaults: settings saved in Canary Wallet stay authoritative, the wrapper exports the managed token for the application to use with the detected local integration, and wallet contacts are not created automatically. The publish URL is ntfy's live internal bridge address, not the retired `ntfy.startos` hostname. Removing ntfy clears the cache and the environment variables on the next reactive restart.

## Network Access and Interfaces

One interface.

| Interface | Id   | Type | Port | Description                        |
| --------- | ---- | ---- | ---- | ---------------------------------- |
| Web UI    | `ui` | ui   | 3000 | The web interface of Canary Wallet |

Bound on the `ui-multi` MultiHost over HTTP and not masked. The back end listens on 3001 inside the service and is never exported.

At startup, the package reads every enabled browser-reachable URL from this
interface. It passes a preferred HTTPS `.local` URL as `FRONTEND_URL` and all
enabled URLs as `FRONTEND_URLS`, so Canary Wallet's browser-origin checks keep
working when the interface is opened through another enabled StartOS address.

Canary Wallet supports ntfy, encrypted Nostr DMs, and JSON webhooks. Notification events and disclosed content are selected per contact and per method in Canary Wallet; the StartOS wrapper provisions the optional local ntfy publisher described above.

## Installation and First-Run Flow

Install seeds the store and nothing else, then raises **two** critical tasks — and they are genuinely independent, because the service can satisfy neither on its own.

1. **Select an Electrum server.** Until this is set the package declares no dependency, and `main` throws rather than starting.
2. **Set the admin password.** There is no default credential.

The order does not matter, but both are required before the service will run. The Electrum task is raised from the dependency setup rather than from init, so it appears whenever the selection is missing — including if it is somehow cleared later.

Once running, the server syncs on a fixed interval and the front end serves the interface.

## Actions

Two actions, and between them they are the whole of setup.

### Select Electrum Server

Chooses which Electrum server Canary Wallet reads from. Run it when its task appears, and again to switch servers.

- **What it changes:** `electrum` in the store — and with it the declared dependency, the resolved server address, and whether the task is raised.
- **Cost:** the service restarts and reconnects to the new server.
- **Repeat safety:** idempotent; the last choice wins.
- **What to expect after switching:** the newly selected server becomes a required running dependency, and the previous one stops being one. Canary Wallet re-reads history from the new server rather than migrating anything.

### Set Admin Password

Sets the password for the web interface. Run it when its task appears, or to rotate the credential.

- **When to run it:** **only while stopped** — the password is read into the server's environment at start, so it is changed between runs rather than under a running server.
- **What it changes:** `adminPassword` in the store.
- **Repeat safety:** re-runnable; the last value wins.
- **Outputs:** the password.

## Tasks

Two, both `critical`, and both raised by circumstance rather than only at install.

| Task                   | Severity   | Raised when                    | Cleared when    |
| ---------------------- | ---------- | ------------------------------ | --------------- |
| Select Electrum Server | `critical` | No Electrum server is selected | The action runs |
| Set Admin Password     | `critical` | No admin password is set       | The action runs |

Both are reactive: they are re-raised on any init that finds the value missing, not only on a fresh install. So clearing either value brings its task back rather than leaving the service unstartable with no prompt.

`critical` blocks the service from starting and suspends the ordinary controls, so a fresh install shows the two tasks and nothing else.

## Health Checks

Two checks, one per daemon.

| Check    | Displayed as    | Method                                   | Grace Period |
| -------- | --------------- | ---------------------------------------- | ------------ |
| `server` | "Server"        | An HTTP request to a chain-data endpoint | 60s          |
| `web`    | "Web interface" | Port 3000 is listening                   | default      |

**The server's check is a real query, not a port probe** — it asks for current block headers, which only succeeds once the server has reached the Electrum server. So a failing "Server" check most often means the Electrum server is unreachable or still syncing, rather than Canary Wallet being broken.

The two daemons do not require one another, so the web interface can be up and serving while the server is not ready.

## Backups and Restore

The `main` volume is copied wholesale — `sdk.Backups.ofVolumes('main')`. That is Canary Wallet's own data plus the store, meaning the watched addresses, the Electrum selection, the admin password, the session secret, and the cached ntfy publisher all travel together.

A restored instance comes back configured and raises no tasks. It does still need its Electrum server present on the new box — the selection is restored, but the dependency has to actually be installed and running there. The restored ntfy publisher cache is cleared once before reactive watchers start. If ntfy is present and running, a publisher is provisioned for that instance; otherwise provisioning waits for ntfy to start. If ntfy is absent, its environment variables are omitted.

## Limitations and Differences

1. **An Electrum server is mandatory**, and it must be Fulcrum or Electrs — the selection is a fixed choice of the two, not an arbitrary address.
2. **Mainnet only.** The network is fixed in the package.
3. **The admin password can only be changed while stopped**, because it is read at start-up.
4. **Explorer links depend on what is installed.** With neither Mempool nor Bitcoin Explorer present, links fall back to whatever upstream defaults to.
5. **Only browser-reachable explorer addresses are used** — internal ones are filtered out, so an explorer reachable only on the bridge contributes nothing.
6. **The sync interval is fixed** and not exposed as a setting.
7. **Local ntfy is package-provisioned when ntfy is installed and running.** Saved Canary Wallet ntfy settings are not overwritten. A previously saved custom URL of `http://ntfy.startos` is no longer the detected server URL; choose the listed local ntfy option to pick up the provisioned publisher. Arbitrary private ntfy or webhook URLs are not trusted by Canary Wallet unless they match a detected integration.

---

## Quick Reference for AI Consumers

```yaml
package_id: canary
image: schjonhaug/canary-wallet-backend # plus schjonhaug/canary-wallet-frontend
architectures: as published by the image # the manifest declares no restriction
subcontainers:
  - backend-sub # the server; holds the volume
  - web-sub # the front end; mounts nothing
volumes:
  main: /app/data
file_models:
  - store.json
startos_managed_env_vars:
  - CANARY_WALLET_NETWORK
  - CANARY_WALLET_ELECTRUM_URL
  - CANARY_WALLET_BIND_ADDRESS
  - CANARY_WALLET_DATA_DIR
  - CANARY_WALLET_MODE
  - CANARY_WALLET_SELF_HOSTED_ADMIN_PASSWORD
  - CANARY_WALLET_SYNC_INTERVAL
  - JWT_SECRET
  - FRONTEND_URL
  - FRONTEND_URLS
  - CANARY_WALLET_MEMPOOL_URLS # only when mempool is installed
  - CANARY_WALLET_BTC_RPC_EXPLORER_URLS # only when bitcoin-explorer is installed
  - CANARY_WALLET_TX_EXPLORER_PLATFORM # only when either is
  - CANARY_WALLET_NTFY_SERVER_URL # ntfy bridge URL, only when ntfy is installed
  - CANARY_WALLET_NTFY_TOKEN # only after Provision Publisher succeeds
  - CANARY_WALLET_NTFY_TOPIC # only after Provision Publisher succeeds
  - API_URL # front end only
dependencies:
  - fulcrum # required only when selected; kind: running
  - electrs # required only when selected; kind: running
  - mempool # never required; explorer links only
  - bitcoin-explorer # never required; explorer links only
  - ntfy # required only while ntfy is installed; kind: exists
interfaces:
  ui: { type: ui, port: 3000 } # the server on 3001 is internal only
actions:
  - select-electrum
  - set-admin-password # only-stopped
tasks:
  - { action: select-electrum, severity: critical }
  - { action: set-admin-password, severity: critical }
health_checks:
  - server # displayed "Server"
  - web # displayed "Web interface"
```
