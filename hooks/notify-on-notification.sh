#!/usr/bin/env bash
# Claude Code hook: forwards Claude notification events to ntfy.
# Hook event: Notification
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
HEADERS=(-H "Title: Claude Code")

if [[ -n "${NTFY_TOKEN:-}" ]]; then
  HEADERS+=(-H "Authorization: Bearer ${NTFY_TOKEN}")
fi

# Read hook input from stdin
INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Notification from Claude Code"' 2>/dev/null || echo "Notification from Claude Code")

curl -s "${HEADERS[@]}" -d "$MESSAGE" -- "$URL" >/dev/null &

exit 0
