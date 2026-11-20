#!/usr/bin/env bash

set -euo pipefail

if [ -z "${SCRIPTS_DIR:-}" ]; then
  export SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -z "${ROOT_DIR:-}" ]; then
  export ROOT_DIR="$(cd "${SCRIPTS_DIR}/../.." && pwd)"
fi

readonly KEYFILE="$ROOT_DIR/.bin/id_rsa_deploy.key"

sops --decrypt --extract '["GH_USER_PRIVATE_KEY"]' .infra/env.global.yml > "$KEYFILE"

chmod 600 "$KEYFILE"
