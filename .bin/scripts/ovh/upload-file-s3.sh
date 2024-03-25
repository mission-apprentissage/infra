#!/usr/bin/env bash
set -euo pipefail

readonly MODULE_DIR="${SCRIPT_DIR}/ovh/ovh-nodejs-client"

cd "${MODULE_DIR}"
yarn --silent install
yarn --silent cli uploadFileToS3 "$@"
cd - >/dev/null

echo "SUCCEED"
