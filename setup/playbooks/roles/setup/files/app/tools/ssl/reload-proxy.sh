#!/usr/bin/env bash
set -euo pipefail

readonly STACK_NAME=${1:?"Missing docker swarm stack name"};
shift

for containerId in $(docker ps -f name=${STACK_NAME}_reverse_proxy --quiet)
do
  docker exec -it $containerId nginx -s reload
done
