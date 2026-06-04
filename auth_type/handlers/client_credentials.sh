#!/usr/bin/env bash
set -euo pipefail

# Handler: OIDC client_credentials
# Expects: OIDC_TOKEN_ENDPOINT, OIDC_CLIENT_ID, OIDC_CLIENT_SECRET, OIDC_SCOPE (optional)
# Writes: artifacts/auth.env with ZAP_AUTH_METHOD/header values

# Support uppercase and lowercase input variable names
OIDC_TOKEN_ENDPOINT="${OIDC_TOKEN_ENDPOINT:-${oidc_token_endpoint:-}}"
OIDC_CLIENT_ID="${OIDC_CLIENT_ID:-${oidc_client_id:-}}"
OIDC_CLIENT_SECRET="${OIDC_CLIENT_SECRET:-${oidc_client_secret:-}}"
OIDC_SCOPE="${OIDC_SCOPE:-${oidc_scope:-}}"

if [[ -z "$OIDC_TOKEN_ENDPOINT" || -z "$OIDC_CLIENT_ID" || -z "$OIDC_CLIENT_SECRET" ]]; then
	echo "ERROR: missing OIDC config (OIDC_TOKEN_ENDPOINT, OIDC_CLIENT_ID, OIDC_CLIENT_SECRET)" >&2
	exit 1
fi

RESPONSE=$(curl -sf -X POST "$OIDC_TOKEN_ENDPOINT" \
	-H "Content-Type: application/x-www-form-urlencoded" \
	--data-urlencode "grant_type=client_credentials" \
	--data-urlencode "client_id=${OIDC_CLIENT_ID}" \
	--data-urlencode "client_secret=${OIDC_CLIENT_SECRET}" \
	--data-urlencode "scope=${OIDC_SCOPE:-}")

TOKEN=$(echo "$RESPONSE" | jq -r '.access_token' 2>/dev/null || true)
if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
	echo "ERROR: failed to obtain access token: $RESPONSE" >&2
	exit 1
fi

cat >> "$ENV_FILE" <<EOF
ZAP_AUTH_METHOD=header
ZAP_AUTH_HEADER_NAME=Authorization
ZAP_AUTH_HEADER_VALUE=Bearer $TOKEN
EOF

echo "WROTE: ZAP_AUTH_METHOD=header"
