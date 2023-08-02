#!/usr/bin/env bash
set -euo pipefail
#Needs to be run as sudo

echo "Mise en place de la page de maintenance..."
docker exec -i $(docker ps -q -f name={{product_name}}_reverse_proxy --latest) bash -c "mkdir -p /etc/nginx/html; touch /etc/nginx/html/maintenance.on" || true
