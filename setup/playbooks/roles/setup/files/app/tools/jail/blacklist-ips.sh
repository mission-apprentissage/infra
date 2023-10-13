#!/usr/bin/env bash
# Blacklist list of bad/dangerous IPs
# Daily feed from : https://github.com/stamparm/ipsum

set -euo pipefail

# iptables -D INPUT -m set --match-set ipsum src -j DROP 2>/dev/null || true
# ipset destroy ipsum

for ip in $(curl --compressed https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt 2>/dev/null | grep -v "#" | grep -v -E "\s[1-2]$" | cut -f 1); do 
  bash /opt/app/tools/jail/ban-ip.sh $ip
done

# specific blacklist
bash /opt/app/tools/jail/ban-ip.sh 3.92.127.83
bash /opt/app/tools/jail/ban-ip.sh 82.165.82.41

bash /opt/app/tools/send-to-slack.sh "[IPTABLES] IPs blacklist has been renewed."
