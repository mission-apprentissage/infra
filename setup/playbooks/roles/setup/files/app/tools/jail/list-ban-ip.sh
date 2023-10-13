#!/usr/bin/env bash
set -euo pipefail
#Needs to be run as sudo

JAILS=`fail2ban-client status | grep "Jail list" | sed -E 's/^[^:]+:[ \t]+//' | sed 's/,//g'`
for JAIL in $JAILS
do
  fail2ban-client status $JAIL
done