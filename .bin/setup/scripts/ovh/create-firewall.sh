#!/usr/bin/env bash

set -euo pipefail

readonly PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
readonly ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;
readonly APP_KEY=${1:?"Merci de préciser l'application key OVH (ex. recette ou production)"}; shift;
readonly APP_SECRET=${1:?"Merci de préciser l'application secret OVH (ex. recette ou production)"}; shift;

function main() {
  local env_ini="${ROOT_DIR}/products/${PRODUCT_NAME}/env.ini"
  if [ ! -f "${env_ini}" ]; then
    echo "Product ${PRODUCT_NAME} not found (${env_ini})";
    exit 1;
  fi;

  set +e
  local env_ip=$(grep "\[${ENV_NAME}\]" -A 1 "${env_ini}" | tail -1)
  set -e
  if [[ "$env_ip" == "" ]]; then
    echo "Environement ${ENV_NAME} not found";
    exit 1;
  fi;

  if [[ "$env_ip" == "" ]]; then
    echo "Environement ${ENV_NAME} not found";
    exit 1;
  fi;

  cd "${SETUP_SCRIPTS_DIR}/ovh/ovh-nodejs-client"
  yarn install
  export APP_KEY
  export APP_SECRET
  yarn cli createFirewall "${env_ip}" "$@"
  cd - >/dev/null
}

main "$@"
