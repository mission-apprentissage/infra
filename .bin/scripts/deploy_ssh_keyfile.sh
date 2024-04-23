#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${ANSIBLE_VAULT_PASSWORD_FILE:-}" ]]; then
  ansible_extra_opts+=("--vault-password-file" "${SCRIPT_DIR}/get-vault-password-client.sh")
else
  echo "Récupération de la passphrase depuis l'environnement variable ANSIBLE_VAULT_PASSWORD_FILE" 
fi

readonly KEYFILE="$ROOT_DIR/.bin/id_rsa_deploy.key"
readonly VAULT_FILE="${ROOT_DIR}/.infra/vault/vault.yml"

ansible-vault view "${ansible_extra_opts[@]}" "$VAULT_FILE" | yq '.vault.MNA_GH_USER_PRIVATE_KEY' > "$KEYFILE"
chmod 600 "$KEYFILE"
