#!/usr/bin/env bash

set -euo pipefail

if [ -z "${SCRIPTS_DIR:-}" ]; then
  export SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -z "${ROOT_DIR:-}" ]; then
  export ROOT_DIR="$(cd "${SCRIPTS_DIR}/../.." && pwd)"
fi

PRODUCT_NAME=${1:?"Merci de préciser le produit !"}
shift

env_ini="${ROOT_DIR}/products/${PRODUCT_NAME}/inventories/env.ini"

if [ ! -f "${env_ini}" ]; then
  >&2 echo "Product ${PRODUCT_NAME} not found (${env_ini})"
fi

echo $env_ini
