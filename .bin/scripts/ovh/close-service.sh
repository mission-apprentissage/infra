#!/usr/bin/env bash

set -euo pipefail

if [ -z "${SCRIPT_DIR:-}" ]; then
  export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -z "${ROOT_DIR:-}" ]; then
  export ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
fi

readonly PRODUCT_NAME=${1:?"Merci de préciser le produit !"}
shift

readonly ENV_NAME=${1:?"Merci de préciser l'environnement !"}
shift

readonly MODULE_DIR="${SCRIPT_DIR}/ovh/ovh-nodejs-client"

install_npm_if_needed() {

  if [[ ! -f "$LOCK_FILE" ]]; then
    echo "WARNING: $LOCK_FILE not found, skipping npm ci"
    return
  fi

	current_hash=$(openssl dgst -md5 "$LOCK_FILE" | awk '{print $2}')

  if [[ ! -d "node_modules" ]]; then
    echo "node_modules missing, running npm ci..."
  elif [[ ! -f "$LOCK_HASH_FILE" ]] || [[ "$current_hash" != "$(cat "$LOCK_HASH_FILE")" ]]; then
    echo "package-lock.json changed, running npm ci..."
  else
    echo "node_modules already up to date"
    return
  fi

  npm ci --ignore-scripts --quiet && echo "$current_hash" > "$LOCK_HASH_FILE"
}

function main() {

  local env_ip=$("${BIN_DIR}/infra.sh" product:env:ip "${PRODUCT_NAME}" "${ENV_NAME}")

  if [ -z $env_ip ]; then
    exit 1
  fi

  cd "${MODULE_DIR}"
	install_npm_if_needed

  if [[ -z "${APP_KEY:-}" ]]; then
    export APP_KEY=$(sops --decrypt --extract '["OVH_API_KEY"]' "${ROOT_DIR}/.infra/env.global.yml")
  fi

  if [[ -z "${APP_SECRET:-}" ]]; then
    export APP_SECRET=$(sops --decrypt --extract '["OVH_API_SECRET"]' "${ROOT_DIR}/.infra/env.global.yml")
  fi

  if [[ -z "${APP_TOKEN:-}" ]]; then
    export APP_TOKEN=$(sops --decrypt --extract '["OVH_API_TOKEN"]' "${ROOT_DIR}/.infra/env.global.yml")
  fi

  node ./index.js closeService "${env_ip}" "$PRODUCT_NAME" "$@"
  cd - >/dev/null
}

main "$@"
