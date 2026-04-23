#!/usr/bin/env bash

set -euo pipefail

if [ -z "${SCRIPT_DIR:-}" ]; then
  export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -z "${ROOT_DIR:-}" ]; then
  export ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
fi

readonly KEYFILE="$ROOT_DIR/.bin/id_rsa_deploy.key"

sops --decrypt --extract '["GH_USER_PRIVATE_KEY"]' .infra/env.global.yml > "$KEYFILE"

chmod 600 "$KEYFILE"
