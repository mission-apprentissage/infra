#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PR_NUMBER=${1:?"Merci de préciser la version local (ex. 33)"}; shift;

function deploy() {
echo "Déploiement preview"

local ansible_become_default=""
if [[ $* != *"pass"* ]]; then
    ansible_become_default="--ask-become-pass"
fi

ansible-playbook \
    -i "${SCRIPT_DIR}/../env.ini" \
    --limit "preview" \
    --vault-password-file="${SCRIPT_DIR}/vault/get-vault-password-client.sh" \
    ${ansible_become_default} \
     "${SCRIPT_DIR}/../playbooks/preview.yml" --extra-vars "pr_number=$PR_NUMBER" "$@"
}

deploy "$@"
