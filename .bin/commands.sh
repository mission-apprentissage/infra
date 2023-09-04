#!/usr/bin/env bash

set -euo pipefail

function Help() {
   # Display Help
   echo "Commands"
   echo "  bin:setup                                               Installs mna-infra binary with zsh completion on system"
   echo "  product:ini_file                                        Get product ini file location"
   echo "  product:env:ip                                          Get product environnement IP"
   echo "  product:validate:env                                    Validate product + environnment name"
   echo "  firewall:setup                                          Setup OVH firewall"
   echo "  firewall:service:close                                  Close service on OVH firewall"
   echo "  system:setup                                            Setup server"
   echo "  system:setup:initial                                    Initial setup server"
   echo "  system:user:remove                                      Remove user from server"
   echo "  ssh:known_hosts:print                                   Print SSH known host for a product including all servers"
   echo "  ssh:known_hosts:update                                  Update SSH known host for a product including all servers"
   echo "  release:proxy                                           Release docker reverse proxy image"
   echo "  release:fluentd                                         Release fluentd reverse proxy image"
   echo 
   echo
}

function bin:setup() {
  sudo ln -fs "${ROOT_DIR}/.bin/mna-infra.sh" /usr/local/bin/mna-infra

  sudo mkdir -p /usr/local/share/zsh/site-functions
  sudo ln -fs "${ROOT_DIR}/.bin/zsh-completion" /usr/local/share/zsh/site-functions/_mna-infra
  sudo rm -f ~/.zcompdump*
}

function product:ini_file() {
  local PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
  local env_ini="${ROOT_DIR}/products/$PRODUCT_NAME/env.ini"

  if [ ! -f "${env_ini}" ]; then
    >&2 echo "Product $PRODUCT_NAME not found (${env_ini})";
    return 1;
  fi;

  echo $env_ini;
}

function product:env:ip() {
  local PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
  local ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;
  local env_ini=$(product:ini_file "${PRODUCT_NAME}")

  if [[ -z $env_ini ]]; then exit 1; fi

  local env_ip=$(ansible-inventory -i "${env_ini}" --list -l "${ENV_NAME}" | jq -r ".${ENV_NAME}.hosts[0]")

  if [[ "$env_ip" == "" || "$env_ip" == "null" ]]; then
    >&2 echo "Environment ${ENV_NAME} not found";
    exit 1;
  fi;

  echo $env_ip
}

function product:validate:env() {
  # If we're able to get ip then we're good
  local env_ip=$(product:env:ip "$@")

  if [ -z $env_ip ]; then exit 1; fi
}

function firewall:setup() {
  local PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
  local ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_DIR/ovh/create-firewall.sh" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

function firewall:service:close() {
  local PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
  local ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_DIR/ovh/close-service.sh" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

function system:setup() {
  local PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
  local ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_DIR/run-playbook.sh" "setup.yml" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

function system:setup:initial() {
  system:setup "$@" --user ubuntu --ask-pass 
}

function system:user:remove() {
  local PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
  local ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_DIR/run-playbook.sh" "clean.yml" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

function ssh:known_hosts:print() {
  local PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
  local ips=$("${SCRIPT_DIR}/known_hosts/list_ips.sh" "${PRODUCT_NAME}")
  if [ -z "$ips" ]; then exit 1; fi
  ssh-keyscan ${ips}
}

function ssh:known_hosts:update() {
  local PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
  local ips=$("${SCRIPT_DIR}/known_hosts/list_ips.sh" "${PRODUCT_NAME}")
  if [ -z $ips ]; then exit 1; fi
  for ip in ${ips}; do
    ssh-keygen -R ${ip}
  done;

  ssh-keyscan ${ips} >> ~/.ssh/known_hosts
}

function release:proxy() {
  "$SCRIPT_DIR/release/build-image.sh" reverse_proxy "$@"
}

function release:fluentd() {
  "$SCRIPT_DIR/release/build-image.sh" fluentd "$@"
}

function ssh:config() {
  local PRODUCT_NAME=${1:?"Merci le produit (bal, tdb)"}; shift;
  local ips=($("${SCRIPT_DIR}/known_hosts/list_ips.sh" "${PRODUCT_NAME}"))
  if [ -z "$ips" ]; then exit 1; fi

  local hostnames=($("${SCRIPT_DIR}/known_hosts/list_hostnames.sh" "${PRODUCT_NAME}"))

  read -p "What is your username? " username

  local config=""

  for i in "${!ips[@]}"; do
    config="${config}
Host ${hostnames[$i]}
  Port 22
  User ${username}
  HostName ${ips[$i]}
"
  done;

  if ! grep -qF 'Include ~/.ssh/config.d/*.config' ~/.ssh/config; then
    echo '' >> ~/.ssh/config
    echo 'Include ~/.ssh/config.d/*.config' >> ~/.ssh/config
  fi

  mkdir -p ~/.ssh/config.d
  echo "$config" > ~/.ssh/config.d/${PRODUCT_NAME}.config
}