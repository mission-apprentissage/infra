#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PRODUCT_NAME=${1:?"Merci de préciser le nom du product"}
shift
readonly HABILITATIONS_FILE="${SCRIPT_DIR}/../../../products/${PRODUCT_NAME}/habilitations.yml"
readonly VAULT_PASSWORD_FILE="${SCRIPT_DIR}/../../../products/${PRODUCT_NAME}/.vault-password.gpg"

function create_password_file() {
  local recipients=()
  local password
  password="$(pwgen -n 71 -C | head -n1)"

  echo "Extracting gpg keys from habilitations file..."
  mapfile -t keys < <(grep "gpg_key:" "${HABILITATIONS_FILE}" | awk -F ":" '{print $2}' | sed '/^$/d' | tr -d ' ')

  echo "Fetching gpg keys and add them as a recipients..."
  for key in "${keys[@]}"; do
    echo $key
    gpg --keyserver keyserver.ubuntu.com --quiet --recv-keys "$key"
    recipients+=("--recipient $key")
  done

  echo "Generating vault password..."
  echo "${password}" | gpg --quiet --always-trust --armor ${recipients[*]} -e -o "${VAULT_PASSWORD_FILE}"

  op document delete ".vault-password-${PRODUCT_NAME}" --vault "mna-vault-passwords-common"
  cat "${VAULT_PASSWORD_FILE}" | op document create - --title ".vault-password-${PRODUCT_NAME}" --file-name ".vault-password-${PRODUCT_NAME}.gpg" --vault "mna-vault-passwords-common"

  rm "${VAULT_PASSWORD_FILE}"
}


create_password_file
