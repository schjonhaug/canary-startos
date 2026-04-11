import { compat, types as T } from "../deps.ts";

interface CanaryConfig extends T.Config {
  "electrum-server"?: {
    type?: string;
  };
}

// deno-lint-ignore require-await
export const setConfig: T.ExpectedExports.setConfig = async (
  effects: T.Effects,
  newConfig: CanaryConfig
) => {
  const server = newConfig?.["electrum-server"]?.type;
  const dependencies: Record<string, string[]> = {};
  if (server === "electrs" || server === "fulcrum") {
    dependencies[server] = [];
  }

  return compat.setConfig(effects, newConfig, dependencies);
};
