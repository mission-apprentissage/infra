set -euo pipefail

readonly PRODUCT_NAME=${1:?"Merci le produit (orion, monitoring)"}; shift;
readonly ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

readonly MODULE_DIR="${SCRIPT_DIR}/ovh/ovh-nodejs-client"

function main() {
  local env_ip=$("${BIN_DIR}/infra.sh" product:env:ip "${PRODUCT_NAME}" "${ENV_NAME}")
  if [ -z $env_ip ]; then exit 1; fi

  cd "${MODULE_DIR}"
  yarn --silent install


  VAULT=$(${SCRIPT_DIR}/view-vault.sh)

  if [[ -z "${OVH_API_APP_KEY:-}" ]]; then
    export OVH_API_APP_KEY=$(yq '.vault.OVH_API_APP_KEY' <<< "${VAULT}")
  fi;
  if [[ -z "${OVH_API_APP_SECRET:-}" ]]; then
    export OVH_API_APP_SECRET=$(yq '.vault.OVH_API_APP_SECRET' <<< "${VAULT}")
  fi;

  yarn --silent cli closeService "${env_ip}" "$PRODUCT_NAME" "$@"
  cd - >/dev/null
}

main "$@"
