import { readdir, readFile } from "fs/promises";
import { __dirname } from "./utils.js";
import { join } from "path";
import { parse } from "ini";

// Récupération des associations de produits et de leurs IPs
export default async function getConfig() {
  const productDir = join(__dirname(import.meta.url), "..", "..", "..", "..", "products");
  const files = await readdir(productDir, { withFileTypes: true });

  const config = {};
  for (const file of files) {
    if (file.isDirectory() && file.name !== "infra") {
      const data = await readFile(join(productDir, file.name, "env.ini"), "utf-8");
      const env = parse(data);
      for (const key of Object.keys(env)) {
        if (key.endsWith(":vars")) {
          continue;
        }

        const ips = Object.keys(env[key]).filter((v) => /^\d+\.\d+\.\d+\.\d+$/.test(v));
        if (ips.length === 0) {
          continue;
        }
        config[`${file.name}-${key}`] = ips;
      }
    }
  }

  return config;
}
