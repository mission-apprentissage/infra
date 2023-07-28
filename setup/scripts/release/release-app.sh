#!/bin/bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="${SCRIPT_DIR}/../../.."

cd ${ROOT_DIR}

defaultMode=""
if [ ! -z "${CI:-}" ]; then
  defaultMode="push"
else
  defaultMode="load"
fi

readonly next_version="${1}"
readonly mode=${2:-$defaultMode}

${SCRIPT_DIR}/bump-version.sh $next_version 
${SCRIPT_DIR}/build-images.sh $next_version $mode production recette
${SCRIPT_DIR}/push-git.sh $next_version
