import { ensureCredentials } from '../credentials'
import { sdk } from '../sdk'

export const showLoginCredentials = sdk.Action.withoutInput(
  'show-login-credentials',

  async ({ effects }) => ({
    name: 'Show Login Credentials',
    description: 'Reveal the Canary admin username and password',
    warning: null,
    allowedStatuses: 'any',
    group: null,
    visibility: 'enabled',
  }),

  async ({ effects }) => {
    const credentials = await ensureCredentials(effects)

    return {
      version: '1',
      title: 'Canary Login Credentials',
      message: 'Use these credentials to sign in to Canary.',
      result: {
        type: 'group',
        value: [
          {
            name: 'Username',
            description: null,
            type: 'single',
            value: 'admin@local',
            copyable: true,
            qr: false,
            masked: false,
          },
          {
            name: 'Password',
            description: null,
            type: 'single',
            value: credentials.adminPassword,
            copyable: true,
            qr: false,
            masked: true,
          },
        ],
      },
    }
  },
)
