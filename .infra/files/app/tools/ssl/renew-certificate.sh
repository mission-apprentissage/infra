#!/usr/bin/env bash
set -euo pipefail

{% if env_type == "preview" %}
  echo "Not supported in preview environnment"
  exit 0;
{% endif %}

readonly SERVER_NAME=${1:?"Missing server name parameter"};
shift

# Allow Nginx container to access challenge
mkdir -p /opt/app/system/certbot/www/.well-known/acme-challenge/
find /opt/app/system/certbot/www/ -type d -exec chmod 755 {} +

docker run \
  -i \
  -v /opt/app/system/certbot/www/:/var/www/certbot/:rw \
  -v /opt/app/system/certbot/conf/:/etc/letsencrypt/:rw \
  --rm certbot/certbot:latest \
  certonly \
    --webroot --webroot-path /var/www/certbot/ \
    --email misson.apprentissage.devops@gmail.com \
    --agree-tos \
    --non-interactive \
    --domain ${SERVER_NAME} \
    "$@"

# Allow Nginx container to access certificates
chgrp -R www-data /opt/app/system/certbot/
find /opt/app/system/certbot/conf/ -type d -exec chmod 755 {} +
find /opt/app/system/certbot/conf/ -type f -exec chmod 644 {} +
/opt/app/tools/ssl/reload-proxy.sh
