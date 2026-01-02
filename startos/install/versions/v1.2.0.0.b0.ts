import { VersionInfo } from '@start9labs/start-sdk'

export const v_1_2_0_0_b0 = VersionInfo.of({
  version: '1.2.0:0-beta.0',
  releaseNotes: `Initial release for StartOS
* Bitcoin wallet monitoring with transaction notifications
* Support for multipath descriptors (P2WPKH, P2SH, P2TR, P2PKH)
* Dedicated wallet wizard for easy onboarding
* Real-time notifications via ntfy.sh (with self-hosted server support)
* Balance alerts with configurable thresholds
* Multi-language notifications (English and Norwegian)`,
  migrations: {},
})
