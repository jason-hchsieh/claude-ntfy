#!/usr/bin/env bash
# Claude Code hook: sends ntfy notification when Claude stops responding.
# Hook event: Stop
#
# Required env vars:
#   NTFY_SERVER_URL - ntfy server URL (default: http://localhost:8080)
#   NTFY_TOPIC      - ntfy topic to publish to
# Optional env vars:
#   NTFY_TOKEN      - Bearer token for authentication

set -euo pipefail

NTFY_SERVER_URL="${NTFY_SERVER_URL:-http://localhost:8080}"
NTFY_TOPIC="${NTFY_TOPIC:?NTFY_TOPIC is required}"

URL="${NTFY_SERVER_URL}/${NTFY_TOPIC}"
HEADERS=(-H "Title: Claude Code finished")

if [[ -n "${NTFY_TOKEN:-}" ]]; then
  HEADERS+=(-H "Authorization: Bearer ${NTFY_TOKEN}")
fi

# Read hook input from stdin (contains session info)
INPUT=$(cat)
STOP_REASON=$(echo "$INPUT" | jq -r '.stop_reason // "completed"' 2>/dev/null || echo "completed")

curl -s "${HEADERS[@]}" -d "Claude Code session ${STOP_REASON}." "$URL" >/dev/null 2>&1 &

exit 0
