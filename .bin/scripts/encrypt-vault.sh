#!/usr/bin/env bash
set -euo pipefail

readonly VAULT_FILE="${ROOT_DIR}/products/infra/vault/vault.yml"

ansible-vault encrypt --vault-password-file="${SCRIPT_DIR}/get-vault-password-client.sh" "${VAULT_FILE}"
