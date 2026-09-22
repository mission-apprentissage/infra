#!/bin/sh
set -eu

mkdir -p ~/.ssh
chmod 700 ~/.ssh

cp /run/secrets/runner_ssh_key ~/.ssh/id_runner
chmod 600 ~/.ssh/id_runner

cp /opt/scripts/ssh_config ~/.ssh/config
chmod 600 ~/.ssh/config

cp /opt/scripts/known_hosts ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts

REPO_SLUG="${REPO_URL#https://github.com/}"

APP_JWT=$(/opt/scripts/mint-app-jwt.sh /run/secrets/github_app_key)

INSTALL_TOKEN=$(curl -fsSL -X POST \
  -H "Authorization: Bearer ${APP_JWT}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/${GITHUB_APP_INSTALLATION_ID}/access_tokens" \
  | jq -r '.token')

RUNNER_TOKEN=$(curl -fsSL -X POST \
  -H "Authorization: Bearer ${INSTALL_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${REPO_SLUG}/actions/runners/registration-token" \
  | jq -r '.token')

./config.sh \
  --url "${REPO_URL}" \
  --token "${RUNNER_TOKEN}" \
  --name "${RUNNER_NAME}-$(hostname)-$(date +%s)" \
  --labels "${RUNNER_LABELS}" \
  --work "_work" \
  --unattended \
  --ephemeral

cleanup() {
  ./config.sh remove --token "${RUNNER_TOKEN}" || true
}
trap cleanup EXIT INT TERM

./run.sh
