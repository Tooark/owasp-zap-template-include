#!/usr/bin/env bash
set -euo pipefail

# Create artifacts directory and initialize dotenv file
mkdir -p artifacts
ENV_FILE="artifacts/auth.env"
: > "$ENV_FILE"
export ENV_FILE

# Resolve script directory and handler path (packaged or local)
SCRIPT_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
HANDLER="/opt/zap-auth/handlers/${AUTH_TYPE}.sh"
if [[ ! -f "$HANDLER" ]]; then
  HANDLER="$SCRIPT_DIR/../auth_type/handlers/${AUTH_TYPE}.sh"
fi

if [[ ! -f "$HANDLER" ]]; then
  echo "ERROR: handler for AUTH_TYPE='${AUTH_TYPE}' not found; looked at /opt and ${SCRIPT_DIR}/../auth_type/handlers" >&2
  exit 1
fi

echo "▶ Running auth handler: ${AUTH_TYPE} (handler: $HANDLER)"
# shellcheck source=/dev/null
source "$HANDLER"

echo "✅ Handler finished. Keys written to $ENV_FILE:"
grep -E '^[A-Z_]+=.*' "$ENV_FILE" | cut -d= -f1 || true
