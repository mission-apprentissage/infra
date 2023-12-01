set -euo pipefail

readonly PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
readonly ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

readonly MODULE_DIR="${SCRIPT_DIR}/ovh/ovh-nodejs-client"

function main() {
  local env_ip=$("${BIN_DIR}/mna.sh" product:env:ip "${PRODUCT_NAME}" "${ENV_NAME}")
  if [ -z $env_ip ]; then exit 1; fi

  cd "${MODULE_DIR}"
  yarn --silent install

  export APP_KEY=$(op item get "API OVH" --vault "devsops" --fields username)
  export APP_SECRET=$(op item get "API OVH" --vault "devsops" --fields credential)

  yarn --silent cli closeService "${env_ip}" "$@"
  cd - >/dev/null
}

main "$@"
