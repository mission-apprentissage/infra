#!/usr/bin/env bash
set -euo pipefail

function encrypt_file() {
  local file_path="$1"

  if [[ -z "$file_path" ]]; then
    echo "Error: File path not provided." >&2
    return 1
  fi

  if [[ ! -f "$file_path" ]]; then
    echo "Error: File not found: $file_path" >&2
    return 1
  fi

  if [[ -z "${ANSIBLE_VAULT_PASSWORD_FILE:-}" ]]; then
    ansible_extra_opts+=("--vault-password-file" "${SCRIPT_DIR}/get-vault-password-client.sh")
  else
    echo "Récupération de la passphrase depuis l'environnement variable ANSIBLE_VAULT_PASSWORD_FILE"
  fi

  readonly PASSPHRASE="$ROOT_DIR/.bin/DEPLOY_GPG_PASSPHRASE.txt"
  readonly VAULT_FILE="${ROOT_DIR}/.infra/vault/vault.yml"

  delete_cleartext() {
    rm -f "$PASSPHRASE"
  }
  trap delete_cleartext EXIT

  ansible-vault view "${ansible_extra_opts[@]}" "$VAULT_FILE" | yq '.vault.DEPLOY_GPG_PASSPHRASE' > "$PASSPHRASE"

  gpg -c --cipher-algo twofish --batch --passphrase-file "$PASSPHRASE" -o "${file_path}.gpg" "$file_path"
}

encrypt_file "$@"
