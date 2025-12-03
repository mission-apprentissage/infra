set -euo pipefail

readonly PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
readonly ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

readonly MODULE_DIR="${SCRIPT_DIR}/ovh/ovh-nodejs-client"

function main() {
  local env_ip=$("${BIN_DIR}/infra.sh" product:env:ip "${PRODUCT_NAME}" "${ENV_NAME}")
  if [ -z $env_ip ]; then exit 1; fi

  cd "${MODULE_DIR}"
  npm ci --ignore-scripts --quiet

  export APP_KEY=$(op item get "API OVH" --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}" --fields username)
  export APP_SECRET=$(op item get "API OVH" --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}" --fields credential --reveal)

  node ./index.js closeService "${env_ip}" "$PRODUCT_NAME" "$@"
  cd - >/dev/null
}

main "$@"
