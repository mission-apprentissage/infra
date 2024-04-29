#!/usr/bin/env bash
set -euo pipefail

docker compose $(for file in $(ls docker-compose.*.yml); do echo -n "-f $file "; done) "$@"
