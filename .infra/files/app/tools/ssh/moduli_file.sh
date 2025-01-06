#!/usr/bin/env bash
set -euo pipefail
#Needs to be run as sudo

awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe