#!/bin/bash
# client_credentials_token.sh
# Registre um App no Entra ID / Okta / Auth0 só para o scanner

TENANT_ID="${TENANT_ID}"
CLIENT_ID="${ZAP_CLIENT_ID}"
CLIENT_SECRET="${ZAP_CLIENT_SECRET}"
SCOPE="api://${API_CLIENT_ID}/.default"   # Entra ID
# SCOPE="your-api/read" # Okta / Auth0

RESPONSE=$(curl -sf -X POST \
  "https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=client_credentials" \
  --data-urlencode "client_id=${CLIENT_ID}" \
  --data-urlencode "client_secret=${CLIENT_SECRET}" \
  --data-urlencode "scope=${SCOPE}")

TOKEN=$(echo "$RESPONSE" | jq -r '.access_token')
[[ "$TOKEN" == "null" || -z "$TOKEN" ]] && { echo "Erro: $RESPONSE"; exit 1; }

# Exporta para os próximos steps do pipeline
echo "ZAP_TOKEN=${TOKEN}" >> "$GITHUB_ENV"
echo "::add-mask::${TOKEN}"
echo "Token obtido com sucesso"
