#!/usr/bin/env bash
#
# Test de non-régression de la politique de cache du reverse proxy
# (cf. docker/reverse_proxy/files/templates/conf.d/cache.conf.template).
#
# Rejoue le scénario de l'incident LBA du 2026-09-01 : l'amont sert des réponses portant les
# en-têtes exacts mesurés sur la prod, on remplit le cache, on change le contenu de l'amont
# (= nouveau déploiement de l'UI), et on vérifie ce que le proxy ressert.
#
# Attendu : les réponses document de Next sont resservies à jour (jamais stockées), les assets
# immuables et les réponses d'API explicitement cachables restent servies depuis le cache. Le
# test couvre les deux includes de proxy, `proxy.conf` et `proxy_sub_path.conf`.
#
# Chaque cas assert le corps servi ET la valeur de X-Cache-Status. Asserter le seul corps
# laisserait disparaître l'en-tête sans que rien ne le signale, alors qu'il est le seul moyen
# de vérifier l'état du cache depuis l'extérieur.
#
# Pour vérifier que ce test n'est pas vacuous, deux manipulations, chacune doit le faire échouer :
#   - commenter `proxy_no_cache` dans conf.d/cache.conf.template  → /doc sert BUILD-A en HIT
#   - commenter `proxy_cache_bypass` dans conf.d/cache.conf.template → /doc?_rsc= passe en MISS
#   - commenter `add_header X-Cache-Status` dans conf.d/headers.conf.template → statut « - » partout
#
# Piège que ce test verrouille : `proxy_no_cache` et `proxy_cache_bypass` ne sont pas cumulatifs
# entre niveaux. Redéclarer l'une d'elles dans un include de location écraserait les conditions
# de cache.conf et ferait échouer /doc.
#
# Volontairement écrit pour bash 3.2 (bash système de macOS) : ni tableau associatif, ni autre
# construction de bash 4, sinon le script part en erreur de syntaxe et affiche un tableau faux
# au lieu d'échouer proprement.
#
# Usage : ./run.sh   (nécessite Docker ; `docker compose down` pour nettoyer à la fin)

set -uo pipefail
cd "$(dirname "$0")"

readonly BASE=http://127.0.0.1:18080

# "uri|corps attendu|X-Cache-Status attendu", APRÈS le changement de build côté amont.
# BUILD-B = réponse fraîche (non stockée)  |  BUILD-A = réponse servie depuis le cache proxy
readonly CASES=(
  # via includes/proxy.conf
  "/doc|BUILD-B|MISS"                       # document Next prérendu : s-maxage=31536000, ne doit PAS être caché
  "/doc-ppr|BUILD-B|MISS"                   # document Next PPR : Next envoie déjà no-store
  "/_next/static/chunks/a.js|BUILD-A|HIT"   # asset versionné par hash : doit rester caché
  "/api/version|BUILD-B|MISS"               # API sans Cache-Control : jamais cachée, hier comme aujourd'hui
  "/api-public/data|BUILD-A|HIT"            # API qui demande explicitement le cache : sémantique inchangée
  # requête RSC : Next y met un cache-buster unique, l'entrée ne serait jamais resservie.
  # BYPASS et non MISS : $arg__rsc est connu avant l'appel amont, il court-circuite la lecture.
  "/doc?_rsc=abc123|BUILD-B|BYPASS"
  # via includes/proxy_sub_path.conf, qui porte sa propre directive proxy_cache
  "/sub/doc|BUILD-B|MISS"
  "/sub/_next/static/chunks/a.js|BUILD-A|HIT"
)

probe() { # $1=uri  ->  "corps|X-Cache-Status"
  # En-têtes et corps sont lus dans deux fichiers distincts : extraire le corps du flux complet
  # casserait dès qu'une réponse de test tiendrait sur plus d'une ligne.
  local hdr body st corps
  hdr=$(mktemp); body=$(mktemp)
  curl -s --max-time 5 -D "$hdr" -o "$body" "$BASE$1"
  st=$(grep -i '^x-cache-status:' "$hdr" | tr -d '\r' | awk '{print $2}')
  corps=$(tr -d '\r\n' < "$body")
  rm -f "$hdr" "$body"
  printf '%s|%s' "$corps" "${st:--}"
}

# Le build A doit être en place AVANT le démarrage du proxy : toute requête émise pendant
# l'attente de disponibilité irait sinon remplir le cache avec le contenu de l'exécution
# précédente, et le test passerait pour de mauvaises raisons.
mkdir -p srv
echo "BUILD-A" > srv/build.txt

echo "Build de l'image et démarrage de la stack..."
docker compose down --remove-orphans >/dev/null 2>&1
if ! docker compose up -d --build >/dev/null; then
  echo "ECHEC : la stack de test n'a pas démarré (port 18080 déjà pris ?)." >&2
  exit 2
fi

# /doc-ppr sert de sonde : Next y envoie no-store, la réponse n'est donc jamais mise en cache.
# Sans cette garde, un conteneur tiers lié au port 18080 répondrait à notre place et le test
# passerait en interrogeant la mauvaise stack.
ready=0
for _ in $(seq 20); do
  if [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "$BASE/doc-ppr")" = "200" ]; then ready=1; break; fi
  sleep 1
done
if [ "$ready" != "1" ] || [ "$(docker compose ps --status running --services | grep -c '^reverse_proxy$')" != "1" ]; then
  echo "ECHEC : le reverse proxy de test ne répond pas sur $BASE." >&2
  docker compose ps >&2
  exit 2
fi

# Le test compare "servi depuis le cache" et "refetché" : il n'a de sens que sur un cache vide
# au départ. Un conteneur proxy survivant d'une exécution précédente rendrait le résultat
# non déterministe (entrées déjà expirées, contenu du build précédent).
# `-type f` parce que ce qu'on cherche, ce sont des entrées, pas des dossiers. Aujourd'hui le
# cache est à plat (proxy_cache_path sans `levels=`) et nginx n'y crée aucun répertoire, la
# distinction ne change donc rien. Elle protège d'un futur `levels=` : les répertoires de
# niveaux survivent à l'éviction de leurs entrées et feraient échouer une garde trop large.
if [ -n "$(docker compose exec -T reverse_proxy find /tmp/nginx_cache -mindepth 1 -type f 2>/dev/null)" ]; then
  echo "ECHEC : le cache du proxy de test n'est pas vide au démarrage." >&2
  exit 2
fi

echo "Remplissage du cache proxy (build A)..."
for c in "${CASES[@]}"; do
  probe "${c%%|*}" >/dev/null
  probe "${c%%|*}" >/dev/null
done

echo "Nouveau déploiement de l'amont (build B)..."
echo "BUILD-B" > srv/build.txt
docker compose restart upstream >/dev/null 2>&1
sleep 2

fail=0
printf '\n%-32s %-18s %-18s %s\n' URL "ATTENDU" "SERVI" VERDICT
for c in "${CASES[@]}"; do
  uri=${c%%|*}
  reste=${c#*|}
  attendu_corps=${reste%%|*}
  attendu_statut=${reste##*|}
  IFS='|' read -r corps statut <<< "$(probe "$uri")"
  if [ "$corps" = "$attendu_corps" ] && [ "$statut" = "$attendu_statut" ]; then verdict=OK; else verdict=ECHEC; fail=1; fi
  printf '%-32s %-18s %-18s %s\n' "$uri" "$attendu_corps/$attendu_statut" "$corps/$statut" "$verdict"
done

echo
if [ $fail -eq 0 ]; then echo "Tous les cas passent."; else echo "Au moins un cas échoue."; fi
exit $fail
