#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PRODUCT_NAME=${1:?"Merci de préciser le nom du product"}
shift
readonly HABILITATIONS_FILE="${SCRIPT_DIR}/../../../products/${PRODUCT_NAME}/habilitations.yml"
readonly VAULT_PASSWORD_FILE="${SCRIPT_DIR}/../../../products/${PRODUCT_NAME}/.vault-password.gpg"


# TODO pas beaux ! 
case $PRODUCT_NAME in
    tdb)
         REPO_NAME="flux-retour-cfas"
        ;;
    lba)
         REPO_NAME="labonnealternance"
        ;;
    *)
        REPO_NAME=$PRODUCT_NAME
        ;;
esac

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

#  # ===> set dans infra
#   gh secret set "${PRODUCT_NAME}_vault_password" --body "$(cat "${VAULT_PASSWORD_FILE}")"   
#   # ===> set dans bal (utile pour le deploy)
  gh secret set "VAULT_PWD" --body "$(cat "${VAULT_PASSWORD_FILE}")" --repo "https://github.com/mission-apprentissage/${REPO_NAME}" 

  op document delete "habilitations-${PRODUCT_NAME}" --vault "mna-vault-passwords-common"
  cat "${HABILITATIONS_FILE}" | op document create - --title "habilitations-${PRODUCT_NAME}" --file-name "habilitations-${PRODUCT_NAME}.yml" --vault "mna-vault-passwords-common"

  rm "${VAULT_PASSWORD_FILE}"
  rm "${HABILITATIONS_FILE}"
}

if [ ! -f "$HABILITATIONS_FILE" ]; then
    DOCUMENT_CONTENT=$(op document get "habilitations-${PRODUCT_NAME}" --vault "mna-vault-passwords-common" || echo "") 
    echo "$DOCUMENT_CONTENT" > "$HABILITATIONS_FILE"
fi

code -w "${HABILITATIONS_FILE}"

create_password_file
