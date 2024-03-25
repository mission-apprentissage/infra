#!/usr/bin/env bash
set -euo pipefail

# get product name automatically ?
PRODUCT_NAME=${1:?"Merci de préciser le produit (bal, tdb, lba)"}; shift;
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VAULT_FILE="${ROOT_DIR}/.infra/vault/vault.yml"
readonly BACKUP_LOCAL_DIR="/opt/app/mongodb/backups"
readonly BACKUP_FILE="${BACKUP_LOCAL_DIR}/mongodb_$(date +%Y-%m-%d_%H-%M-%S).gpg"

# Ansible vault password retrieval
if [[ -z "${ANSIBLE_VAULT_PASSWORD_FILE:-}" ]]; then
  ansible_extra_opts+=("--vault-password-file" "${SCRIPT_DIR}/get-vault-password-client.sh")
else
  echo "Récupération de la passphrase depuis l'environnement variable ANSIBLE_VAULT_PASSWORD_FILE"
fi

# Get MONGODB_URI from Ansible Vault
readonly MONGODB_URI=$(ansible-vault view "${ansible_extra_opts[@]}" "$VAULT_FILE" | yq ".vault.${PRODUCT_NAME}.MONGODB_URI")

# Error handling for empty MONGODB_URI
if [[ -z "$MONGODB_URI" ]]; then
  echo "Error: MONGODB_URI not found in Ansible Vault." >&2
  exit 1
fi

# Run mongodump with captured URI and redirect output for encryption
docker run --rm mongo:6 mongodump --uri="$MONGODB_URI" -j=2 --gzip --archive | source "${SCRIPT_DIR}/encrypt_script.sh" "$BACKUP_FILE"

# Handle errors from the encryption script (exit code non-zero)
if [[ $? -ne 0 ]]; then
  echo "Error: Encryption failed." >&2
  exit 1
fi

echo "MongoDB backup created and encrypted: $BACKUP_FILE"
