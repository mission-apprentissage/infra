#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "/opt/bal/data/ssl/privkey.pem" ]; then
  cd "${SCRIPT_DIR}"
    docker build --tag bal_certbot certbot/
    docker run --rm --name bal_certbot \
      -p 80:5000 \
      -v /opt/bal/data/certbot:/etc/letsencrypt \
      -v /opt/bal/data/ssl:/ssl \
      bal_certbot generate "$@"
  cd -
else
  echo "Certificat SSL déja généré"
fi
