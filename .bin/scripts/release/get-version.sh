#!/usr/bin/env bash

readonly TAG_PREFIX=${1:?"Merci de préciser le directory (ex. reverse_proxy, fluentd)"}
shift
LATEST_TAG=$(git --git-dir="$ROOT_DIR/.git" describe --tags --abbrev=0 --candidates 100 --match "$TAG_PREFIX@*" --always)
HEAD=$(git --git-dir="$ROOT_DIR/.git" rev-parse HEAD)

if [[ "$LATEST_TAG" = "$HEAD" ]]; then
  LATEST_TAG="$TAG_PREFIX@0.0.0"
fi;

set -euo pipefail

VERSION=$(echo $LATEST_TAG | cut -d "@" -f 2)
echo $VERSION
