#!/usr/bin/env bash
set -euo pipefail

# Handler: local JWT login (API returns token on login)
# Expects: JWT_LOGIN_URL, JWT_LOGIN_PAYLOAD_TEMPLATE, JWT_TOKEN_JQ_PATH

JWT_LOGIN_URL="${JWT_LOGIN_URL:-${jwt_login_url:-}}"
JWT_LOGIN_PAYLOAD_TEMPLATE="${JWT_LOGIN_PAYLOAD_TEMPLATE:-${jwt_login_payload_template:-}}"
JWT_TOKEN_JQ_PATH="${JWT_TOKEN_JQ_PATH:-${jwt_token_jq_path:-.access_token}}"

if [[ -z "$JWT_LOGIN_URL" ]]; then
  echo "ERROR: JWT_LOGIN_URL is required" >&2
  exit 1
fi

PAYLOAD="$(echo "$JWT_LOGIN_PAYLOAD_TEMPLATE" | envsubst)"
RESPONSE=$(curl -sf -X POST "$JWT_LOGIN_URL" -H "Content-Type: application/json" --data "$PAYLOAD")

TOKEN=$(echo "$RESPONSE" | jq -r "$JWT_TOKEN_JQ_PATH" 2>/dev/null || true)
if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "ERROR: failed to obtain JWT token: $RESPONSE" >&2
  exit 1
fi

cat >> "$ENV_FILE" <<EOF
ZAP_AUTH_METHOD=header
ZAP_AUTH_HEADER_NAME=Authorization
ZAP_AUTH_HEADER_VALUE=Bearer $TOKEN
EOF

echo "WROTE: ZAP_AUTH_METHOD=header (JWT local)"
