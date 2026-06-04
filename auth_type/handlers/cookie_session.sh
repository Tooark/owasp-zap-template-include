#!/usr/bin/env bash
set -euo pipefail

# Handler: Cookie/session login
# Expects: SESSION_LOGIN_URL, and either SESSION_LOGIN_FORM_TEMPLATE or SESSION_USER+SESSION_PASS
# Writes cookies to artifacts/cookies.txt and emits auth.env with cookie info

SESSION_LOGIN_URL="${SESSION_LOGIN_URL:-${session_login_url:-}}"
SESSION_LOGIN_FORM_TEMPLATE="${SESSION_LOGIN_FORM_TEMPLATE:-${session_login_form_template:-}}"
SESSION_COOKIE_NAME="${SESSION_COOKIE_NAME:-${session_cookie_name:-JSESSIONID}}"

if [[ -z "$SESSION_LOGIN_URL" ]]; then
  echo "ERROR: SESSION_LOGIN_URL is required" >&2
  exit 1
fi

if [[ -z "$SESSION_LOGIN_FORM_TEMPLATE" ]]; then
  if [[ -z "${SESSION_USER:-}" || -z "${SESSION_PASS:-}" ]]; then
    echo "ERROR: SESSION_USER and SESSION_PASS are required when no form template provided" >&2
    exit 1
  fi
  SESSION_LOGIN_FORM_TEMPLATE="username=${SESSION_USER}&password=${SESSION_PASS}"
fi

# Perform login and save cookies
curl -sf -c artifacts/cookies.txt -X POST "$SESSION_LOGIN_URL" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data "$SESSION_LOGIN_FORM_TEMPLATE"

cat >> "$ENV_FILE" <<EOF
ZAP_AUTH_METHOD=cookie
ZAP_AUTH_COOKIE_FILE=cookies.txt
ZAP_AUTH_COOKIE_NAME=${SESSION_COOKIE_NAME}
EOF

echo "WROTE: ZAP_AUTH_METHOD=cookie"
