#!/usr/bin/env bash

set -euo pipefail

PRODUCT_NAME=${1:?"Merci le produit (sirius, monitoring)"}; shift;
env_ini="${ROOT_DIR}/products/$PRODUCT_NAME/env.ini"
ansible-inventory -i "${env_ini}" --list | jq -r '._meta.hostvars | keys | map(. | select(.!="localhost")) | join(" ")'
