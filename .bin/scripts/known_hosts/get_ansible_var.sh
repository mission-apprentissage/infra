#!/usr/bin/env bash

set -euo pipefail

if [ -z "${SCRIPT_DIR:-}" ]; then
  export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

if [ -z "${ROOT_DIR:-}" ]; then
  export ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
fi

PRODUCT_NAME=infra . "${ROOT_DIR}/.bin/commands.sh"

PRODUCT_NAME=${1:?"Merci de préciser le produit !"}
shift

VAR_NAME=${1:?"Merci de préciser la variable !"}
shift

env_ini=$(product:ini_file "${PRODUCT_NAME}")

# ansible-inventory --list ne rend pas les templates Jinja ({{ product_name }}-production).
# On passe par le module debug qui les rend, en sortie one-line parseable.
# localhost est exclu et le tri C est identique au 'jq keys' de list_ips.sh
# pour garder les deux listes alignées ip par ip.
ansible all -i "${env_ini}" -m debug -a "var=${VAR_NAME}" -o 2> /dev/null \
  | grep -v '^localhost ' \
  | LC_ALL=C sort \
  | sed 's/^[^{]*=> //' \
  | jq -rs --arg name "$VAR_NAME" 'map(.[$name]) | join(" ")'
