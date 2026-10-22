#!/usr/bin/env bash

if [ -z "${SCRIPTS_DIR:-}" ]; then
  export SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"
fi

if [ -z "${ROOT_DIR:-}" ]; then
  export ROOT_DIR="$(cd "${SCRIPTS_DIR}/../../" && pwd)"
fi

_local_shared_submodule_sync() {

  local path="${ROOT_DIR}/.bin/shared"

  [[ -n "${MNA_SHARED_CHECKED:-}" ]] && return 0
  export MNA_SHARED_CHECKED=1

  if [[ -z "${CI:-}" ]]; then

    local recurse
    recurse=$(git -C "${ROOT_DIR}" config --get --type=bool submodule.recurse 2> /dev/null) || recurse=""

    if [[ "${recurse}" != "true" ]]; then
      git -C "${ROOT_DIR}" config --local submodule.recurse true
      echo "submodule.recurse était '${recurse:-non defini}', forcé à 'true' pour ce dépôt." >&2
    fi

    local push_recurse
    push_recurse=$(git -C "${ROOT_DIR}" config --get push.recurseSubmodules 2> /dev/null) || push_recurse=""

    if [[ "${push_recurse}" != "check" ]]; then
      git -C "${ROOT_DIR}" config --local push.recurseSubmodules check
      echo "push.recurseSubmodules était '${push_recurse:-non defini}', forcé à 'check' pour ce dépôt." >&2
    fi
  fi

  if [[ ! -e "${path}/.git" ]]; then
    echo "Initialisation du sous-module : ${path}" >&2
    git -C "${ROOT_DIR}" submodule update --init -- "${path}" >&2
    return
  fi

  local expected current
  expected=$(git -C "${ROOT_DIR}" ls-files --stage -- "${path}" | awk '{print $2}')
  current=$(git -C "${path}" rev-parse HEAD)

  [[ "${expected}" == "${current}" ]] && return 0

  if ! git -C "${path}" symbolic-ref -q HEAD > /dev/null \
    && [[ -z "$(git -C "${path}" status --porcelain)" ]] \
    && git -C "${path}" merge-base --is-ancestor "${current}" "${expected}" 2> /dev/null; then

    echo "Mise a jour du sous-module : ${current:0:7} -> ${expected:0:7}" >&2
    git -C "${ROOT_DIR}" submodule update -- "${path}" >&2
    return

  fi

  {
    echo "Attention : .bin/shared (${current:0:7}) diffère de la transaction attendue (${expected:0:7})."
    echo "Branche, modifications locales ou divergence : aucune mise a jour automatique."
    echo "Pour aligner : git submodule update -- .bin/shared"
  } >&2
}

_local_shared_submodule_sync

. "${ROOT_DIR}/.bin/shared/commands.sh"

################################################################################
# Shared commands
################################################################################

_register "app:deploy:log:encrypt"
_register "app:deploy:log:decrypt"
_register "dev:dependencies:check"
_register "dev:setup"
_register "vault:edit"

################################################################################
# Non-shared commands
################################################################################

_local_release_nginx__help="Release nginx Docker image"
_register "release:nginx" "_local_release_nginx"

function _local_release_nginx() {
  "${SCRIPTS_DIR}/release/build-image.sh" reverse_proxy "$@"
}

_local_release_fluentd__help="Release fluentd Docker image"
_register "release:fluentd" "_local_release_fluentd"

function _local_release_fluentd() {
  "${SCRIPTS_DIR}/release/build-image.sh" fluentd "$@"
}

_local_release_docker_stack_wait__help="Release docker-stack-wait Docker image"
_register "release:docker-stack-wait" "_local_release_docker_stack_wait"

function _local_release_docker_stack_wait() {
  "${SCRIPTS_DIR}/release/build-image.sh" docker-stack-wait "$@"
}

_local_release_runner__help="Release runner Docker image"
_register "release:runner" "_local_release_runner"

function _local_release_runner() {
  "${SCRIPTS_DIR}/release/build-image.sh" runner "$@"
}

_local_firewall_setup__help="Setup OVHcloud firewall"
_register "firewall:setup" "_local_firewall_setup"

function _local_firewall_setup() {
  local PRODUCT_NAME=${1:?"Merci préciser le produit !"}
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  _local_product_validate_env "$PRODUCT_NAME" "$ENV_NAME"

  "${SCRIPTS_DIR}/ovh/create-firewall.sh" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

_local_firewall_service_close__help="Close service on OVHcloud firewall"
_register "firewall:service:close" "_local_firewall_service_close"

function _local_firewall_service_close() {
  local PRODUCT_NAME=${1:?"Merci préciser le produit !"}
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  _local_product_validate_env "$PRODUCT_NAME" "$ENV_NAME"

  "${SCRIPTS_DIR}/ovh/close-service.sh" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

_local_system_setup__help="Setup server"
_register "system:setup" "_local_system_setup"

function _local_system_setup() {
  local PRODUCT_NAME=${1:?"Merci préciser le produit !"}
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  _local_product_validate_env "$PRODUCT_NAME" "$ENV_NAME"

  case "${PRODUCT_NAME}/${ENV_NAME}" in
    runner/base | bal/staging | bal/production | analytics/base)
      ;;
    *)
      _local_firewall_setup "$PRODUCT_NAME" "$ENV_NAME"
      ;;
  esac

  "${SCRIPTS_DIR}/run-playbook.sh" "setup.yml" "$PRODUCT_NAME" "$ENV_NAME" "$@"

  local TAG="${PRODUCT_NAME}-${ENV_NAME}"

  echo "Creating tag ${TAG}"

  git --git-dir="${ROOT_DIR}/.git" tag -f "${TAG}"
  git --git-dir="${ROOT_DIR}/.git" push -f origin "${TAG}"
}

_local_system_user_remove__help="Remove user from server"
_register "system:user:remove" "_local_system_user_remove"

function _local_system_user_remove() {
  local PRODUCT_NAME=${1:?"Merci préciser le produit !"}
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  local USERNAME=${1:?"Merci de préciser l'utilisateur à supprimer !"}
  shift

  _local_product_validate_env "$PRODUCT_NAME" "$ENV_NAME"

  "${SCRIPTS_DIR}/run-playbook.sh" "clean.yml" "$PRODUCT_NAME" "$ENV_NAME" --extra-vars "username='${USERNAME}'" "$@"
}

_local_system_unban__help="Unban IP from server"
_register "system:unban" "_local_system_unban"

function _local_system_unban() {
  local PRODUCT_NAME=${1:?"Merci préciser le produit !"}
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  local IP=${1:?"Merci de préciser l'adresse IPv4 à débannir !"}
  shift

  _local_product_validate_env "$PRODUCT_NAME" "$ENV_NAME"

  "${SCRIPTS_DIR}/run-playbook.sh" "unban.yml" "$PRODUCT_NAME" "$ENV_NAME" --extra-vars "ip='${IP}'" "$@"
}

_local_system_password_rotate__help="Rotate password of the 'deploy' user"
_register "system:password:rotate" "_local_system_password_rotate"

function _local_system_password_rotate() {
  local PRODUCT_NAME=${1:?"Merci préciser le produit !"}
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  _local_product_validate_env "$PRODUCT_NAME" "$ENV_NAME"

  "${SCRIPTS_DIR}/run-playbook.sh" "password-rotate.yml" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

_local_system_reboot__help="Reboot server if needed"
_register "system:reboot" "_local_system_reboot"

function _local_system_reboot() {
  local PRODUCT_NAME=${1:?"Merci préciser le produit !"}
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  _local_product_validate_env "$PRODUCT_NAME" "$ENV_NAME"

  "${SCRIPTS_DIR}/run-playbook.sh" "reboot.yml" "$PRODUCT_NAME" "$ENV_NAME" "$@"
}

_local_system_setup_initial__help="Initial server setup"
_register "system:setup:initial" "_local_system_setup_initial"

function _local_system_setup_initial() {
  local PRODUCT_NAME=${1:?"Merci préciser le produit !"}
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  export ANSIBLE_HOST_KEY_CHECKING=False
  _local_firewall_setup "$PRODUCT_NAME" "$ENV_NAME"

  read -p "Do you want to setup the server with a RSA key? [Y/n]" response

  case $response in
    [yY][eE][sS]|[yY]|"")
      "${SCRIPTS_DIR}/deploy_ssh_keyfile.sh"
      export ANSIBLE_PRIVATE_KEY_FILE="${ROOT_DIR}/.bin/id_rsa_deploy.key"
      export ANSIBLE_BECOME_PASS="-"
      _local_system_setup "$PRODUCT_NAME" "$ENV_NAME" "$@" --user ubuntu
      rm -f "${ANSIBLE_PRIVATE_KEY_FILE}"
      ;;
    *)
      _local_system_setup "$PRODUCT_NAME" "$ENV_NAME" "$@" --user ubuntu --ask-pass
      return
      ;;
  esac
}

_local_product_repo__help="Get product repository"
_register "product:repo" "_local_product_repo"

function _local_product_repo() {
  local PRODUCT_NAME=${1:?"Merci préciser le produit !"}
  shift

  local env_ini
  env_ini=$(_local_product_ini_file "${PRODUCT_NAME}")

  if [[ -z "$env_ini" ]]; then
    exit 1
  fi

  "${SCRIPTS_DIR}/get-product-repo.sh" "$PRODUCT_NAME" "$@"
}

_local_product_validate_env__help="Validate product environnement name"
_register "product:validate:env" "_local_product_validate_env"

function _local_product_validate_env() {

  local env_ip
  env_ip=$(_local_product_env_ip "$@") || env_ip=""

  if [[ -z "$env_ip" ]]; then
    if [[ -z "${CI:-}" ]]; then
      exit 1
    else
      # If we are in CI just exit 0 to allow batch
      exit 0
    fi
  fi

}

_local_product_create__help="Create a new repository"
_register "product:create" "_local_product_create"

function _local_product_create() {
  "${SCRIPTS_DIR}/ensure-gh-auth.sh"
  "${SCRIPTS_DIR}/create-product.sh" "$@"
}

_local_product_ini_file__help="Get product ini file location"
_register "product:ini_file" "_local_product_ini_file"

function _local_product_ini_file() {
  "${SCRIPTS_DIR}/validate-product-name.sh" "$@"
}

_local_product_env_ip__help="Get production environnement IP"
_register "product:env:ip" "_local_product_env_ip"

function _local_product_env_ip() {
  local PRODUCT_NAME=${1:?"Merci préciser le produit !"}
  shift

  local ENV_NAME=${1:?"Merci de préciser l'environnement !"}
  shift

  local env_ini
  env_ini=$(_local_product_ini_file "${PRODUCT_NAME}")

  if [[ -z "$env_ini" ]]; then
    exit 1
  fi

  "${SCRIPTS_DIR}/get-product-env-ip.sh" "$PRODUCT_NAME" "$ENV_NAME"
}

_local_ssh_known_hosts_print__help="Print SSH known host for a product"
_register "ssh:known_hosts:print" "_local_ssh_known_hosts_print"

function _local_ssh_known_hosts_print() {
  local PRODUCT_NAME=${1:?"Merci préciser le produit !"}
  shift

  local ips
  ips=$("${SCRIPTS_DIR}/known_hosts/list_ips.sh" "${PRODUCT_NAME}")

  if [[ -z "$ips" ]]; then
    exit 1
  fi

  # Word splitting volontaire : une IP par argument
  ssh-keyscan -t ed25519 ${ips}
}

_local_ssh_known_hosts_update__help="Update SSH known host for a product"
_register "ssh:known_hosts:update" "_local_ssh_known_hosts_update"

function _local_ssh_known_hosts_update() {
  local PRODUCT_NAME=${1:?"Merci préciser le produit !"}
  shift

  local ips
  ips=$("${SCRIPTS_DIR}/known_hosts/list_ips.sh" "${PRODUCT_NAME}")

  if [[ -z "$ips" ]]; then
    exit 1
  fi

  "${SCRIPTS_DIR}/ensure-gh-auth.sh"

  local SSH_KNOWN_HOSTS
  SSH_KNOWN_HOSTS=$(ssh-keyscan -t ed25519 ${ips} 2> /dev/null)

  local ip
  for ip in ${ips}; do
    if [[ "${ip}" != "x.x.x.x" ]]; then
      ssh-keygen -R "${ip}"
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

  local repo=($("${SCRIPTS_DIR}/known_hosts/get_ansible_var.sh" "${PRODUCT_NAME}" "repo"))

  gh variable set SSH_KNOWN_HOSTS --body "$SSH_KNOWN_HOSTS" -R "${repo[0]}"
  gh variable set "${PRODUCT_NAME}_SSH_KNOWN_HOSTS" --body "$SSH_KNOWN_HOSTS" --repo "${REPO_INFRA}"
}

_local_ssh_config__help="Update your local SSH config for a product"
_register "ssh:config" "_local_ssh_config"

function _local_ssh_config() {
  local PRODUCT_NAME=${1:?"Merci préciser le produit !"}
  shift

  local ips=($("${SCRIPTS_DIR}/known_hosts/list_ips.sh" "${PRODUCT_NAME}"))

  if [[ ${#ips[@]} -eq 0 ]]; then
    exit 1
  fi

  local hostnames=($("${SCRIPTS_DIR}/known_hosts/get_ansible_var.sh" "${PRODUCT_NAME}" "host_name"))
  read -p "What is your username? " username

  local config=""
  local i

  for i in "${!ips[@]}"; do
    config="${config}
Host ${hostnames[$i]} ${ips[$i]}
  Port 22
  User ${username}
  Hostname ${ips[$i]}
"
  done

  if ! grep -qF 'Include ~/.ssh/config.d/*.config' ~/.ssh/config; then
    echo '' >> ~/.ssh/config
    echo 'Match All' >> ~/.ssh/config
    echo 'Include ~/.ssh/config.d/*.config' >> ~/.ssh/config
  fi

  mkdir -p ~/.ssh/config.d
  echo "$config" > ~/.ssh/config.d/"${PRODUCT_NAME}".config
}
