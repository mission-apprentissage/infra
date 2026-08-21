#!/usr/bin/env bash

set -euo pipefail

# Update templates files conversion

/docker-entrypoint.d/20-envsubst-on-templates.sh

# Validate file configuration

nginx -t

# Remove PDF cache files
# Les fichiers de cache Nginx sont nommés par hash MD5, sans extension :
# les entrées PDF s'identifient via l'en-tête "KEY:" (l'URL en clair) présent
# dans chaque fichier, pas via un motif sur le nom du fichier.

{ grep -rlZ "^KEY: .*\.pdf" /tmp/nginx_cache/ 2> /dev/null || true; } \
  | xargs -0r rm -f

# Trigger nginx reload

nginx -s reload
