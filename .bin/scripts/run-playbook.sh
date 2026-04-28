#!/usr/bin/env bash

set -euo pipefail

if [ -z "${SCRIPT_DIR:-}" ]; then
  export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -z "${ROOT_DIR:-}" ]; then
  export ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
fi

PRODUCT_NAME=infra . "${ROOT_DIR}/.bin/commands.sh"

PLAYBOOK_NAME=${1:?"Merci de préciser le playbook à exécuter !"}
shift

PRODUCT_NAME=${1:?"Merci de préciser le nom du produit !"}
shift

ENV_FILTER=${1:?"Merci de préciser l'environnement !"}
shift

env_ini=$(product:ini_file "${PRODUCT_NAME}")

PRODUCT_DIR="${ROOT_DIR}/products/${PRODUCT_NAME}"

install_role_if_needed() {
  local role="$1"
  local required_version="$2"

	role_line=$(ansible-galaxy role list 2>/dev/null \
		| grep "$role" \
		|| true)

	installed_version=$(echo "$role_line" \
		| awk -F', ' '{print $2}')

	older_version=$(printf '%s\n' "$required_version" "$installed_version" \
		| sort -V \
		| head -1)

  if [[ -z "$installed_version" ]]; then

    echo "Installing role $role ($required_version)..."
    ansible-galaxy install "$role,$required_version"

	elif [[ "$older_version" != "$required_version" ]]; then

    echo "Upgrading role $role ($installed_version → $required_version)..."
    ansible-galaxy install "$role,$required_version" --force

  else

    echo "Role $role already up to date ($installed_version)"

  fi

}

install_collection_if_needed() {

  local collection="$1"
  local namespace="${collection%%.*}"
  local name="${collection##*.}"

  collection_line=$(ansible-galaxy collection list 2>/dev/null \
		| grep -E "^$namespace\.$name " \
		|| true)

  installed_version=$(echo "$collection_line" \
		| awk '{print $2}')

  if [[ -z "$installed_version" ]]; then

    echo "Installing collection $collection..."
    ansible-galaxy collection install "$collection"

  else

		latest_line=$(ansible-galaxy collection info "$collection" 2>/dev/null \
			| grep "^latest version:" \
			|| true)

		latest_version=$(echo "$latest_line" \
			| awk '{print $NF}')

		older_version=$(printf '%s\n' "$latest_version" "$installed_version" \
			| sort -V \
			| head -1)

		if [[ -n "$latest_version" && "$older_version" != "$latest_version" ]]; then

      echo "Upgrading collection $collection ($installed_version → $latest_version)..."
      ansible-galaxy collection install -U "$collection"

    else

      echo "Collection $collection already up to date ($installed_version)"

    fi

  fi

}

function runPlaybook() {

  echo "Lancement du playbook ${PLAYBOOK_NAME} pour ${PRODUCT_NAME}-${ENV_FILTER}..."
  
  local ansible_extra_opts=()

  if [[ ! -z "${ANSIBLE_BECOME_PASS:-}" ]]; then
    echo "Récupération du mot de passe 'become_pass' depuis l'environnement variable ANSIBLE_BECOME_PASS" 
  else
    ansible_extra_opts+=("--ask-become-pass")
  fi

  if [[ ! -z "${ANSIBLE_REMOTE_USER:-}" ]]; then
    echo "Récupération du username depuis l'environnement variable ANSIBLE_REMOTE_USER" 
  fi

  export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

	install_role_if_needed "patrickjahns.promtail" "1.31.0"
	install_role_if_needed "geerlingguy.docker" "7.4.7"
	install_collection_if_needed "community.general"
	install_collection_if_needed "community.crypto"
	install_collection_if_needed "ansible.posix"
	install_collection_if_needed "community.sops"

  ANSIBLE_CONFIG="${ROOT_DIR}/.infra/ansible/ansible.cfg" ansible-playbook \
    -i "${ROOT_DIR}/.infra/env.ini" \
    -i "${env_ini}" \
    --limit "${ENV_FILTER}" \
    -e "product=${PRODUCT_NAME}" \
    "${ansible_extra_opts[@]}" \
    "${ROOT_DIR}/.infra/ansible/${PLAYBOOK_NAME}" \
    "$@"
}

# Do not show error log in CI
# Do not remove this behavior as displaying errors can reveal secrets
if [[ -z "${CI:-}" ]]; then
  runPlaybook "$@"
else
  runPlaybook "$@" &> /tmp/deploy.log
fi
