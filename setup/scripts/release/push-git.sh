#!/bin/bash
set -euo pipefail

next_version="${1}"

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="${SCRIPT_DIR}/../../.."

cd ${ROOT_DIR}

if [ ! -z "${CI:-}" ]; then
  git add CHANGELOG.md \
  .github/workflows/_deploy.yml \
  .infra/env.ini \
  package.json \
  server/package.json \
  shared/package.json \
  ui/package.json

  git commit -m "chore(release): bump $next_version [skip ci]"
  git push --follow-tags --force
else
  echo "Skipping push: Not in CI"
fi
