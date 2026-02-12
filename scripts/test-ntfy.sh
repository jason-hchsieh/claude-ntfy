#!/usr/bin/env bash
# Send a test notification to verify the ntfy setup is working.
# Uses the same config loader as the hooks.

set -euo pipefail

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
  BOLD='\033[1m' GREEN='\033[32m' RED='\033[31m' RESET='\033[0m'
else
  BOLD='' GREEN='' RED='' RESET=''
fi

ok()   { printf "${GREEN}%s${RESET}\n" "$1"; }
fail() { printf "${RED}%s${RESET}\n" "$1"; }

# ── Load configuration ────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

CONFIG=$(resolve_config 2>&1) || {
  fail "Error: Failed to resolve configuration"
  printf '%s\n' "$CONFIG"
  printf '\nRun the setup skill to configure: /setup\n'
  exit 1
}

set_config_vars "$CONFIG"
build_auth_headers

printf '%bTest Notification%b\n' "$BOLD" "$RESET"
printf "  Server:  %s\n" "$NTFY_SERVER_URL"
printf "  Topic:   %s\n" "$NTFY_TOPIC"
printf "  Token:   %s\n" "${NTFY_TOKEN:+(set)}${NTFY_TOKEN:-(none)}"
echo ""

# ── Check server health ──────────────────────────────────────────

printf "Checking server health... "
HEALTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "${NTFY_SERVER_URL}/v1/health" 2>/dev/null || echo "000")

if [[ "$HEALTH_CODE" != "200" ]]; then
  fail "FAIL (HTTP $HEALTH_CODE)"
  printf 'Server %s is not reachable.\n' "$NTFY_SERVER_URL"
  exit 1
fi
ok "OK"

# ── Send test notification ───────────────────────────────────────

HOSTNAME_VAL=$(hostname 2>/dev/null || echo "unknown")
USERNAME_VAL=$(whoami 2>/dev/null || echo "unknown")

# Detect git branch if in a git repository
GIT_BRANCH=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
fi

# Format project name with branch
PROJECT_NAME="test-ntfy"
if [[ -n "$GIT_BRANCH" ]]; then
  PROJECT_NAME="${PROJECT_NAME} (${GIT_BRANCH})"
fi

printf "Sending test notification... "
RESPONSE=$(curl -s -w "\n%{http_code}" \
  ${NTFY_HEADERS[@]+"${NTFY_HEADERS[@]}"} \
  -H "Title: Test | ${PROJECT_NAME} | ${USERNAME_VAL} @ ${HOSTNAME_VAL}" \
  -H "Tags: test_tube" \
  -H "Priority: 3" \
  -H "Markdown: yes" \
  -d "This is a test notification from **claude-ntfy**. If you see this, your setup is working!" \
  "${NTFY_SERVER_URL}/${NTFY_TOPIC}" 2>/dev/null || echo -e "\n000")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

case "$HTTP_CODE" in
  200)
    ok "OK (HTTP 200)"
    echo ""
    ok "Test notification sent successfully!"
    echo "Check your ntfy client for the message."
    ;;
  401|403)
    fail "FAIL (HTTP $HTTP_CODE)"
    echo "Authentication failed. Check your NTFY_TOKEN."
    exit 1
    ;;
  404)
    fail "FAIL (HTTP $HTTP_CODE)"
    printf 'Topic not found. Check your topic name: %s\n' "$NTFY_TOPIC"
    exit 1
    ;;
  000)
    fail "FAIL (connection error)"
    printf 'Could not connect to %s\n' "$NTFY_SERVER_URL"
    exit 1
    ;;
  *)
    fail "FAIL (HTTP $HTTP_CODE)"
    echo "Response: $BODY"
    exit 1
    ;;
esac
