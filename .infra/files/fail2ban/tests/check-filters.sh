#!/usr/bin/env bash
# Rejoue chaque ligne de cases/<filtre>.txt dans fail2ban-regex et compare au résultat attendu.
# Exécuté dans le conteneur par run.sh.
set -uo pipefail

fail=0
for cases in /repo/tests/cases/*.txt; do
  filter="$(basename "$cases" .txt)"
  expected="" count=0
  while IFS= read -r line; do
    case "$line" in
      "# attendu: "*) expected="${line#\# attendu: }"; continue ;;
      "#"* | "") continue ;;
    esac
    count=$((count + 1))
    printf '%s\n' "$line" > /tmp/line.log
    out="$(fail2ban-regex -v /tmp/line.log "/repo/filter.d/$filter.conf" 2>&1)"
    if grep -q '^Lines: 1 lines, 1 ignored, 0 matched, 0 missed' <<<"$out"; then
      actual="ignored"
    elif grep -q '^Lines: 1 lines, 0 ignored, 0 matched, 1 missed' <<<"$out"; then
      actual="missed"
    else
      # En mode -v, fail2ban-regex liste chaque IP comptée : « |      <ip>  <date> ».
      actual="$(sed -nE 's/^\|[[:space:]]+([0-9a-f.:]+)  [A-Z][a-z]{2} .*/\1/p' <<<"$out")"
    fi
    if [[ -z "$expected" || "$actual" != "$expected" ]]; then
      echo "✗ $filter, cas $count : attendu « ${expected:-non déclaré} », obtenu « ${actual:-rien} »"
      echo "  $line"
      fail=1
    fi
    expected=""
  done < "$cases"
  echo "› $filter : $count lignes rejouées"
  [[ "$count" -gt 0 ]] || { echo "✗ $filter : aucun cas"; fail=1; }
done
exit "$fail"
