#!/usr/bin/env bash
set -euo pipefail

readonly PROJECT_DIR="/opt/app"

echo "Gracefully reloading reverse_proxy..."
for containerId in $(docker ps -q -f name={{product_name}}_reverse_proxy)
do
  docker exec $containerId /reload.sh
done
