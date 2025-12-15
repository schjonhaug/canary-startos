import { types as T } from "../deps.ts";

export const properties: T.ExpectedExports.properties = async (_effects) => {
  return {
    type: "object",
    value: {
      "Service Status": {
        type: "string",
        value: "Running",
        description: "Current status of the Canary service",
        copyable: false,
        qr: false,
        masked: false,
      },
    },
  } as T.Properties;
};
