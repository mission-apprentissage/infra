#!/usr/bin/env bash

set -euo pipefail

. "${BIN_DIR}/commands.sh"

PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}
shift

env_ini=$(product:ini_file "${PRODUCT_NAME}")

ansible-inventory -i "${env_ini}" --list \
  | jq -r '._meta.hostvars | keys | map(. | select(.!="localhost")) | join(" ")'
