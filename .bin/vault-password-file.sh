#!/usr/bin/env bash

set -euo pipefail

export BIN_DIR="$(dirname -- "$( readlink -f -- "$0"; )")"

"${BIN_DIR}/infra" vault:password
