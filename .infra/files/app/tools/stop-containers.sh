#!/usr/bin/env bash
set -euo pipefail
#Needs to be run as sudo
readonly CONTAINER_FILTER=${1:-"{{product_name}}*"};

echo "****************************"
echo "[$(date +'%Y-%m-%d_%H%M%S')] Running ${BASH_SOURCE[0]} $*"
echo "****************************"

echo "Arrêt des conteneurs ${CONTAINER_FILTER}..."
docker service scale {{product_name}}_${CONTAINER_FILTER}=0
