#!/usr/bin/env bash
set -euo pipefail
#Needs to be run as sudo

readonly SERVICE=${1:?"Merci de préciser le service"}
shift

docker service logs bal_${SERVICE} "$@"
