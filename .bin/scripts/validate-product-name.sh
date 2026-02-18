#!/usr/bin/env bash

set -euo pipefail

. "${BIN_DIR}/commands.sh"

PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}
shift

if [ "$PRODUCT_NAME" != "bal" ] \
  && [ "$PRODUCT_NAME" != "data" ] \
  && [ "$PRODUCT_NAME" != "api" ] \
  && [ "$PRODUCT_NAME" != "lba" ] \
  && [ "$PRODUCT_NAME" != "monitoring" ] \
  ; then

  env_ini="${ROOT_DIR}/products/$PRODUCT_NAME/env.ini"

else

  env_ini="${ROOT_DIR}/products/$PRODUCT_NAME/inventories/env.ini"

fi

if [ ! -f "${env_ini}" ]; then
  >&2 echo "Product $PRODUCT_NAME not found (${env_ini})"
fi

echo $env_ini
