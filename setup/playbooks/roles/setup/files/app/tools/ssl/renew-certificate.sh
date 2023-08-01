#!/usr/bin/env bash
set -euo pipefail

readonly SERVER_NAME=${1:?"Missing server name parameter"};
shift

docker run \
  --rm \
  -v /opt/app/data/certbot/www/:/var/www/certbot/:rw \
  -v /opt/app/data/certbot/conf/:/etc/letsencrypt/:rw \
  --rm certbot/certbot:latest \
  certonly \
    --webroot --webroot-path /var/www/certbot/ \
    --email misson.apprentissage.devops@gmail.com \
    --agree-tos \
    --non-interactive \
    --domain ${SERVER_NAME} \
    "$@"

/opt/infra/tools/ssl/reload-proxy.sh
