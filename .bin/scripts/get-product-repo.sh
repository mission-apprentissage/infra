#!/usr/bin/env bash

set -euo pipefail

readonly PRODUCT_NAME=${1:?"Merci le produit (sirius, monitoring)"}; shift;

readonly env_ini="${ROOT_DIR}/products/$PRODUCT_NAME/env.ini"

"${SCRIPT_DIR}/validate-product-name.sh" "${PRODUCT_NAME}"

set +e
readonly repo=$(ansible-inventory -i "${env_ini}" --list -l all | jq -r "._meta.hostvars[._meta.hostvars | keys | first].repo")
set -e

if [[ "$repo" == "" ]]; then
  >&2 echo "Repository not found";
  exit 1;
fi;

echo $repo
