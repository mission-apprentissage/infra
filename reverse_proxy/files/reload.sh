#!/usr/bin/env bash

set -euo pipefail

# Update templates files conversion

/docker-entrypoint.d/20-envsubst-on-templates.sh

# Validate file configuration

nginx -t

# Remove cache files

rm -rf /tmp/nginx_cache

# Trigger nginx reload

nginx -s reload
