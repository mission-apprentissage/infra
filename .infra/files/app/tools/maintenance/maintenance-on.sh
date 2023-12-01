#!/usr/bin/env bash
set -euo pipefail
#Needs to be run as sudo

echo "Mise en place de la page de maintenance..."
for containerId in $(docker ps -q -f name={{product_name}}_reverse_proxy)
do
    docker exec -i $containerId bash -c 'mkdir -p /etc/nginx/html; touch /etc/nginx/html/maintenance.on' || true
done