import { types as T } from "../deps.ts";

// deno-lint-ignore require-await
export const migration: T.ExpectedExports.migration = async (_effects, _version) => {
  return { result: { configured: true } };
};
