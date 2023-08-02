#!/usr/bin/env bash
set -euo pipefail
#Needs to be run as sudo

echo "Désactivation de la page de maintenance..."
docker exec -i $(docker ps -q -f name={{product_name}}_reverse_proxy --latest) bash -c "rm -f /etc/nginx/html/*.on"
