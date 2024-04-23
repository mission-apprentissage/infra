import { readdir, readFile } from 'fs/promises';
import { __dirname } from './utils.js';
import { join } from 'path';
import { parse } from 'ini';


export default async function getConfig() {
    const productDir = join(__dirname(import.meta.url), '..', '..', '..', '..', 'products');
    const files = await readdir(productDir, { withFileTypes: true });

    const config = {};
    for (const file of files) {
        if (file.isDirectory()) {
            const data = await readFile(join(productDir, file.name, 'env.ini'), 'utf-8');
            const env = parse(data);
            for (const key of Object.keys(env)) {
                if (key.endsWith(':vars')) {
                    continue;
                }

                const ips = Object.keys(env[key]).filter(v => /^\d+\.\d+\.\d+\.\d+$/.test(v));
                if (ips.length === 0) {
                    continue;
                }
                config[`${file.name}-${key}`] = ips
            }
        }
    }

    return config;
}
