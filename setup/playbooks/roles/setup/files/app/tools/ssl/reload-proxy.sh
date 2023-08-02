#!/usr/bin/env bash
set -euo pipefail

for containerId in $(docker ps -f name={{product_name}}_reverse_proxy --quiet)
do
  docker exec -i $containerId nginx -s reload
done
