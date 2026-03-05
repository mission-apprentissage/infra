#!/usr/bin/env bash

set -euo pipefail

# Update templates files conversion

/docker-entrypoint.d/20-envsubst-on-templates.sh

# Validate file configuration

nginx -t

# Remove cache files

find /tmp/nginx_cache/ -maxdepth 1 -type f -name "*.pdf" -print0 \
  | xargs -0 rm -f

# Trigger nginx reload

nginx -s reload
