#!/usr/bin/env bash
set -euo pipefail

# Handler: API Key header
# Expects one of: API_KEY_VALUE (direct), API_KEY_VAR (name of env var), or ZAP_API_KEY
# Optional: API_KEY_HEADER_NAME (default: X-API-Key)

API_KEY_HEADER_NAME="${API_KEY_HEADER_NAME:-${api_key_header_name:-X-API-Key}}"
API_KEY_VALUE="${API_KEY_VALUE:-${api_key:-${ZAP_API_KEY:-}}}"
API_KEY_VAR="${API_KEY_VAR:-}"

if [[ -z "$API_KEY_VALUE" && -n "$API_KEY_VAR" ]]; then
  API_KEY_VALUE="$(printenv "$API_KEY_VAR" || true)"
fi

if [[ -z "$API_KEY_VALUE" ]]; then
  echo "ERROR: API key not provided; set API_KEY_VALUE, API_KEY_VAR or ZAP_API_KEY" >&2
  exit 1
fi

cat >> "$ENV_FILE" <<EOF
ZAP_AUTH_METHOD=header
ZAP_AUTH_HEADER_NAME=${API_KEY_HEADER_NAME}
ZAP_AUTH_HEADER_VALUE=${API_KEY_VALUE}
EOF

echo "WROTE: ZAP_AUTH_METHOD=header ZAP_AUTH_HEADER_NAME=${API_KEY_HEADER_NAME}"
