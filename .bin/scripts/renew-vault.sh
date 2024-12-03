#!/usr/bin/env bash
set -euo pipefail

readonly VAULT_FILE="${ROOT_DIR}/products/infra/vault/vault.yml"

function renew() {
  local previous_vault_password_file="${ROOT_DIR}/products/infra/vault/.vault-password-previous.gpg"
  local vault_password_file="${ROOT_DIR}/products/infra/vault/.vault-password.gpg"

  if [ -f "$vault_password_file" ]; then
    echo "Backuping previous vault password..."
    mv "${vault_password_file}" "${previous_vault_password_file}"
  fi

  echo "Generating new vault password..."
  bash "${SCRIPT_DIR}/generate-vault-password.sh"

  echo "Using new password to re-encrypt vault file..."
  ansible-vault rekey \
    --vault-id "previous@${SCRIPT_DIR}/get-vault-password-client.sh" \
    --new-vault-id "default@${SCRIPT_DIR}/get-vault-password-client.sh" \
    "${VAULT_FILE}"

  rm "${previous_vault_password_file}"
}

renew "$@"
