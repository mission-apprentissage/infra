#!/usr/bin/env bash

set -euo pipefail

function product:ini_file() {
  readonly PRODUCT_NAME=${1:?"Merci le produit (sirius, monitoring)"}; shift;
  readonly env_ini="${ROOT_DIR}/products/$PRODUCT_NAME/env.ini"

  if [ ! -f "${env_ini}" ]; then
    >&2 echo "Product $1 not found (${env_ini})";
    exit 1;
  fi;

  echo $env_ini
}
