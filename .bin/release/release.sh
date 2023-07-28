#!/usr/bin/env bash

set -euo pipefail

export RELEASE_SCRIPTS_DIR="$ROOT_DIR/.bin/release/scripts"

function release:proxy() {
  "$RELEASE_SCRIPTS_DIR/build-proxy.sh" "$@"
}
