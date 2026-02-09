#!/usr/bin/env bash
# Claude Code hook: sends ntfy notification for Stop, Notification, and PermissionRequest events.
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

if [[ -n "${NTFY_TOKEN:-}" ]]; then
  HEADERS=(-H "Authorization: Bearer ${NTFY_TOKEN}")
else
  HEADERS=()
fi

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""' 2>/dev/null || echo "")
PROJECT=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null | xargs basename 2>/dev/null || echo "")

case "$EVENT" in
  Stop)
    TITLE="Claude Code finished"
    MESSAGE="Session completed in **${PROJECT:-unknown project}**."
    TAGS="white_check_mark"
    PRIORITY="3"
    ;;
  PermissionRequest)
    TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
    TITLE="Claude Code needs permission"
    if [[ -n "$COMMAND" ]]; then
      MESSAGE="**${TOOL}** needs approval"$'\n'"\`${COMMAND}\`"
    else
      MESSAGE="**${TOOL}** needs approval in **${PROJECT:-unknown project}**"
    fi
    TAGS="warning"
    PRIORITY="4"
    ;;
  Notification)
    TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"' 2>/dev/null || echo "Claude Code")
    MESSAGE=$(echo "$INPUT" | jq -r '.message // "Notification from Claude Code"' 2>/dev/null || echo "Notification from Claude Code")
    if [[ -n "$PROJECT" ]]; then
      MESSAGE="${MESSAGE}"$'\n'"_${PROJECT}_"
    fi
    TAGS="bell"
    PRIORITY="3"
    ;;
  *)
    TITLE="Claude Code"
    MESSAGE=$(echo "$INPUT" | jq -r '.message // "Notification from Claude Code"' 2>/dev/null || echo "Notification from Claude Code")
    TAGS="robot"
    PRIORITY="3"
    ;;
esac

curl -s "${HEADERS[@]}" \
  -H "Title: ${TITLE}" \
  -H "Tags: ${TAGS}" \
  -H "Priority: ${PRIORITY}" \
  -H "Markdown: yes" \
  -d "$MESSAGE" -- "$URL" >/dev/null

exit 0
