# Updating the upstream version

Canary Wallet ships as two coordinated upstream Docker images (`canary-wallet-frontend` and `canary-wallet-backend`) pinned by `dockerTag` in `startos/manifest/index.ts`. Both share the same Canary Wallet version and must be bumped together.

## Determining the upstream version

- **Canary Wallet** ([schjonhaug/canary](https://github.com/schjonhaug/canary-wallet)) — latest GitHub release:

  ```
  gh release view -R schjonhaug/canary-wallet --json tagName -q .tagName
  ```

  Cross-check that both Docker images have published a matching tag (image tags occasionally lead the source release):

  ```
  curl -fsSL "https://hub.docker.com/v2/repositories/schjonhaug/canary-wallet-frontend/tags?page_size=20&ordering=last_updated" | jq -r '.results[].name'
  curl -fsSL "https://hub.docker.com/v2/repositories/schjonhaug/canary-wallet-backend/tags?page_size=20&ordering=last_updated" | jq -r '.results[].name'
  ```

  Both pins live in `startos/manifest/index.ts` (`images.frontend.source.dockerTag` and `images.backend.source.dockerTag`).

## Applying the bump

- Edit `startos/manifest/index.ts` and update both `dockerTag` values to the new version:
  - `schjonhaug/canary-wallet-frontend:v<new version>`
  - `schjonhaug/canary-wallet-backend:v<new version>`
