#!/usr/bin/env bash
set -euo pipefail

readonly PLAYBOOK_NAME=${1:?"Merci de préciser le playbook a éxécuter"}
shift
readonly PRODUCT_NAME=${1:?"Merci de préciser le nom du product"}
shift
readonly ENV_FILTER=${1:?"Merci de préciser un ou plusieurs environnements (ex. recette ou production)"}
shift

PRODUCT_DIR="${ROOT_DIR}/products/${PRODUCT_NAME}"

function runPlaybook() {
  echo "Lancement du playbook ${PLAYBOOK_NAME} pour ${PRODUCT_NAME}-${ENV_FILTER}..."
  
  local ansible_extra_opts=()
  if [[ $* != *"pass"* ]]; then
      local become_pass=$(op read op://Private/${PRODUCT_NAME}-$ENV_FILTER/password 2> /dev/null);
      if [ -z $become_pass ]; then
        echo "Si vous avez 1password CLI, il est possible de récupérer le password automatiquement"
        echo "Pour cela, ajouter le dans le vault "Private" l'item ${PRODUCT_NAME}-$ENV_FILTER avec le champs password"
        ansible_extra_opts+=("--ask-become-pass")
      else
        echo "Récupération du mot de passe 'become_pass' depuis 1password" 
        ansible_extra_opts+=("-e ansible_become_password='$become_pass'")
      fi;
  fi

  if [[ $* != *"--user"* ]]; then
      local username=$(op read op://Private/${PRODUCT_NAME}-$ENV_FILTER/username 2> /dev/null);
      if [ -z $username ]; then
        echo "Si vous avez 1password CLI, il est possible de récupérer le username automatiquement"
        echo "Pour cela, ajouter le dans le vault "Private" l'item ${PRODUCT_NAME}-$ENV_FILTER avec le champs username"
      else
        echo "Récupération du username depuis 1password" 
        ansible_extra_opts+=("--user" $username)
      fi;
  fi

  export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
  ansible-galaxy install patrickjahns.promtail
  ansible-galaxy install geerlingguy.docker
  ansible-galaxy collection install community.general
  ansible-galaxy collection install community.crypto
  ansible-galaxy collection install ansible.posix

  PLAYBOOKS_ROOT="${ROOT_DIR}/setup/playbooks";

  ANSIBLE_CONFIG="${PLAYBOOKS_ROOT}/ansible.cfg" ansible-playbook \
    -i "${PRODUCT_DIR}/env.ini" \
    --limit "${ENV_FILTER}" \
    --vault-password-file="${ROOT_DIR}/setup/vault/get-vault-password-client.sh" \
    "${ansible_extra_opts[@]}" \
     "${PLAYBOOKS_ROOT}/${PLAYBOOK_NAME}" "$@"
}

op document get ".vault-password-infra" --vault "mna-vault-passwords-common" --out-file="${ROOT_DIR}/setup/vault/.vault-password.gpg" --force
op document get "habilitations-${PRODUCT_NAME}" --vault "mna-vault-passwords-common" --out-file="${PRODUCT_DIR}/habilitations.yml" --force

# Do not show error log in CI
# Do not remove this behavior as displaying errors can reveal secrets
if [[ -z "${CI:-}" ]]; then
  runPlaybook "$@"
else
  runPlaybook "$@" 2> /dev/null
fi;