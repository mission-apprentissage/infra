#!/usr/bin/env bash
set -euo pipefail

# Check if the file /var/run/reboot-required exists
if [ -f /var/run/reboot-required ]; then
    exit 1
fi