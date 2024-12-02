set -euo pipefail

readonly MODULE_DIR="${SCRIPT_DIR}/ovh/ovh-nodejs-client"

cd "${MODULE_DIR}"
npm install --quiet
node ./index.js cli ping "$@"
cd - >/dev/null

echo "SUCCEED"
