#!/usr/bin/env bash

set -euo pipefail

readonly PRODUCT_NAME=${1:?"Merci le produit (sirius, monitoring)"}; shift;
readonly ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

function main() {
  local env_ip=$("${BIN_DIR}/infra" product:env:ip "${PRODUCT_NAME}" "${ENV_NAME}")
  if [ -z $env_ip ]; then exit 1; fi

  cd "${SCRIPT_DIR}/ovh/ovh-nodejs-client"
  yarn --silent install

  VAULT=$(${SCRIPT_DIR}/view-vault.sh)

  if [[ -z "${OVH_API_APP_KEY:-}" ]]; then
    export OVH_API_APP_KEY=$(yq '.vault.OVH_API_APP_KEY' <<< "${VAULT}")
  fi;
  if [[ -z "${OVH_API_APP_SECRET:-}" ]]; then
    export OVH_API_APP_SECRET=$(yq '.vault.OVH_API_APP_SECRET' <<< "${VAULT}")
  fi;
  if [[ -z "${OVH_API_APP_TOKEN:-}" ]]; then
    export OVH_API_APP_TOKEN=$(yq '.vault.OVH_API_APP_TOKEN' <<< "${VAULT}")
  fi;

  yarn --silent cli createFirewall ${env_ip} "$PRODUCT_NAME" "${ENV_NAME}" --key "${OVH_API_APP_TOKEN}"
  cd - >/dev/null
}

main "$@"
