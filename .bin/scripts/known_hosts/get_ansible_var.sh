#!/usr/bin/env bash

set -euo pipefail

. "${BIN_DIR}/commands.sh"

PRODUCT_NAME=${1:?"Merci de préciser le produit (bal, tdb)"}
shift

VAR_NAME=${1:?"Merci de préciser la variable"}
shift

env_ini=$(product:ini_file "${PRODUCT_NAME}")

ansible-inventory -i "${env_ini}" --list \
  | jq -r --arg name "$VAR_NAME" '._meta.hostvars | values | map(.[$name]) | join(" ")'
