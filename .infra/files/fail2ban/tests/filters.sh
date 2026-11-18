#!/usr/bin/env bash
# Test des filtres et des jails fail2ban nginx (filter.d/nginx-*.conf, jail.d/nginx.local).
#
# Construit une image Ubuntu 24.04 avec le paquet fail2ban de la distribution, rejoue des lignes
# factices d'error.log à travers fail2ban-regex, puis démarre fail2ban avec les jails du dépôt
# et vérifie que les jails nginx lisent le fichier.
#
# Usage : .infra/files/fail2ban/tests/filters.sh
# Sortie non nulle si une assertion échoue. Adresses IP des plages de documentation uniquement.
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FAIL2BAN_DIR="$(dirname "$HERE")"
readonly IMAGE="fail2ban-filters-test"
readonly WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "› Build de l'image $IMAGE"
docker build -q -t "$IMAGE" - >/dev/null <<'DOCKERFILE'
FROM ubuntu:24.04
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends fail2ban python3-systemd \
 && rm -rf /var/lib/apt/lists/*
DOCKERFILE

# Un cas par ligne : filtre @@ attendu @@ ligne d'error.log.
# attendu = l'IP comptée, « ignored » (ignoreregex) ou « missed » (aucune expression).
readonly P='2026/11/18 17:29:55 [error] 15531#15531: *1'
readonly S='server: example.test, request: "GET /x HTTP/2.0", host: "example.test"'
cat > "$WORKDIR/cases" <<CASES
nginx-req-limit@@203.0.113.1@@$P limiting requests, excess: 3.200 by zone "lba_autocomplete", client: 203.0.113.1, $S
nginx-req-limit@@2001:db8::1@@$P limiting requests, excess: 3.200 by zone "lba_public_search", client: 2001:db8::1, $S
nginx-req-limit@@ignored@@$P limiting requests, excess: 101.000 by zone "flood", client: 203.0.113.2, $S
nginx-req-limit@@ignored@@$P limiting requests, excess: 5.000 by zone "lba_bff_recherche", client: 203.0.113.3, $S
nginx-req-limit@@203.0.113.4@@$P limiting requests, excess: 5.000 by zone "flood2", client: 203.0.113.4, $S
nginx-req-limit@@203.0.113.5@@$P limiting requests, excess: 5.000 by zone "api_flood", client: 203.0.113.5, $S
nginx-req-limit@@203.0.113.6@@$P limiting requests, excess: 5.000 by zone "lba_autocomplete", client: 203.0.113.6, $S, referrer: "x, client: 198.51.100.99"
nginx-req-limit@@203.0.113.7@@$P limiting requests, excess: 5.000 by zone "lba_autocomplete", client: 203.0.113.7, $S, referrer: "by zone "a_recherche""
nginx-req-limit@@203.0.113.8@@$P limiting requests, excess: 5.000 by zone "lba_autocomplete", client: 203.0.113.8, $S, referrer: "by zone "flood", client: 198.51.100.99"
nginx-req-limit@@203.0.113.9@@$P limiting requests, excess: 5.000 by zone "lba_autocomplete", client: 203.0.113.9, server: example.test, request: "GET /recherche?q=x_recherche HTTP/2.0", host: "example.test", referrer: "https://example.test/recherche"
nginx-req-limit@@missed@@$P delaying request, excess: 0.500 by zone "lba_autocomplete", client: 203.0.113.10, $S
nginx-req-limit@@missed@@$P limiting connections by zone "perip", client: 203.0.113.11, $S
nginx-conn-limit@@203.0.113.12@@$P limiting connections by zone "perip", client: 203.0.113.12, $S
nginx-conn-limit@@203.0.113.13@@$P limiting connections by zone "perip", client: 203.0.113.13, $S, referrer: "x, client: 198.51.100.99"
nginx-conn-limit@@missed@@$P limiting requests, excess: 5.000 by zone "lba_autocomplete", client: 203.0.113.14, $S
nginx-conn-limit-long@@missed@@$P open() "/x" failed (2: No such file or directory), client: 203.0.113.15, $S, referrer: "fausse sequence improbable pour garantir uniquement le declenchement manuel, client: 198.51.100.99"
nginx-conn-limit-long@@missed@@$P fausse sequence improbable pour garantir uniquement le declenchement manuel, client: 203.0.113.16
nginx-conn-limit-long@@missed@@$P limiting requests, excess: 5.000 by zone "lba_autocomplete", client: 203.0.113.17, $S
CASES

cat > "$WORKDIR/run.sh" <<'RUN'
#!/bin/bash
set -uo pipefail
fail=0
ko() { echo "  ✗ $*"; fail=1; }

n=0
while IFS= read -r case; do
  n=$((n + 1))
  filter="${case%%@@*}"; rest="${case#*@@}"; expected="${rest%%@@*}"; line="${rest#*@@}"
  printf '%s\n' "$line" > /tmp/line.log
  out="$(fail2ban-regex -v /tmp/line.log "/repo/filter.d/$filter.conf" 2>&1)"
  if grep -q '^Lines: 1 lines, 1 ignored, 0 matched, 0 missed' <<<"$out"; then actual=ignored
  elif grep -q '^Lines: 1 lines, 0 ignored, 0 matched, 1 missed' <<<"$out"; then actual=missed
  else actual="$(sed -nE 's/^\|[[:space:]]+([0-9a-f.:]+)  [A-Z][a-z]{2} .*/\1/p' <<<"$out" | paste -sd, -)"; fi
  [[ "$actual" == "$expected" ]] || ko "cas $n ($filter) : attendu « $expected », obtenu « ${actual:-rien} » — $line"
done < /cases
echo "› $n lignes rejouées dans fail2ban-regex"
[[ "$n" -gt 0 ]] || ko "aucun cas rejoué"

# Jails du dépôt, sans action de ban (ni iptables ni ipset dans le conteneur).
cp /repo/filter.d/* /etc/fail2ban/filter.d/
for f in /repo/jail.d/nginx.local /repo/jail.d/sshd.local; do
  grep -v '^banaction' "$f" > "/etc/fail2ban/jail.d/$(basename "$f")"
done
printf '[DEFAULT]\nbanaction = dummy\nbanaction_allports = dummy\n' > /etc/fail2ban/jail.d/zz-test.local
mkdir -p /opt/app/system/nginx && touch /opt/app/system/nginx/error.log /var/log/auth.log
fail2ban-server -xf --logtarget=/tmp/f2b.log --loglevel=INFO start >/dev/null 2>&1 &
for _ in $(seq 1 30); do grep -q "Jail 'nginx-conn-limit-long' started" /tmp/f2b.log 2>/dev/null && break; sleep 1; done
echo "$(date -u '+%Y/%m/%d %H:%M:%S') [error] 1#1: *1 limiting requests, excess: 5.000 by zone \"lba_autocomplete\", client: 203.0.113.50, server: example.test, request: \"GET /x HTTP/2.0\", host: \"example.test\"" >> /opt/app/system/nginx/error.log
for _ in $(seq 1 15); do grep -q 'Found 203.0.113.50' /tmp/f2b.log && break; sleep 1; done

for jail in nginx-req-limit nginx-conn-limit nginx-conn-limit-long; do
  grep -qE "Jail '$jail' uses (pyinotify|poller) " /tmp/f2b.log || ko "$jail ne lit pas un fichier : $(grep "Jail '$jail' uses" /tmp/f2b.log || echo 'jail non démarré')"
done
grep -q "Jail 'sshd' uses systemd " /tmp/f2b.log || ko "sshd n'utilise pas le backend systemd"
grep -q '\[nginx-req-limit\] Found 203.0.113.50' /tmp/f2b.log || ko "aucun Found pour une ligne écrite dans error.log"
echo "› fail2ban démarré avec les jails du dépôt"

[[ "$fail" -eq 0 ]] && echo "✓ Tous les tests passent" || { echo "✗ Échec"; cat /tmp/f2b.log; }
exit "$fail"
RUN

docker run --rm -v "$FAIL2BAN_DIR":/repo:ro -v "$WORKDIR/cases":/cases:ro -v "$WORKDIR/run.sh":/run.sh:ro "$IMAGE" bash /run.sh
