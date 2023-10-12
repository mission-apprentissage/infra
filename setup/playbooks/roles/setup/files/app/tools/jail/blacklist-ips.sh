#!/usr/bin/env bash
# Blacklist list of bad/dangerous IPs
# Daily feed from : https://github.com/stamparm/ipsum

set -euo pipefail
#Needs to be run as sudo

ipset -exist create ipsum hash:net
ipset flush ipsum
for ip in $(curl --compressed https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt 2>/dev/null | grep -v "#" | grep -v -E "\s[1-2]$" | cut -f 1); do ipset add ipsum $ip; done

# specific blacklist
ipset add ipsum 3.92.127.83
ipset add ipsum 82.165.82.41

iptables -D INPUT -m set --match-set ipsum src -j DROP 2>/dev/null || true
iptables -I INPUT -m set --match-set ipsum src -j DROP

bash /opt/app/tools/send-to-slack.sh "[IPTABLES] IPs blacklist has been renewed."
