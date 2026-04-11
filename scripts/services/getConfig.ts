import { compat, types as T } from "../deps.ts";

export const getConfig: T.ExpectedExports.getConfig = compat.getConfig({
  "electrum-server": {
    "name": "Electrum Server",
    "description": "Select the Electrum server to use for syncing wallet data",
    "type": "union",
    "tag": {
      "id": "type",
      "name": "Select Electrum Server",
      "variant-names": {
        "electrs": "Electrs",
        "fulcrum": "Fulcrum",
      },
      "description": "Select the Electrum server you want to use for syncing wallet data from the Bitcoin blockchain",
    },
    "default": "electrs",
    "variants": {
      "electrs": {},
      "fulcrum": {},
    },
  },
});
