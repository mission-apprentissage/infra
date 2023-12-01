#!/usr/bin/env bash
set -euo pipefail

readonly PRODUCT_NAME=${1:?"Merci de préciser le nom du product"}
shift

readonly env_ini="${ROOT_DIR}/products/$PRODUCT_NAME/env.ini"

if [ -f "${env_ini}" ]; then
  >&2 echo "Product $PRODUCT_NAME already exists (${env_ini})";
  return 1;
fi;

mkdir -p "${ROOT_DIR}/products/${PRODUCT_NAME}"
cp "${ROOT_DIR}/products/tmpl/env.ini" "${ROOT_DIR}/products/${PRODUCT_NAME}/env.ini"
