// Bundle Deno scripts into a single JavaScript file for StartOS
import { bundle } from "https://deno.land/x/emit@0.31.4/mod.ts";

const result = await bundle(new URL("./embassy.ts", import.meta.url));
const { code } = result;

await Deno.writeTextFile("scripts/embassy.js", code);
console.log("Bundled embassy.ts -> scripts/embassy.js");
