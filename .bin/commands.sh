#!/usr/bin/env bash

set -euo pipefail

function Help() {
   # Display Help
   echo "Commands"
   echo "  bin:setup                                  Installs ij-infra binary with zsh completion on system"
   echo "  release:proxy                              Release docker reverse proxy image"
   echo "  release:fluentd                            Release fluentd reverse proxy image"
   echo "  system:setup                               Setup server"
   echo "  system:unban                               Unban IP from server"
   echo "  system:reboot                              Reboot server if needed"
   echo "  system:setup:initial                       Initial setup server"
   echo "  system:user:remove                         Remove user from server"
   echo "  vault:edit                                 Edit vault file"
   echo "  vault:view                                 View vault file"
   echo "  vault:renew                                Renew vault password with updated habilitations"
   echo "  vault:password                             Show vault password"
   echo "  deploy:log:encrypt                         Encrypt Github ansible logs"
   echo "  deploy:log:dencrypt                        Decrypt Github ansible logs"
   echo "  product:ini_file                           Get product ini file location"
   echo "  product:env:ip                             Get product environnement IP"
   echo "  product:validate:env                       Validate product + environnment name"
   echo "  product:repo                               Get product repository"
   echo "  product:create                             Create a new repository"
   echo "  firewall:setup                             Setup OVH firewall"
   echo "  firewall:service:close                     Close service on OVH firewall"
   echo "  ssh:known_hosts:print                      Print SSH known host for a product including all servers"
   echo "  ssh:known_hosts:update                     Update SSH known host for a product including all servers"
   echo "  ssh:config                                 Update your local SSH config for a product including all servers"
   echo 
   echo
}

function bin:setup() {
  sudo ln -fs "${ROOT_DIR}/.bin/infra" "/usr/local/bin/ij-infra"

  sudo mkdir -p /usr/local/share/zsh/site-functions
  sudo ln -fs "${ROOT_DIR}/.bin/zsh-completion" "/usr/local/share/zsh/site-functions/_ij-infra"
  sudo rm -f ~/.zcompdump*
}

function release:proxy() {
  "$SCRIPT_DIR/release/build-image.sh" reverse_proxy "$@"
}

function release:fluentd() {
  "$SCRIPT_DIR/release/build-image.sh" fluentd "$@"
}

function system:setup() {
  local PRODUCT_NAME=${1:?"Merci le produit (orion, monitoring)"}; shift;
  local ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"
  firewall:setup "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_DIR/run-playbook.sh" "setup.yml" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

function system:reboot() {
  local PRODUCT_NAME=${1:?"Merci le produit (orion, monitoring)"}; shift;
  local ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_DIR/run-playbook.sh" "reboot.yml" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

function system:setup:initial() {
  local PRODUCT_NAME=${1:?"Merci le produit (orion, monitoring)"}; shift;
  local ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

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

function system:user:remove() {
  local PRODUCT_NAME=${1:?"Merci le produit (orion, monitoring)"}; shift;
  local ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;
  local USERNAME=${1:?"Merci de préciser l'utilisateur à supprimer"}; shift;

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_DIR/run-playbook.sh" "clean.yml" "$PRODUCT_NAME" "$ENV_NAME" --extra-vars "username='${USERNAME}'" "$@"
}

function system:unban() {
  local PRODUCT_NAME=${1:?"Merci le produit (orion, monitoring)"}; shift;
  local ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;
  local IP=${1:?"Merci de préciser l'ip à unban"}; shift;

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_DIR/run-playbook.sh" "unban.yml" "$PRODUCT_NAME" "$ENV_NAME" --extra-vars "ip='${IP}'" "$@"
}

function vault:edit() {
  editor=${EDITOR:-'code -w'}
  EDITOR=$editor "${SCRIPT_DIR}/edit-vault.sh" "$@"
}

function vault:view() {
  "${SCRIPT_DIR}/view-vault.sh" "$@"
}

function vault:renew() {
  "${SCRIPT_DIR}/renew-vault.sh" "$@"
}

function vault:password() {
  "${SCRIPT_DIR}/get-vault-password-client.sh" "$@"
}

function deploy:log:encrypt() {
  (cd "$ROOT_DIR" && "${SCRIPT_DIR}/deploy-log-encrypt.sh" "$@")
}

function deploy:log:decrypt() {
  (cd "$ROOT_DIR" && "${SCRIPT_DIR}/deploy-log-decrypt.sh" "$@")
}

function product:ini_file() {
  local PRODUCT_NAME=${1:?"Merci le produit (orion, monitoring)"}; shift;
  local env_ini="${ROOT_DIR}/products/$PRODUCT_NAME/env.ini"

  if [ ! -f "${env_ini}" ]; then
    >&2 echo "Product $PRODUCT_NAME not found (${env_ini})";
    return 1;
  fi;

  echo $env_ini;
}

function product:env:ip() {
  local PRODUCT_NAME=${1:?"Merci le produit (orion, monitoring)"}; shift;
  local env_ini=$(product:ini_file "${PRODUCT_NAME}")

  if [[ -z $env_ini ]]; then exit 1; fi

  "$SCRIPT_DIR/get-product-env-ip.sh" "$PRODUCT_NAME" "$@"
}

function product:repo() {
  local PRODUCT_NAME=${1:?"Merci le produit (orion, monitoring)"}; shift;
  local env_ini=$(product:ini_file "${PRODUCT_NAME}")

  if [[ -z $env_ini ]]; then exit 1; fi

  "$SCRIPT_DIR/get-product-repo.sh" "$PRODUCT_NAME" "$@"
}

function product:validate:env() {
  # If we're able to get ip then we're good
  local env_ip=$(product:env:ip "$@")

  if [ -z $env_ip ]; then
    if [[ -z "${CI:-}" ]]; then
      exit 1;
    else
      # If we are in CI just exit 0 to allow batch
      exit 0;
    fi;
  fi;
}

function product:create() {
  "$SCRIPT_DIR/create-product.sh" "$@"
}

function product:access:update() {
  "$SCRIPT_DIR/update-product-access.sh" "$@"
}

function firewall:setup() {
  local PRODUCT_NAME=${1:?"Merci le produit (orion, monitoring)"}; shift;
  local ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_DIR/ovh/create-firewall.sh" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

function firewall:service:close() {
  local PRODUCT_NAME=${1:?"Merci le produit (orion, monitoring)"}; shift;
  local ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}; shift;

  product:validate:env "$PRODUCT_NAME" "$ENV_NAME"

  "$SCRIPT_DIR/ovh/close-service.sh" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

function ssh:known_hosts:print() {
  local PRODUCT_NAME=${1:?"Merci le produit (orion, monitoring)"}; shift;
  local ips=$("${SCRIPT_DIR}/known_hosts/list_ips.sh" "${PRODUCT_NAME}")
  if [ -z "$ips" ]; then exit 1; fi
  ssh-keyscan ${ips}
}

function ssh:known_hosts:update() {
  local PRODUCT_NAME=${1:?"Merci le produit (orion, monitoring)"}; shift;
  local ips=$("${SCRIPT_DIR}/known_hosts/list_ips.sh" "${PRODUCT_NAME}")
  if [ -z "$ips" ]; then exit 1; fi
  for ip in ${ips}; do
    if [[ "${ip}" != "x.x.x.x" ]]; then
      ssh-keygen -R ${ip}
    fi;
  done;

  ssh-keyscan ${ips} >> ~/.ssh/known_hosts 2> /dev/null

  read -p "Do you want to update github variable? [Y/n]" response

  case $response in
    [yY][eE][sS]|[yY]|"")
      ;;
    *)
      return
      ;;
  esac

  local repo=($("${SCRIPT_DIR}/known_hosts/get_ansible_var.sh" "${PRODUCT_NAME}" "repo"))

  SSH_KNOWN_HOSTS=$(ssh-keyscan ${ips} 2> /dev/null)
  gh variable set SSH_KNOWN_HOSTS --body "$SSH_KNOWN_HOSTS" -R "${repo[0]}" 
  gh variable set "${PRODUCT_NAME}_SSH_KNOWN_HOSTS" --body "$SSH_KNOWN_HOSTS" --repo "https://github.com/mission-apprentissage/ij-infra"
}

function ssh:config() {
  local PRODUCT_NAME=${1:?"Merci le produit (orion, monitoring)"}; shift;
  local ips=($("${SCRIPT_DIR}/known_hosts/list_ips.sh" "${PRODUCT_NAME}"))
  if [ -z "$ips" ]; then exit 1; fi

  local hostnames=($("${SCRIPT_DIR}/known_hosts/get_ansible_var.sh" "${PRODUCT_NAME}" "host_name"))
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
    echo 'Match All' >> ~/.ssh/config
    echo 'Include ~/.ssh/config.d/*.config' >> ~/.ssh/config
  fi

  mkdir -p ~/.ssh/config.d
  echo "$config" > ~/.ssh/config.d/${PRODUCT_NAME}.config
}