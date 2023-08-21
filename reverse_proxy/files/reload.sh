#!/usr/bin/env bash
set -euo pipefail

# Update templates files conversion
/docker-entrypoint.d/20-envsubst-on-templates.sh
# Validate file configuration
nginx -t
# Trigger nginx reload
nginx -s reload
