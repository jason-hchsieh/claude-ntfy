#!/usr/bin/env bash
# Claude Code hook: sends ntfy notification for Stop, Notification, and PermissionRequest events.
#
# Configuration can be provided via:
#   - Environment variables (NTFY_SERVER_URL, NTFY_TOPIC, NTFY_TOKEN)
#   - Config file (~/.config/claude-ntfy/config.json or ~/.claude/claude-ntfy/config.json)
#
# Required: NTFY_TOPIC (env var or config file)
# Optional: NTFY_SERVER_URL (default: http://localhost:8080)
# Optional: NTFY_TOKEN (for authentication)

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the config loader
source "${SCRIPT_DIR}/lib/config.sh"

# Load configuration (merges env vars, config files, and defaults)
CONFIG=$(resolve_config) || {
  echo "Error: Failed to load configuration" >&2
  exit 1
}

# Extract configuration values
NTFY_SERVER_URL=$(printf '%s' "$CONFIG" | jq -r '.server_url')
NTFY_TOPIC=$(printf '%s' "$CONFIG" | jq -r '.topic')
NTFY_TOKEN=$(printf '%s' "$CONFIG" | jq -r '.token // empty')

URL="${NTFY_SERVER_URL}/${NTFY_TOPIC}"

if [[ -n "${NTFY_TOKEN:-}" ]]; then
  HEADERS=(-H "Authorization: Bearer ${NTFY_TOKEN}")
else
  HEADERS=()
fi

INPUT=$(cat)
EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // ""' 2>/dev/null || echo "")
PROJECT=$(printf '%s' "$INPUT" | jq -r '.cwd // ""' 2>/dev/null | xargs basename 2>/dev/null || echo "")

# Get hostname and username for context
HOSTNAME=$(hostname 2>/dev/null || echo "unknown")
USERNAME=$(whoami 2>/dev/null || echo "unknown")
USER_HOST="${USERNAME}@${HOSTNAME}"

PROJ="${PROJECT:-unknown}"

case "$EVENT" in
  Stop)
    TITLE="Stop | ${PROJ} | ${USERNAME} @ ${HOSTNAME}"
    MESSAGE="Session completed."
    TAGS="white_check_mark"
    PRIORITY="3"
    ;;
  PermissionRequest)
    TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
    COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
    TITLE="Permission | ${PROJ} | ${USERNAME} @ ${HOSTNAME}"
    if [[ -n "$COMMAND" ]]; then
      MESSAGE="**${TOOL}**: \`${COMMAND}\`"
    else
      MESSAGE="**${TOOL}** needs approval"
    fi
    TAGS="warning"
    PRIORITY="4"
    ;;
  Notification)
    NTFY_TITLE=$(printf '%s' "$INPUT" | jq -r '.title // empty' 2>/dev/null || echo "")
    TITLE="Notification | ${PROJ} | ${USERNAME} @ ${HOSTNAME}"
    MESSAGE=$(printf '%s' "$INPUT" | jq -r '.message // "Notification from Claude Code"' 2>/dev/null || echo "Notification from Claude Code")
    if [[ -n "$NTFY_TITLE" ]]; then
      MESSAGE="**${NTFY_TITLE}**"$'\n'"${MESSAGE}"
    fi
    TAGS="bell"
    PRIORITY="3"
    ;;
  *)
    TITLE="${EVENT:-Event} | ${PROJ} | ${USERNAME} @ ${HOSTNAME}"
    MESSAGE=$(printf '%s' "$INPUT" | jq -r '.message // "Notification from Claude Code"' 2>/dev/null || echo "Notification from Claude Code")
    TAGS="robot"
    PRIORITY="3"
    ;;
esac

curl -s ${HEADERS[@]+"${HEADERS[@]}"} \
  -H "Title: ${TITLE}" \
  -H "Tags: ${TAGS}" \
  -H "Priority: ${PRIORITY}" \
  -H "Markdown: yes" \
  -d "$MESSAGE" -- "$URL" >/dev/null

exit 0
