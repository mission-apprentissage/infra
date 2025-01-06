#!/usr/bin/env bash
set -euo pipefail
#Needs to be run as sudo

iptables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
iptables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 10 --hitcount 10 -j DROP
ip6tables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
ip6tables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 10 --hitcount 10 -j DROP
