#!/usr/bin/env bash
set -euo pipefail

gpg --decrypt --default-key "infra_devops" $@
