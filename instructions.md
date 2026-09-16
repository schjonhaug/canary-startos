# Canary Wallet

## Documentation

- [Canary Wallet upstream README](https://github.com/schjonhaug/canary-wallet#readme) — features, supported wallet types, and notification options.
- [Canary Wallet issue tracker](https://github.com/schjonhaug/canary-wallet/issues) — bugs and feature requests.

## What you get on StartOS

- A **Web UI** for Canary Wallet on the bundled `ui` interface.
- A watch-only monitor that looks up your wallets through your own local Electrum server — **Fulcrum** or **Electrs**. Addresses never leave your StartOS.
- A built-in admin account whose password is generated and rotated by a StartOS action.

## Getting set up

1. Install **Fulcrum** or **Electrs** on StartOS and let it fully sync. Canary Wallet will not start until one is selected and running.
2. On first install, StartOS posts a critical **Set Admin Password** task. Run it and copy the generated password to a password manager — you'll need it to sign in.
3. Run the **Select Electrum Server** action and pick which dependency Canary Wallet should talk to (defaults to Fulcrum).
4. Open the **Web UI** and sign in with the password from step 2.

## Using Canary Wallet

### Adding a wallet

1. In the Web UI, click **Add Wallet**.
2. Give it a name (e.g. "Cold Storage", "Hardware Wallet").
3. Paste your **extended public key** (xpub / ypub / zpub) or **output descriptor**.
4. Click **Create**. The wallet begins syncing — initial scans for wallets with deep address indexes can take a few minutes; Canary Wallet detects high indexes automatically.

Canary Wallet is watch-only — it only consumes public keys, never holds them, and cannot spend.

### Notifications

Each wallet contact can use one or more notification methods:

- **ntfy** sends push notifications through [ntfy.sh](https://ntfy.sh) or a self-hosted ntfy server.
- **Nostr DM** sends encrypted direct messages to an npub or hex public key. Canary Wallet supports modern NIP-17 and legacy NIP-04 delivery modes.
- **JSON webhook** sends structured self-hosted events to an HTTP or HTTPS endpoint reachable from the Canary Wallet backend. Use the contact editor's test button before saving.

For every contact, choose which transaction stages and special events to send: incoming or outgoing pending transactions, confirmations, RBF replacements, and CPFP relationships. Content controls are also per notification method, so you decide whether a message may disclose the wallet name, event type, transaction amount or balance, and balance-alert condition, threshold, or current balance.

To use public ntfy push notifications:

1. Install the ntfy app ([Android](https://play.google.com/store/apps/details?id=io.heckel.ntfy) / [iOS](https://apps.apple.com/app/ntfy/id1625396347)) and subscribe to a topic of your choice.
2. In Canary Wallet, add a contact, enable **ntfy**, and paste the same topic.
3. Use the inline test before saving the contact.

#### Using the StartOS ntfy service (optional)

Install Start9's **ntfy** package either before or after Canary Wallet. When ntfy is installed and running, Canary Wallet provisions a local publisher for you and uses it as the default ntfy server. Settings you have already saved in Canary Wallet are not overwritten, and wallet contacts are still created by you.

1. Install **ntfy** and let it finish starting. Canary Wallet detects ntfy automatically, including when installed later.
2. In Canary Wallet's settings, choose the local **ntfy** server if it is not already selected. The default topic is `canary`.
3. In ntfy, run **Create User**, then **Grant User Topic Access** to give that user **read-only** access to `canary` (or your chosen topic).
4. On your phone, point the ntfy app at your StartOS ntfy package's **public** address (LAN or Tor, the same one you'd open in a browser) and subscribe to that topic with a user that has read access.

Use the contact editor's test button before saving. Canary Wallet does not create wallet contacts automatically.

If you previously pasted `http://ntfy.startos` as a custom URL, switch to the listed local ntfy option so Canary Wallet uses the provisioned publisher.

You can still provision by hand if you prefer: on ntfy, run **Provision Publisher** with publisher ID `canary` and the topic you want, then paste the returned URL, token, and topic into Canary Wallet's settings.

For a JSON webhook, enter the receiver's complete URL in the contact editor. The request originates from Canary Wallet's backend container, not your browser, so `localhost` refers to Canary Wallet itself. Treat URL paths and query strings as secrets even though collapsed contact summaries show only the origin.

### Balance alerts

Set per-wallet thresholds in the Web UI to fire when a balance goes **above**, **below**, or **equals** a target amount. Alerts use the same push channel as transaction notifications.

### Actions

- **Select Electrum Server** — pick **Fulcrum** or **Electrs** as Canary Wallet's address-lookup backend. Re-run any time to switch.
- **Set Admin Password** — generate a new random password for the built-in admin account. Stop Canary Wallet before running it to rotate or recover access.
