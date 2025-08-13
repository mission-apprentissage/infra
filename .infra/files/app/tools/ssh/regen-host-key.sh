#!/usr/bin/env bash
set -euo pipefail
#Needs to be run as sudo

rm /etc/ssh/ssh_host_*
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
touch /etc/ssh/ssh_host_keys_generated