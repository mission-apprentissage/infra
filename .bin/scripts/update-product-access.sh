#!/usr/bin/env bash
set -euo pipefail

readonly PRODUCT_NAME=${1:?"Merci de préciser le nom du product"}
shift
readonly HABILITATIONS_FILE="${ROOT_DIR}/products/${PRODUCT_NAME}/habilitations.yml"
readonly HABILITATIONS_TEMPFILE="/tmp/${PRODUCT_NAME}-habilitations.yml"
readonly VAULT_PASSWORD_FILE="${ROOT_DIR}/products/${PRODUCT_NAME}/.vault-password.gpg"

readonly REPO_NAME=$("${SCRIPT_DIR}/get-product-repo.sh" "${PRODUCT_NAME}")

function create_password_file() {
  local recipients=()
  local password
  password="$(pwgen -n 71 -C | head -n1)"

  echo "Extracting gpg keys from habilitations file..."
  mapfile -t keys < <(sed -n '/gpg_keys/,/authorized_keys/p' "${HABILITATIONS_FILE}" | grep -Ev "gpg_keys|authorized_keys" | awk -F "-" '{print $2}' | tr -d ' ')

  echo "Fetching gpg keys and add them as a recipients..."
  for key in "${keys[@]}"; do
    echo $key
    gpg --keyserver hkp://keyserver.ubuntu.com --quiet --recv-keys "$key"
    recipients+=("--recipient $key")
  done

  echo "Generating vault password..."

  echo "${password}" | gpg --quiet --always-trust --armor ${recipients[*]} -e -o "${VAULT_PASSWORD_FILE}"

  local pass_exist=$(op document list --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}" | grep ".vault-password-${PRODUCT_NAME}")
  if [[ "$pass_exist" != "" ]]; then
    cat "${VAULT_PASSWORD_FILE}" | op document edit ".vault-password-${PRODUCT_NAME}" - --file-name ".vault-password-${PRODUCT_NAME}.gpg" --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}"
  else
    cat "${VAULT_PASSWORD_FILE}" | op document create - --title ".vault-password-${PRODUCT_NAME}" --file-name ".vault-password-${PRODUCT_NAME}.gpg" --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}"
  fi;

#  # ===> set dans infra
  gh secret set "${PRODUCT_NAME}_VAULT_PWD" --body "${password}" --repo "${REPO_INFRA}"
#   # ===> set dans bal (utile pour le deploy)
  gh secret set "VAULT_PWD" --body "$password" --repo "https://github.com/${REPO_NAME}" 

  local habilitations_exist=$(op document list --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}" | grep "habilitations-${PRODUCT_NAME}")
  if [[ "$habilitations_exist" != "" ]]; then
    cat "${HABILITATIONS_FILE}" | op document edit "habilitations-${PRODUCT_NAME}" - --file-name "habilitations-${PRODUCT_NAME}.yml" --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}"
  else
    cat "${HABILITATIONS_FILE}" | op document create - --title "habilitations-${PRODUCT_NAME}" --file-name "habilitations-${PRODUCT_NAME}.yml" --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}"
  fi;

  cat "${HABILITATIONS_FILE}" | gh secret set "HABILITATIONS" --repo "https://github.com/${REPO_NAME}"
  cat "${HABILITATIONS_FILE}" | gh secret set "${PRODUCT_NAME}_HABILITATIONS" --repo "${REPO_INFRA}"

  rm "${VAULT_PASSWORD_FILE}"
  rm "${HABILITATIONS_FILE}"
}

DOCUMENT_CONTENT=$(op document get "habilitations-${PRODUCT_NAME}" --vault "${OP_VAULT_PASSWORD}" --account "${OP_ACCOUNT}" || echo "")
echo "$DOCUMENT_CONTENT" > "$HABILITATIONS_FILE"
cp "$HABILITATIONS_FILE" "$HABILITATIONS_TEMPFILE"

$EDITOR "${HABILITATIONS_TEMPFILE}"

if ! cmp -s "${HABILITATIONS_TEMPFILE}" "${HABILITATIONS_FILE}"; then
  mv "$HABILITATIONS_TEMPFILE" "$HABILITATIONS_FILE"
  create_password_file
fi

