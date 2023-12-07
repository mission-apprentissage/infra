#!/usr/bin/env bash
set -euo pipefail

readonly TEXT_MESSAGE=${1:?"Please provide a text message"}
readonly SLACK_URL="{{ vault[product_name].SLACK_WEBHOOK_URL }}"
readonly MNA_ENV="{{ product_name }}_{{ env_type }}"

curl -s -o /dev/null -X POST --data-urlencode \
  "payload={\"text\": \"[${MNA_ENV}] ${TEXT_MESSAGE}\" }" "${SLACK_URL}"
