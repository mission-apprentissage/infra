#!/usr/bin/env bash

set -euo pipefail

. "${BIN_DIR}/commands.sh"

PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}
shift

env_ini=$(product:ini_file "${PRODUCT_NAME}")

"${SCRIPT_DIR}/validate-product-name.sh" "${PRODUCT_NAME}"

set +e

repo=$(ansible-inventory -i "${env_ini}" --list -l all | jq -r "._meta.hostvars[._meta.hostvars | keys | first].repo")

set -e

if [ "$repo" == "" ]; then
  >&2 echo "Repository not found"
  exit 1
fi

echo $repo
