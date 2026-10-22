#!/usr/bin/env bash

set -euo pipefail

if [ -z "${SCRIPTS_DIR:-}" ]; then
  export SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -z "${ROOT_DIR:-}" ]; then
  export ROOT_DIR="$(cd "${SCRIPTS_DIR}/../.." && pwd)"
fi

PRODUCT_NAME=infra . "${ROOT_DIR}/.bin/commands.sh"

PRODUCT_NAME=${1:?"Merci de préciser le nom du produit !"}
shift

env_ini=$(_dispatch "product:ini_file" "${PRODUCT_NAME}")

if [ -f "${env_ini}" ]; then
  >&2 echo "Product $PRODUCT_NAME already exists (${env_ini})"
  return 1
fi

mkdir -p "${ROOT_DIR}/products/${PRODUCT_NAME}"
