#!/usr/bin/env bash
# render-zap-yaml.sh
set -euo pipefail

# If an auth dotenv was produced by the auth job and copied into /zap/wrk or artifacts/,
# source it so variables like ZAP_AUTH_METHOD are available for envsubst.
if [[ -f "/zap/wrk/auth.env" ]]; then
  # shellcheck disable=SC1090
  source /zap/wrk/auth.env
elif [[ -f "artifacts/auth.env" ]]; then
  # shellcheck disable=SC1090
  source artifacts/auth.env
fi

BASE="/opt/zap-auth/zap-templates/base.yaml"
PROFILE="/opt/zap-auth/zap-templates/scan-profiles/${SCAN_TYPE}.yaml"

case "${ZAP_AUTH_METHOD:-none}" in
  header)
    AUTH_SNIPPET=$(envsubst < /opt/zap-auth/zap-templates/auth-snippets/header.yaml)
  ;;
  cookie)
    AUTH_SNIPPET=$(envsubst < /opt/zap-auth/zap-templates/auth-snippets/cookie.yaml)
  ;;
  mtls)
    AUTH_SNIPPET=$(envsubst < /opt/zap-auth/zap-templates/auth-snippets/mtls.yaml)
  ;;
  none|"")
    AUTH_SNIPPET=""
  ;;
  *)
    echo "ERROR: unknown ZAP_AUTH_METHOD: $ZAP_AUTH_METHOD" >&2; exit 1 ;;
esac

export AUTH_SNIPPET TARGET_URL OPENAPI_URL
envsubst < "$BASE"
