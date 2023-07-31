#!/usr/bin/env bash
set -euo pipefail

readonly TEXT_MESSAGE=${1:?"Please provide a text message"}
readonly SLACK_URL="{{ vault[product_name].SLACK_WEBHOOK_URL }}"
readonly CHANNEL_NAME="{{ vault[product_name].SLACK_CHANNEL_NAME }}"
readonly MNA_ENV=$(cat /env)

curl -s -o /dev/null -X POST --data-urlencode \
  "payload={\"text\": \"[${MNA_ENV}] ${TEXT_MESSAGE}\", \"channel\": \"${CHANNEL_NAME}\" }" "${SLACK_URL}"
