#!/usr/bin/env bash

set -euo pipefail

if [ -z "${SCRIPT_DIR:-}" ]; then
  export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -z "${ROOT_DIR:-}" ]; then
  export ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
fi

PRODUCT_NAME=infra . "${ROOT_DIR}/.bin/commands.sh"

PRODUCT_NAME=${1:?"Merci de préciser le produit !"}
shift

VAR_NAME=${1:?"Merci de préciser la variable !"}
shift

env_ini=$(product:ini_file "${PRODUCT_NAME}")

ansible-inventory -i "${env_ini}" --list \
  | jq -r --arg name "$VAR_NAME" '._meta.hostvars | values | map(.[$name]) | join(" ")'
