#!/usr/bin/env bash
set -euo pipefail
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ENV_FILTER=${1:?"Merci de préciser un ou plusieurs environnements (ex. recette ou production)"}
shift

function clean() {
  echo "Nettoyage des ressources de(s) environnement(s) ${ENV_FILTER}..."
  local ansible_pass=()
  if [[ $* != *"pass"* ]]; then
    ansible_pass+=("--ask-become-pass")
  fi

  ansible-playbook -i "${SCRIPT_DIR}/../env.ini" --limit "${ENV_FILTER}" "${ansible_pass[@]}" "${SCRIPT_DIR}/../playbooks/clean.yml" "$@"
}

clean "$@"
