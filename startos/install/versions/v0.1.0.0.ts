import { VersionInfo } from '@start9labs/start-sdk'

export const v_0_1_0_0 = VersionInfo.of({
  version: '0.1.0:0',
  releaseNotes: `Initial release for StartOS

* Bitcoin wallet monitoring with transaction notifications
* Support for multipath descriptors via BDK
* ntfy.sh push notifications
* Web-based wallet management interface`,
  migrations: {
    up: async ({ effects }) => {},
    down: async ({ effects }) => {},
  },
})
