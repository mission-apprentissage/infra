#!/usr/bin/env bash
set -euo pipefail

readonly STACK_NAME=${1:?"Missing docker swarm stack name"};
shift
readonly SERVER_NAME=${1:?"Missing server name parameter"};
shift

docker run \
  --rm \
  -v /opt/${STACK_NAME}/data/certbot/www/:/var/www/certbot/:rw \
  -v /opt/${STACK_NAME}/data/certbot/conf/:/etc/letsencrypt/:rw \
  --rm certbot/certbot:latest \
  certonly \
    --webroot --webroot-path /var/www/certbot/ \
    --email misson.apprentissage.devops@gmail.com \
    --agree-tos \
    --non-interactive \
    --domain ${SERVER_NAME} \
    "$@"

/opt/infra/tools/ssl/reload-proxy.sh $STACK_NAME
