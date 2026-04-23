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

ENV_NAME=${1:?"Merci de préciser l'environnement !"}
shift

env_ini=$(product:ini_file "${PRODUCT_NAME}")

set +e

env_ip=$(ansible-inventory -i "${env_ini}" --list -l "${ENV_NAME}" | jq -r ".${ENV_NAME}.hosts[0]")

set -e

if [ "$env_ip" == "null" ]; then
  >&2 echo "Environment ${ENV_NAME} not found"
  exit 1
fi

echo $env_ip
