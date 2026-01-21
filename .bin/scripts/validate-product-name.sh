#!/usr/bin/env bash

set -euo pipefail

. "${BIN_DIR}/commands.sh"

PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}
shift

if [ "$PRODUCT_NAME" != "bal" ] \
  && [ "$PRODUCT_NAME" != "data" ] \
  ; then

  env_ini="${ROOT_DIR}/products/$PRODUCT_NAME/inventories/env.ini"

else

  env_ini="${ROOT_DIR}/products/$PRODUCT_NAME/env.ini"

fi

if [ ! -f "${env_ini}" ]; then
  >&2 echo "Product $PRODUCT_NAME not found (${env_ini})"
  return 1
fi

echo $env_ini
