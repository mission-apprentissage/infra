#!/usr/bin/env bash
set -euo pipefail
#Needs to be run as sudo

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock sudobmitch/docker-stack-wait {{product_name}}
