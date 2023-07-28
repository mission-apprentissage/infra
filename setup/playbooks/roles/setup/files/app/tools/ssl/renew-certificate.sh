#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DNS_NAME=${1:?"Merci de préciser le nom de domaine"}; shift;

start_reverse_proxy() {
  bash /opt/bal/tools/reload-containers.sh
  bash /opt/bal/tools/wait-deployment.sh
}

stop_reverse_proxy() {
  bash /opt/bal/tools/stop-containers.sh reverse_proxy
  bash /opt/bal/tools/wait-deployment.sh
}

renew_certificate() {
  cd "${SCRIPT_DIR}"
  docker build --tag bal_certbot certbot/
  docker run --rm --name bal_certbot \
    -p 80:5000 \
    -v /opt/bal/data/certbot:/etc/letsencrypt \
    -v /opt/bal/data/ssl:/ssl \
    bal_certbot renew "${DNS_NAME}"
  cd -
}

handle_error() {
  bash /opt/bal/tools/send-to-slack.sh "[SSL] Unable to renew certificate"
  start_reverse_proxy
}
trap handle_error ERR

echo "****************************"
echo "[$(date +'%Y-%m-%d_%H%M%S')] Running ${BASH_SOURCE[0]} $*"
echo "****************************"

trap start_reverse_proxy EXIT

stop_reverse_proxy
renew_certificate
start_reverse_proxy
bash /opt/bal/tools/send-to-slack.sh "[SSL] Certificat has been renewed"
