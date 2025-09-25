#!/usr/bin/env bash

set -euo pipefail

PRODUCT_NAME=${1:?"Merci de préciser le produit (bal, tdb)"}; shift;
VAR_NAME=${1:?"Merci de préciser la variable"}; shift;
ENV_NAME=${1:-""}; shift;
env_ini="${ROOT_DIR}/products/$PRODUCT_NAME/env.ini"

if [[ -z "$ENV_NAME" ]]; then
ansible-inventory -i "${env_ini}" --list | jq -r --arg name "$VAR_NAME" '._meta.hostvars | values | map(.[$name]) | join(" ")'
else
  ansible-inventory -i "${env_ini}" --list -l "${ENV_NAME}" | jq -r --arg name "$VAR_NAME" '._meta.hostvars | values | map(.[$name]) | join(" ")'
fi;
