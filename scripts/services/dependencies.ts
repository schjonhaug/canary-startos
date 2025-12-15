import { types as T } from "../deps.ts";

export const dependencies: T.ExpectedExports.dependencies = {
  electrs: {
    // deno-lint-ignore require-await
    async check(_effects, _configInput) {
      // No specific config requirements for electrs
      return { result: null };
    },
    // deno-lint-ignore require-await
    async autoConfigure(_effects, configInput) {
      // No auto-configuration needed
      return { result: configInput };
    },
  },
};
