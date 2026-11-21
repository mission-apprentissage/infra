#!/usr/bin/env bash
# Tests des filtres et des jails fail2ban nginx, dans un conteneur Ubuntu 24.04.
# Usage : .infra/files/fail2ban/tests/run.sh — sortie non nulle si un test échoue.
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly IMAGE="fail2ban-tests"

docker build -q -t "$IMAGE" "$HERE" >/dev/null
docker run --rm -v "$(dirname "$HERE")":/repo:ro "$IMAGE" bash -c '/repo/tests/check-filters.sh && /repo/tests/check-jails.sh'
