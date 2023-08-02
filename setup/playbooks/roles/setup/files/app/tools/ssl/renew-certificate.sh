#!/usr/bin/env bash
set -euo pipefail

readonly SERVER_NAME=${1:?"Missing server name parameter"};
shift

mkdir -p /opt/app/data/certbot/www/.well-known/acme-challenge/
find /opt/app/data/certbot/www/ -type d -exec chmod 755 {} +

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

/opt/app/tools/ssl/reload-proxy.sh
