#!/usr/bin/env bash

set -euo pipefail

if [ -z "${SCRIPT_DIR:-}" ]; then
  export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -z "${ROOT_DIR:-}" ]; then
  export ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
fi

PRODUCT_NAME=infra . "${ROOT_DIR}/.bin/commands.sh"

PRODUCT_NAME=${1:?"Merci de préciser le produit !"}
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
