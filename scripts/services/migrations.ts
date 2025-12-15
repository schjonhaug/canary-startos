import { types as T } from "../deps.ts";

export const migration: T.ExpectedExports.migration = async (_effects, _version) => {
  // No migration needed for initial version
  return { result: { configured: true } };
};
