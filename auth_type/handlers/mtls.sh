#!/usr/bin/env bash
set -euo pipefail

# Handler: mTLS
# Expects either ZAP_MTLS_P12_B64 (base64 content) or mtls_p12_var pointing to a CI var name
# Also accepts ZAP_MTLS_P12_PASSWORD or mtls_p12_password_var

P12_SOURCE="${ZAP_MTLS_P12_B64:-${mtls_p12_var:-}}"
P12_PASSWORD="${ZAP_MTLS_P12_PASSWORD:-${mtls_p12_password_var:-}}"

if [[ -z "$P12_SOURCE" ]]; then
  echo "ERROR: no P12 source provided (ZAP_MTLS_P12_B64 or mtls_p12_var)" >&2
  exit 1
fi

# If source is a name of an env var, use its content
if printenv "$P12_SOURCE" >/dev/null 2>&1; then
  P12_B64="$(printenv "$P12_SOURCE")"
else
  P12_B64="$P12_SOURCE"
fi

mkdir -p artifacts
echo "$P12_B64" | base64 --decode > artifacts/client.p12

cat >> "$ENV_FILE" <<EOF
ZAP_AUTH_METHOD=mtls
ZAP_AUTH_P12_FILE=client.p12
ZAP_AUTH_P12_PASSWORD=${P12_PASSWORD}
EOF

echo "WROTE: ZAP_AUTH_METHOD=mtls (client.p12)"
