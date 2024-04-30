#!/usr/bin/env bash

set -euo pipefail

readonly PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
readonly ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

readonly env_ini="${ROOT_DIR}/products/$PRODUCT_NAME/env.ini"

"${SCRIPT_DIR}/validate-product-name.sh" "${PRODUCT_NAME}"

set +e
readonly env_ip=$(ansible-inventory -i "${env_ini}" --list -l "${ENV_NAME}" | jq -r ".${ENV_NAME}.hosts[0]")
set -e

if [[ "$env_ip" == "null" ]]; then
  >&2 echo "Environment ${ENV_NAME} not found";
  exit 1;
fi;

echo $env_ip
