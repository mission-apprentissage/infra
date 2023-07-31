#!/usr/bin/env bash

set -euo pipefail

export RELEASE_SCRIPTS_DIR="$ROOT_DIR/.bin/release/scripts"

function release:proxy() {
  "$RELEASE_SCRIPTS_DIR/build-image.sh" reverse_proxy "$@"
}

function release:fluentd() {
  "$RELEASE_SCRIPTS_DIR/build-image.sh" fluentd "$@"
}
