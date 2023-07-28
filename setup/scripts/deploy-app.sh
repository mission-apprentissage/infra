#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ENV_FILTER=${1:?"Merci de préciser un ou plusieurs environnements (ex. recette ou production)"}
shift

function deploy() {
echo "Déploiement sur l'(es) environnement(s) ${ENV_FILTER}..."

local ansible_become_default=""
if [[ $* != *"pass"* ]]; then
    ansible_become_default="--ask-become-pass"
fi

ansible-playbook \
    -i "${SCRIPT_DIR}/../env.ini" \
    --limit "${ENV_FILTER}" \
    --vault-password-file="${SCRIPT_DIR}/vault/get-vault-password-client.sh" \
    ${ansible_become_default} \
     "${SCRIPT_DIR}/../playbooks/deploy.yml" "$@"
}

deploy "$@"
