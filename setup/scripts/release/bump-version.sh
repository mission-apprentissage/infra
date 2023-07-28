#!/bin/bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="${SCRIPT_DIR}/../../.."

next_version="${1}"

cd "${ROOT_DIR}/ui"

UI_VERSION=$(cat package.json | jq -r '.version')
if [ $UI_VERSION != $next_version ]; then
  yarn version ${next_version}
fi;

cd "${ROOT_DIR}/server"
SERVER_VERSION=$(cat package.json | jq -r '.version')
if [ $SERVER_VERSION != $next_version ]; then
  yarn version ${next_version}
fi;

cd "${ROOT_DIR}/shared"
SHARED_VERSION=$(cat package.json | jq -r '.version')
if [ $SHARED_VERSION != $next_version ]; then
  yarn version ${next_version}
fi;

cd ..
