# Canary

Canary monitors watch-only Bitcoin wallets and addresses. It needs a running,
fully synced Electrum server before it can look up balances and transactions.

## First-time setup

1. Install and sync either **Fulcrum** or **Electrs** on this StartOS server.
2. Open Canary's service page and resolve the **Select Electrum Server** task.
   Choose the Electrum service you installed.
3. Start Canary and wait for its health check to pass.
4. Run the **Show Login Credentials** action and save the generated password.
   The username is `admin@local`.
5. Open **Web UI**, sign in, and follow the wallet wizard to add a descriptor or
   Bitcoin address.

Canary is watch-only. It does not need seed words or private keys; do not enter
either into the application.

## Notifications

Configure notification methods and balance alerts from Canary's **Settings**
page. Use the notification test before relying on an alert for monitoring.

## Backup and recovery

Include Canary in your normal StartOS backups. Restoring its StartOS backup
restores the service data and generated login credentials.

## Documentation

- [Canary website](https://canarybitcoin.com)
- [Canary source and issue tracker](https://github.com/schjonhaug/canary)
