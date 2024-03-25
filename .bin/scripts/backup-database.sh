#!/usr/bin/env bash
set -euo pipefail

# get product name automatically ?
PRODUCT_NAME=${1:?"Merci de préciser le produit (bal, tdb, lba)"}; shift;
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VAULT_FILE="${ROOT_DIR}/.infra/vault/vault.yml"
readonly BACKUP_LOCAL_DIR="/opt/app/mongodb/backups"
readonly BACKUP_FILE="${BACKUP_LOCAL_DIR}/mongodb_$(date +%Y-%m-%d_%H-%M-%S).gpg"

function backup() {
  echo "Creating backup..."
  mkdir -p "${BACKUP_LOCAL_DIR}"
  docker run --rm mongo:6 mongodump --uri="{{ vault.${PRODUCT_NAME}.MONGODB_URI }}" -j=2 --gzip --archive \
  | bash "${SCRIPT_DIR}/gpg/encrypt.sh" "$BACKUP_FILE"
}

function uploadToS3(){
  # upload gpg file to S3
  echo "Uploading backup to S3..."
}

function deleteLocalFile(){
  # keep 5 days of archive
  echo "Removing old MongoDB backups..."
  find "${BACKUP_LOCAL_DIR}" -mindepth 1 -maxdepth 1 -prune -ctime +5 -exec rm -r "{}" \;
}

backup
uploadToS3
deleteLocalFile
