#!/usr/bin/env bash

set -euo pipefail

if [ ! -f "${ROOT_DIR}/.bin/shared/commands.sh" ]; then

  echo "Mise à jour du sous-module mna-shared-bin"

  git submodule update --init "${ROOT_DIR}/.bin/shared"

fi

. "${ROOT_DIR}/.bin/shared/commands.sh"

unset _meta_help["app:deploy"]
unset app:deploy
unset _meta_help["seed:update"]
unset seed:update
unset _meta_help["seed:apply"]
unset seed:apply
unset _meta_help["docker:login"]
unset docker:login

################################################################################
# Non-shared commands
################################################################################

_meta_help["release:nginx"]="Release nginx Docker image"

function release:nginx() {
  "$SCRIPT_DIR/release/build-image.sh" reverse_proxy "$@"
}

_meta_help["release:fluentd"]="Release fluentd Docker image"

function release:fluentd() {
  "$SCRIPT_DIR/release/build-image.sh" fluentd "$@"
}

_meta_help["release:docker-stack-wait"]="Release docker-stack-wait Docker image"

function release:docker-stack-wait() {
  "$SCRIPT_DIR/release/build-image.sh" docker-stack-wait "$@"
}

_meta_help["firewall:setup"]="Setup OVHcloud firewall"

function firewall:setup() {

  local PRODUCT_NAME=${1:?"Merci préciser le produit !"} 
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_DIR/ovh/create-firewall.sh" "$PRODUCT_NAME" "$ENV_NAME" "$@"

}

_meta_help["firewall:service:close"]="Close service on OVHcloud firewall"

function firewall:service:close() {

  local PRODUCT_NAME=${1:?"Merci préciser le produit !"} 
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_DIR/ovh/close-service.sh" "$PRODUCT_NAME" "$ENV_NAME" "$@"

}

_meta_help["system:setup"]="Setup server"

function system:setup() {

  local PRODUCT_NAME=${1:?"Merci préciser le produit !"} 
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"
  firewall:setup "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_SHARED_DIR/run-playbook.sh" "setup.yml" "$PRODUCT_NAME" "$ENV_NAME" "$@"

  #TAG="$PRODUCT_NAME-$ENV_NAME"

  #echo "Creating tag $TAG"

  #git --git-dir="$ROOT_DIR/.git" tag -f $TAG
  #git --git-dir="$ROOT_DIR/.git" push -f origin $TAG

}

_meta_help["system:user:remove"]="Remove user from server"

function system:user:remove() {

  local PRODUCT_NAME=${1:?"Merci préciser le produit !"} 
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift
  
  local USERNAME=${1:?"Merci de préciser l'utilisateur à supprimer !"}
  shift

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_SHARED_DIR/run-playbook.sh" "clean.yml" "$PRODUCT_NAME" "$ENV_NAME" --extra-vars "username='${USERNAME}'" "$@"

}

_meta_help["system:unban"]="Unban IP from server"

function system:unban() {

  local PRODUCT_NAME=${1:?"Merci préciser le produit !"} 
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift
  
  local IP=${1:?"Merci de préciser l'adresse IPv4 à débannir !"}
  shift

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_SHARED_DIR/run-playbook.sh" "unban.yml" "$PRODUCT_NAME" "$ENV_NAME" --extra-vars "ip='${IP}'" "$@"

}

_meta_help["system:password:rotate"]="Rotate password of the 'deploy' user"

function system:password:rotate() {

  local PRODUCT_NAME=${1:?"Merci préciser le produit !"} 
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_SHARED_DIR/run-playbook.sh" "password-rotate.yml" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

_meta_help["system:reboot"]="Reboot server if needed"

function system:reboot() {

  local PRODUCT_NAME=${1:?"Merci préciser le produit !"} 
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_SHARED_DIR/run-playbook.sh" "reboot.yml" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

_meta_help["system:setup:initial"]="Initial server setup"

function system:setup:initial() {

  local PRODUCT_NAME=${1:?"Merci préciser le produit !"} 
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  export ANSIBLE_HOST_KEY_CHECKING=False
  firewall:setup "$PRODUCT_NAME" "$ENV_NAME"

  read -p "Do you want to setup the server with a RSA key? [Y/n]" response

  case $response in
    [yY][eE][sS]|[yY]|"")
      "$SCRIPT_DIR/deploy_ssh_keyfile.sh"
      export ANSIBLE_PRIVATE_KEY_FILE="$ROOT_DIR/.bin/id_rsa_deploy.key"
      export ANSIBLE_BECOME_PASS="-"
      system:setup "$PRODUCT_NAME" "$ENV_NAME" "$@" --user ubuntu
      rm -f "${ANSIBLE_PRIVATE_KEY_FILE}"
      ;;
    *)
      system:setup "$PRODUCT_NAME" "$ENV_NAME" "$@" --user ubuntu --ask-pass
      return
      ;;
  esac

}

_meta_help["product:repo"]="Get product repository"

function product:repo() {

  local PRODUCT_NAME=${1:?"Merci préciser le produit !"} 
  shift

  local env_ini=$(product:ini_file "${PRODUCT_NAME}")

  if [[ -z $env_ini ]]; then
    exit 1
  fi

  "$SCRIPT_DIR/get-product-repo.sh" "$PRODUCT_NAME" "$@"
}

_meta_help["product:validate:env"]="Validate product environnement name"

function product:validate:env() {

  local env_ip=$(product:env:ip "$@")

  if [ -z $env_ip ]; then
    if [[ -z "${CI:-}" ]]; then
      exit 1
    else
      # If we are in CI just exit 0 to allow batch
      exit 0
    fi
  fi

}

_meta_help["product:create"]="Create a new repository"

function product:create() {
  "$SCRIPT_DIR/create-product.sh" "$@"
}

_meta_help["product:ini_file"]="Get product ini file location"

function product:ini_file() {
  "$SCRIPT_DIR/validate-product-name.sh" "$@"
}

_meta_help["product:env:ip"]="Get production environnement IP"

function product:env:ip() {

  local PRODUCT_NAME=${1:?"Merci préciser le produit !"} 
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  if [[ -z $env_ini ]]; then
    exit 1
  fi

  "$SCRIPT_DIR/get-product-env-ip.sh" "$PRODUCT_NAME" "$@"
}

_meta_help["ssh:known_hosts:print"]="Print SSH known host for a product"

function ssh:known_hosts:print() {

  local PRODUCT_NAME=${1:?"Merci préciser le produit !"} 
  shift

  local ips=$("${SCRIPT_DIR}/known_hosts/list_ips.sh" "${PRODUCT_NAME}")

  if [ -z "$ips" ]; then
    exit 1
  fi

  ssh-keyscan -t ed25519,rsa ${ips}

}
_meta_help["ssh:known_hosts:update"]="Update SSH known host for a product"

function ssh:known_hosts:update() {

  local PRODUCT_NAME=${1:?"Merci préciser le produit !"} 
  shift

  local ips=$("${SCRIPT_DIR}/known_hosts/list_ips.sh" "${PRODUCT_NAME}")

  if [ -z "$ips" ]; then
    exit 1
  fi

  SSH_KNOWN_HOSTS=$(ssh-keyscan -t ed25519,rsa ${ips} 2> /dev/null)

  for ip in ${ips}; do
    if [[ "${ip}" != "x.x.x.x" ]]; then
      ssh-keygen -R ${ip}
    fi
  done

  echo "${SSH_KNOWN_HOSTS}" >> ~/.ssh/known_hosts 2> /dev/null

  read -p "Do you want to update github variable? [Y/n]" response

  case $response in
    [yY][eE][sS]|[yY]|"")
      ;;
    *)
      return
      ;;
  esac

  local repo=($("${SCRIPT_DIR}/known_hosts/get_ansible_var.sh" "${PRODUCT_NAME}" "repo"))

  gh variable set SSH_KNOWN_HOSTS --body "$SSH_KNOWN_HOSTS" -R "${repo[0]}" 
  gh variable set "${PRODUCT_NAME}_SSH_KNOWN_HOSTS" --body "$SSH_KNOWN_HOSTS" --repo "${REPO_INFRA}"

}

_meta_help["ssh:config"]="Update your local SSH config for a product"

function ssh:config() {

  local PRODUCT_NAME=${1:?"Merci préciser le produit !"} 
  shift

  local ips=($("${SCRIPT_DIR}/known_hosts/list_ips.sh" "${PRODUCT_NAME}"))

  if [ -z "$ips" ]; then
    exit 1
  fi

  local hostnames=($("${SCRIPT_DIR}/known_hosts/get_ansible_var.sh" "${PRODUCT_NAME}" "host_name"))
  read -p "What is your username? " username

  local config=""

  for i in "${!ips[@]}"; do
    config="${config}
Host ${hostnames[$i]} ${ips[$i]}
  Port 22
  User ${username}
  Hostname ${ips[$i]}
"
  done;

  if ! grep -qF 'Include ~/.ssh/config.d/*.config' ~/.ssh/config; then
    echo '' >> ~/.ssh/config
    echo 'Match All' >> ~/.ssh/config
    echo 'Include ~/.ssh/config.d/*.config' >> ~/.ssh/config
  fi

  mkdir -p ~/.ssh/config.d
  echo "$config" > ~/.ssh/config.d/${PRODUCT_NAME}.config

}

