import { VersionInfo } from '@start9labs/start-sdk'

export const v_1_0_1_0 = VersionInfo.of({
  version: '1.0.1:0',
  releaseNotes: `Canary v1.0.1 for StartOS

* Bitcoin wallet monitoring with transaction notifications
* Support for multipath descriptors via BDK
* ntfy.sh push notifications
* Web-based wallet management interface
* Deep scanning for high address indexes
* RBF/CPFP transaction detection
* Multi-language support (English/Norwegian)`,
  migrations: {
    up: async ({ effects }) => {},
    down: async ({ effects }) => {},
  },
})
