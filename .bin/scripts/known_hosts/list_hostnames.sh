#!/usr/bin/env bash

set -euo pipefail

PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
env_ini="${ROOT_DIR}/products/$PRODUCT_NAME/env.ini"
ansible-inventory -i "${env_ini}" --list | jq -r '._meta.hostvars | values | map(.host_name) | join(" ")'
