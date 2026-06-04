#!/bin/bash
# inject_token_zap.sh
ZAP_HOST="http://localhost:8090"
ZAP_KEY="${ZAP_API_KEY}"
TOKEN="${ZAP_TOKEN}"    # vem do step anterior

# Injeta o header em todas as requisições via Replacer
curl -sf "${ZAP_HOST}/JSON/replacer/action/addRule/" \
  --data "apikey=${ZAP_KEY}" \
  --data "description=bearer-auth" \
  --data "enabled=true" \
  --data "matchType=REQ_HEADER" \
  --data "matchString=Authorization" \
  --data "replacement=Bearer ${TOKEN}" \
  --data "initiators=" \
  --data "url="

echo "Header injetado no ZAP"
