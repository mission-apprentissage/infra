#!/usr/bin/env bash

readonly VERSION="${RELEASE_SCRIPTS_DIR}/get-version.sh"

echo "Get"
echo $VERSION
docker buildx create --name mna --driver docker-container --bootstrap --use 2> /dev/null
docker buildx use --builder mna
