#!/usr/bin/env bash

set -euo pipefail

if [ -z "${SCRIPTS_DIR:-}" ]; then
  export SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -z "${ROOT_DIR:-}" ]; then
  export ROOT_DIR="$(cd "${SCRIPTS_DIR}/../.." && pwd)"
fi

PRODUCT_NAME=infra . "${ROOT_DIR}/.bin/commands.sh"

PRODUCT_NAME=${1:?"Merci de préciser le produit !"}
shift

VAR_NAME=${1:?"Merci de préciser la variable !"}
shift

env_ini=$(product:ini_file "${PRODUCT_NAME}")

ANSIBLE_LOAD_CALLBACK_PLUGINS=1 ANSIBLE_STDOUT_CALLBACK=ansible.posix.json \
  ansible 'all:!localhost' -i ${env_ini} --connection=local -m debug -a "var=${VAR_NAME}" \
    | jq -r '[.plays[0].tasks[0].hosts[].'"${VAR_NAME}"'] | join(" ")'
