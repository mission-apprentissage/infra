#!/usr/bin/env bash

set -euo pipefail

if [ -z "${SCRIPT_DIR:-}" ]; then
  export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -z "${ROOT_DIR:-}" ]; then
  export ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
fi

PRODUCT_NAME=infra . "${ROOT_DIR}/.bin/commands.sh"

PRODUCT_NAME=${1:?"Merci de préciser le produit !"}
shift

VAR_NAME=${1:?"Merci de préciser la variable !"}
shift

env_ini=$(product:ini_file "${PRODUCT_NAME}")

# `ansible-inventory --list` renvoie les hostvars NON rendues : une variable
# comme `host_name={{ product_name }}-production` ressort telle quelle, puis se
# fait découper sur les espaces côté appelant. On passe donc par le moteur de
# template d'Ansible (module debug, connection=local => aucun SSH) pour obtenir
# la valeur réellement rendue, y compris les références imbriquées.
# Ordre aligné sur list_ips.sh : hosts triés, localhost exclu.
ansible all -i "${env_ini}" --connection=local -m debug -a "var=${VAR_NAME}" -o 2> /dev/null \
  | python3 -c '
import sys, json, re
rows = {}
for line in sys.stdin:
    m = re.match(r"^(\S+) \| \w+ => (\{.*\})\s*$", line)
    if not m:
        continue
    host = m.group(1)
    if host == "localhost":
        continue
    val = json.loads(m.group(2)).get(sys.argv[1])
    if val in (None, "VARIABLE IS NOT DEFINED!"):
        continue
    rows[host] = val
print(" ".join(rows[h] for h in sorted(rows)))
' "${VAR_NAME}"
