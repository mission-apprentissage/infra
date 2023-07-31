#!/usr/bin/env bash
set -euo pipefail
#Needs to be run as sudo

readonly PROJECT_DIR="/opt/app"

function reload_containers() {
    echo "Rechargement des conteneurs ..."
    if test -f "/opt/app/docker-compose.recette.yml"; then
      docker stack deploy -c /opt/app/docker-compose.yml -c /opt/app/docker-compose.recette.yml {{product_name}};
    else
      docker stack deploy -c /opt/app/docker-compose.yml {{product_name}};
    fi
}

echo "****************************"
echo "[$(date +'%Y-%m-%d_%H%M%S')] Running ${BASH_SOURCE[0]} $*"
echo "****************************"
reload_containers "$@"
