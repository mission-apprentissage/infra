#!/usr/bin/env bash
set -euo pipefail

# Check if lock file exists
if [ ! -f /var/lib/apt/lists/lock ]; then
  exit 0
fi

# Check if apt is locked
PID=$(lsof -t /var/lib/apt/lists/lock || true)

# If apt is not locked, exit
if [ -z "$PID" ]; then
  exit 0
fi

# If apt is locked, check for how long
TIME=$(ps -p $PID -o etimes=)

# If apt is locked for more than 1 hour, kill the process
if [ "$TIME" -gt 3600 ]; then
  echo "apt process is stuck"
  kill -SIGTERM $PID
fi
