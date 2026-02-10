#!/usr/bin/env bash
# Detect and display the current claude-ntfy configuration.
# Shows all config sources, their values, and the final resolved config.

set -euo pipefail

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
  BOLD='\033[1m' DIM='\033[2m' GREEN='\033[32m' YELLOW='\033[33m'
  RED='\033[31m' CYAN='\033[36m' RESET='\033[0m'
else
  BOLD='' DIM='' GREEN='' YELLOW='' RED='' CYAN='' RESET=''
fi

header() { printf "\n${BOLD}%s${RESET}\n" "$1"; }
found() { printf "  ${GREEN}%-40s${RESET} %s\n" "$1" "$2"; }
notfound() { printf "  ${DIM}%-40s${RESET} ${DIM}%s${RESET}\n" "$1" "$2"; }
warn() { printf "  ${YELLOW}%-40s${RESET} %s\n" "$1" "$2"; }
err() { printf "  ${RED}%-40s${RESET} %s\n" "$1" "$2"; }

# ── Environment Variables ──────────────────────────────────────────

header "Environment Variables"

if [[ -n "${NTFY_SERVER_URL:-}" ]]; then
  found "NTFY_SERVER_URL" "$NTFY_SERVER_URL"
else
  notfound "NTFY_SERVER_URL" "(not set)"
fi

if [[ -n "${NTFY_TOPIC:-}" ]]; then
  found "NTFY_TOPIC" "$NTFY_TOPIC"
else
  notfound "NTFY_TOPIC" "(not set)"
fi

if [[ -n "${NTFY_TOKEN:-}" ]]; then
  found "NTFY_TOKEN" "(set, hidden)"
else
  notfound "NTFY_TOKEN" "(not set)"
fi

# ── Config Files ───────────────────────────────────────────────────

header "Config Files"

show_config_file() {
  local label="$1" path="$2"

  if [[ -f "$path" ]]; then
    if jq empty "$path" 2>/dev/null; then
      found "$label" "$path"
      # Show fields
      local server topic token
      server=$(jq -r '.server_url // empty' "$path")
      topic=$(jq -r '.topic // empty' "$path")
      token=$(jq -r '.token // empty' "$path")
      [[ -n "$server" ]] && printf "    server_url: %s\n" "$server" || true
      [[ -n "$topic" ]]  && printf "    topic:      %s\n" "$topic" || true
      [[ -n "$token" ]]  && printf "    token:      (set, hidden)\n" || true
    else
      err "$label" "$path (invalid JSON!)"
    fi
  else
    notfound "$label" "$path (not found)"
  fi
}

show_config_file "User config"        "$HOME/.claude-ntfy.json"
show_config_file "Project config"     "./.claude-ntfy.json"
show_config_file "Project alt config" "./.claude/ntfy.json"

# ── Resolved Configuration ─────────────────────────────────────────

header "Resolved Configuration"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_LIB="${SCRIPT_DIR}/../hooks/lib/config.sh"

if [[ -f "$CONFIG_LIB" ]]; then
  source "$CONFIG_LIB"
  if CONFIG=$(resolve_config 2>/dev/null); then
    server=$(printf '%s' "$CONFIG" | jq -r '.server_url')
    topic=$(printf '%s' "$CONFIG" | jq -r '.topic')
    token=$(printf '%s' "$CONFIG" | jq -r '.token // empty')

    found "server_url" "$server"
    found "topic" "$topic"
    if [[ -n "$token" ]]; then
      found "token" "(set, hidden)"
    else
      notfound "token" "(not set)"
    fi
  else
    err "resolve_config" "Failed — is NTFY_TOPIC set in env or config file?"
  fi
else
  warn "config loader" "Not found at $CONFIG_LIB"
  # Fallback: manual resolution
  server="${NTFY_SERVER_URL:-http://localhost:8080}"
  topic="${NTFY_TOPIC:-}"
  token="${NTFY_TOKEN:-}"

  if [[ -z "$topic" ]]; then
    # Try reading from config files
    for f in "./.claude-ntfy.json" "./.claude/ntfy.json" "$HOME/.claude-ntfy.json"; do
      if [[ -f "$f" ]] && jq empty "$f" 2>/dev/null; then
        topic=$(jq -r '.topic // empty' "$f")
        [[ -z "$server" || "$server" == "http://localhost:8080" ]] && server=$(jq -r '.server_url // empty' "$f")
        [[ -z "$token" ]] && token=$(jq -r '.token // empty' "$f")
        [[ -n "$topic" ]] && break
      fi
    done
  fi

  found "server_url" "${server:-http://localhost:8080}"
  if [[ -n "$topic" ]]; then
    found "topic" "$topic"
  else
    err "topic" "(missing — notifications will fail!)"
  fi
  if [[ -n "$token" ]]; then
    found "token" "(set, hidden)"
  else
    notfound "token" "(not set)"
  fi
fi

# ── Server Connectivity ────────────────────────────────────────────

header "Server Connectivity"

RESOLVED_SERVER="${server:-${NTFY_SERVER_URL:-http://localhost:8080}}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "${RESOLVED_SERVER}/v1/health" 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" == "200" ]]; then
  found "$RESOLVED_SERVER" "reachable (HTTP $HTTP_CODE)"
else
  err "$RESOLVED_SERVER" "unreachable (HTTP $HTTP_CODE)"
fi

echo ""
