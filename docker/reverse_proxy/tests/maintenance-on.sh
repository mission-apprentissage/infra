#!/usr/bin/env bash
set -euo pipefail
#Needs to be run as sudo

docker compose exec -it reverse_proxy bash -c 'mkdir -p /etc/nginx/html; touch /etc/nginx/html/maintenance.on' || true