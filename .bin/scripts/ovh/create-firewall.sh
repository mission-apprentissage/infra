#!/usr/bin/env bash

set -euo pipefail

readonly PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
readonly ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

function main() {
  local env_ip=$("${BIN_DIR}/mna" product:env:ip "${PRODUCT_NAME}" "${ENV_NAME}")
  if [ -z $env_ip ]; then exit 1; fi

  cd "${SCRIPT_DIR}/ovh/ovh-nodejs-client"
  yarn --silent install

  export APP_KEY=$(op item get "API OVH" --vault "devsops" --fields username)
  export APP_SECRET=$(op item get "API OVH" --vault "devsops" --fields credential)
  export TOKEN=$(op item get "API OVH" --vault "devsops" --fields token)

  yarn --silent cli createFirewall ${env_ip} "$PRODUCT_NAME" --key "${TOKEN}"
  cd - >/dev/null
}

main "$@"
