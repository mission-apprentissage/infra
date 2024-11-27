#!/usr/bin/env bash

set -euo pipefail

readonly PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
readonly ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

function main() {
  local env_ip=$("${BIN_DIR}/infra" product:env:ip "${PRODUCT_NAME}" "${ENV_NAME}")
  if [ -z $env_ip ]; then exit 1; fi

  cd "${SCRIPT_DIR}/ovh/ovh-nodejs-client"
  npm install --quiet

  if [[ -z "${APP_KEY:-}" ]]; then
    export APP_KEY=$(op item get "API OVH" --vault "devsops" --account "${OP_ACCOUNT}" --fields username)
  fi;
  if [[ -z "${APP_SECRET:-}" ]]; then
    export APP_SECRET=$(op item get "API OVH" --vault "devsops" --account "${OP_ACCOUNT}" --fields credential --reveal)
  fi;
  if [[ -z "${APP_TOKEN:-}" ]]; then
    export APP_TOKEN=$(op item get "API OVH" --vault "devsops" --account "${OP_ACCOUNT}" --fields token --reveal)
  fi;

  node ./index.js createFirewall ${env_ip} "$PRODUCT_NAME" "${ENV_NAME}" --key "${APP_TOKEN}"
  cd - >/dev/null
}

main "$@"
