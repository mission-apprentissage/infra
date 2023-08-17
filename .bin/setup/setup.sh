#!/usr/bin/env bash

set -euo pipefail

export SETUP_SCRIPTS_DIR="$ROOT_DIR/.bin/setup/scripts"

function validateProductNameAndEnv() {
  local env_ini="${ROOT_DIR}/products/$1/env.ini"

  if [ ! -f "${env_ini}" ]; then
    echo "Product $1 not found (${env_ini})";
    exit 1;
  fi;

  set +e
  local env_name="\[$2\]";
  local env_ip=$(ansible-inventory -i"${env_ini}" --list -l "${env_name}" | jq ".${env_name}.hosts[0]")
  
  set -e
  if [[ "$env_ip" == "" ]]; then
    echo "Environment $2 not found";
    exit 1;
  fi;

  echo $env_ip
}

function firewall:setup() {
  local PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
  local ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

  validateProductNameAndEnv "$PRODUCT_NAME" "$ENV_NAME"

  "$SETUP_SCRIPTS_DIR/ovh/create-firewall.sh" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

function system:setup() {
  local PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
  local ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

  validateProductNameAndEnv "$PRODUCT_NAME" "$ENV_NAME"

  "$SETUP_SCRIPTS_DIR/run-playbook.sh" "setup.yml" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

function system:setup:initial() {
  system:setup "$@" --user ubuntu --ask-pass 
}

function system:user:remove() {
  local PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
  local ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

  validateProductNameAndEnv "$PRODUCT_NAME" "$ENV_NAME"

  "$SETUP_SCRIPTS_DIR/run-playbook.sh" "clean.yml" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

function ssh:known_hosts:print() {
  local PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
  local ips=$("${ROOT_DIR}/.bin/scripts/known_hosts/list_ips.sh" "${PRODUCT_NAME}")
  ssh-keyscan ${ips}
}

function ssh:known_hosts:update() {
  local PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
  local ips=$("${ROOT_DIR}/.bin/scripts/known_hosts/list_ips.sh" "${PRODUCT_NAME}")
  for ip in ${ips}; do
    ssh-keygen -R ${ip}
  done;

  ssh-keyscan ${ips} >> ~/.ssh/known_hosts
}

