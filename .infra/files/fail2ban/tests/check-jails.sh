#!/usr/bin/env bash
# Démarre fail2ban avec les filtres et les jails du dépôt, puis vérifie que les jails nginx lisent
# error.log et que sshd reste sur le journal systemd. Exécuté dans le conteneur par run.sh.
set -uo pipefail

readonly LOG=/tmp/fail2ban.log
readonly ERROR_LOG=/opt/app/system/nginx/error.log

cp /repo/filter.d/* /etc/fail2ban/filter.d/
# Ni iptables ni ipset dans le conteneur : les actions de ban du dépôt sont remplacées par une action neutre.
for jail in nginx sshd; do
  grep -v '^banaction' "/repo/jail.d/$jail.local" > "/etc/fail2ban/jail.d/$jail.local"
done
printf '[DEFAULT]\nbanaction = dummy\nbanaction_allports = dummy\n' > /etc/fail2ban/jail.d/zz-test.local
mkdir -p "$(dirname "$ERROR_LOG")" && touch "$ERROR_LOG" /var/log/auth.log

fail2ban-server -xf --logtarget="$LOG" --loglevel=INFO start >/dev/null 2>&1 &
wait_for() { for _ in $(seq 1 30); do grep -q "$1" "$LOG" 2>/dev/null && return; sleep 1; done; }
wait_for "Jail 'nginx-conn-limit-long' started"

echo "$(date -u '+%Y/%m/%d %H:%M:%S') [error] 1#1: *1 limiting requests, excess: 5.000 by zone \"lba_autocomplete\", client: 203.0.113.50, server: example.test, request: \"GET /x HTTP/2.0\", host: \"example.test\"" >> "$ERROR_LOG"
wait_for "Found 203.0.113.50"

fail=0
expect() { grep -qE "$1" "$LOG" || { echo "✗ absent du log fail2ban : $1"; fail=1; }; }
expect "Jail 'nginx-req-limit' uses (pyinotify|poller) "
expect "Jail 'nginx-conn-limit' uses (pyinotify|poller) "
expect "Jail 'nginx-conn-limit-long' uses (pyinotify|poller) "
expect "Jail 'sshd' uses systemd "
expect "\[nginx-req-limit\] Found 203.0.113.50"

if [[ "$fail" -eq 0 ]]; then echo "› jails : backends et détection vérifiés"; else cat "$LOG"; fi
exit "$fail"
