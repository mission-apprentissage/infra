#!/usr/bin/env bash

set -euo pipefail

. "${BIN_DIR}/commands.sh"

PRODUCT_NAME=${1:?"Merci de préciser le nom du product"}
shift

env_ini=$(product:ini_file "${PRODUCT_NAME}")

if [ -f "${env_ini}" ]; then
  >&2 echo "Product $PRODUCT_NAME already exists (${env_ini})"
  return 1
fi

if [ "$PRODUCT_NAME" != "bal" ] \
  && [ "$PRODUCT_NAME" != "data" ] \
  && [ "$PRODUCT_NAME" != "api" ] \
  ; then

  mkdir -p "${ROOT_DIR}/products/${PRODUCT_NAME}"

fi

