#!/usr/bin/env bash
set -euo pipefail

readonly HABILITATIONS_FILE="${ROOT_DIR}/products/infra/vault/habilitations.yml"
readonly VAULT_PASSWORD_FILE="${ROOT_DIR}/products/infra/vault/.vault-password-next.gpg"

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

  local pass_exist=$(op document list --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}" | grep ".vault-password-infra")
  if [[ "$pass_exist" != "" ]]; then
    cat "${VAULT_PASSWORD_FILE}" | op document edit ".vault-password-infra" - --file-name ".vault-password-infra.gpg" --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}"
  else
    cat "${VAULT_PASSWORD_FILE}" | op document create - --title ".vault-password-infra" --file-name ".vault-password-infra.gpg" --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}"
  fi;

  gh secret set "VAULT_PWD" --body "$password"

  local habilitations_exist=$(op document list --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}" | grep "habilitations-infra")
  if [[ "$habilitations_exist" != "" ]]; then
    cat "${HABILITATIONS_FILE}" | op document edit "habilitations-infra" - --file-name "habilitations-infra.yml" --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}"
  else
    cat "${HABILITATIONS_FILE}" | op document create - --title "habilitations-infra" --file-name "habilitations-infra.yml" --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}"
  fi;

  rm "${VAULT_PASSWORD_FILE}"
  rm "${HABILITATIONS_FILE}"
}

DOCUMENT_CONTENT=$(op document get "habilitations-infra" --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}" || echo "") 
echo "$DOCUMENT_CONTENT" > "$HABILITATIONS_FILE"

$EDITOR "${HABILITATIONS_FILE}"

create_password_file
