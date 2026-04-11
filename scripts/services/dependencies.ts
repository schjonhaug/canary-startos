import { types as T } from "../deps.ts";

export const dependencies: T.ExpectedExports.dependencies = {
  electrs: {
    // deno-lint-ignore require-await
    async check(_effects, _configInput) {
      return { result: null };
    },
    // deno-lint-ignore require-await
    async autoConfigure(_effects, configInput) {
      return { result: configInput };
    },
  },
  fulcrum: {
    // deno-lint-ignore require-await
    async check(_effects, _configInput) {
      return { result: null };
    },
    // deno-lint-ignore require-await
    async autoConfigure(_effects, configInput) {
      return { result: configInput };
    },
  },
};
