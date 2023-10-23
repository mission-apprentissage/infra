#!/usr/bin/env bash
set -euo pipefail
#Needs to be run as sudo

readonly PROJECT_DIR="/opt/app"

function reload_containers() {
    echo "Rechargement des conteneurs ..."
    for serviceId in $(docker service ls -q)
    do
      docker service update $serviceId
    done
}

echo "****************************"
echo "[$(date +'%Y-%m-%d_%H%M%S')] Running ${BASH_SOURCE[0]} $*"
echo "****************************"
reload_containers "$@"
