#!/usr/bin/env bash
# Test du masquage des paramètres d'URL sensibles (conf.d/01_redact.conf).
#
# Construit l'image fluentd du repo, rejoue des lignes factices (Nginx, error.log,
# JSON applicatif, enregistrement sans clé "log") à travers 01_redact.conf puis
# les parsers réels de 03_nginx.conf et 50_parse_json.conf, et vérifie la sortie.
#
# Usage : docker/fluentd/tests/redact.sh
# Sortie non nulle si une assertion échoue. Aucune valeur réelle : JWT et emails inventés.
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FLUENTD_DIR="$(dirname "$HERE")"
readonly IMAGE="fluentd-redact-test"
readonly WORKDIR="$(mktemp -d)"
readonly CONTAINER="fluentd-redact-test-$$"
trap 'docker rm -f "$CONTAINER" >/dev/null 2>&1 || true; rm -rf "$WORKDIR"' EXIT

# JWT factice construit à l'exécution (header.payload.signature, aucune donnée
# réelle) : pas de littéral en forme de JWT dans la source, sinon les scanners
# de secrets le signalent.
b64url() { printf '%s' "$1" | base64 | tr -d '=\n' | tr '+/' '-_'; }
readonly JWT="$(b64url '{"alg":"none","typ":"JWT"}').$(b64url '{"fake":true}').fakesignature"

echo "› Build de l'image $IMAGE"
docker build -q -t "$IMAGE" "$FLUENTD_DIR" >/dev/null

# Conf de test : source sample -> 01_redact -> parsers réels -> stdout (json)
{
  cat <<CONF
<source>
  @type sample
  tag docker.nginx.test.test.nginx
  rate 100
  auto_increment_key n
  sample [
    {"log":"203.0.113.10 - [2026/09/02 10:00:00] \"GET /formulaire-intention?company_recruitment_intention=entretien&id=abc123&token=${JWT} HTTP/1.1\" 200 1234 \"https://lba.example/formulaire-intention?company_recruitment_intention=entretien&id=abc123&token=${JWT}\" \"Mozilla/5.0\" \"-\" \"lba.example\" 0.012"},
    {"log":"203.0.113.10 - [2026/09/02 10:00:01] \"GET /api/x?Access_Token=SECRET_A&jwt=SECRET_B&EMAIL=jane%40example.org&utm_source=news&api-key=SECRET_C&apiKey=SECRET_D&client_secret=SECRET_E&password=SECRET_F HTTP/1.1\" 200 12 \"https://ref.example/?refresh_token=SECRET_G&id=1\" \"UA\" \"-\" \"host\" 0.001"},
    {"log":"203.0.113.10 - [2026/09/02 10:00:02] \"GET /tokens?mytokenizer=1&q=token HTTP/1.1\" 200 12 \"-\" \"UA\" \"-\" \"host\" 0.001"},
    {"log":"2026/09/02 10:00:03 [error] 12#12: *1 open() failed, request: \"GET /x?token=SECRET_H HTTP/1.1\""}
  ]
</source>
<source>
  @type sample
  tag docker.json.test.test.server
  rate 100
  auto_increment_key n
  sample [
    {"log":"{\"level\":30,\"msg\":\"request completed\",\"req\":{\"url\":\"/api/y?token=${JWT}\",\"headers\":{\"referer\":\"https://lba.example/?token=${JWT}&utm_source=a\"}}}"},
    {"log":"{\"level\":30,\"msg\":\"see \\\\\"?token=SECRET_I\\\\\" here\"}"}
  ]
</source>
<source>
  @type sample
  tag docker.json.test.test.modesec
  rate 100
  sample {"transaction":{"id":"t1"}}
</source>
CONF
  cat "$FLUENTD_DIR/conf.d/01_redact.conf"
  sed -n '/^<filter/,/^<\/filter>/p' "$FLUENTD_DIR/conf.d/03_nginx.conf"
  sed -n '/^<filter docker.json.\*.\*.\*>$/,/^<\/filter>/p' "$FLUENTD_DIR/conf.d/50_parse_json.conf" | sed -n '1,/^<\/filter>/p'
  cat <<CONF
<match docker.**>
  @type stdout
  <format>
    @type json
  </format>
</match>
CONF
} > "$WORKDIR/fluent.conf"

echo "› Exécution"
docker run -d --name "$CONTAINER" -v "$WORKDIR:/fluentd/etc:ro" "$IMAGE" >/dev/null
sleep 6
docker logs "$CONTAINER" 2>/dev/null | grep -E '^\{' > "$WORKDIR/out.jsonl" || true
[ -s "$WORKDIR/out.jsonl" ] || { echo "ÉCHEC : aucune sortie fluentd"; docker logs "$CONTAINER" | tail -20; exit 1; }

fail=0
must_contain() { grep -qF -- "$1" "$WORKDIR/out.jsonl" && echo "  ok   contient   : $1" || { echo "  KO   absent     : $1"; fail=1; }; }
must_not_contain() { grep -qF -- "$1" "$WORKDIR/out.jsonl" && { echo "  KO   présent    : $1"; fail=1; } || echo "  ok   absent     : $1"; }

echo "› Assertions"
# Aucune valeur sensible ne doit survivre
must_not_contain "$JWT"
for s in SECRET_A SECRET_B SECRET_C SECRET_D SECRET_E SECRET_F SECRET_G SECRET_H SECRET_I jane%40example.org; do must_not_contain "$s"; done
# Nginx : champs dérivés masqués
must_contain '"nginx_path":"/formulaire-intention?company_recruitment_intention=entretien&id=abc123&token=[redacted]"'
must_contain '"nginx_referer":"https://lba.example/formulaire-intention?company_recruitment_intention=entretien&id=abc123&token=[redacted]"'
must_contain 'Access_Token=[redacted]&jwt=[redacted]&EMAIL=[redacted]&utm_source=news&api-key=[redacted]&apiKey=[redacted]&client_secret=[redacted]&password=[redacted]'
must_contain '"nginx_referer":"https://ref.example/?refresh_token=[redacted]&id=1"'
must_contain 'request: \"GET /x?token=[redacted] HTTP/1.1\"'
# Faux positifs : rien à masquer
must_contain '"nginx_path":"/tokens?mytokenizer=1&q=token"'
# JSON applicatif : masqué ET toujours parsable (log_msg extrait)
must_contain '"url":"/api/y?token=[redacted]"'
must_contain '"referer":"https://lba.example/?token=[redacted]&utm_source=a"'
must_contain '"log_msg":"request completed"'
must_contain '"log_msg":"see \"?token=[redacted]\" here"'
# Enregistrement sans clé "log" : pas de clé ajoutée
must_contain '"transaction":{"id":"t1"}'
if grep -F '"transaction":{"id":"t1"}' "$WORKDIR/out.jsonl" | grep -qF '"log"'; then
  echo '  KO   clé "log" ajoutée sur un enregistrement qui n en avait pas'; fail=1
else
  echo '  ok   pas de clé "log" ajoutée sur l enregistrement ModSecurity'
fi

if [ "$fail" -ne 0 ]; then echo "ÉCHEC"; exit 1; fi
echo "OK"
