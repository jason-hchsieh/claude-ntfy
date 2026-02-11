#!/usr/bin/env bash
# Configuration loading for claude-ntfy
# Supports: environment variables > user config ($XDG_CONFIG_HOME/claude-ntfy/config.json) > defaults

set -euo pipefail

# XDG Base Directory spec: https://specifications.freedesktop.org/basedir-spec/latest/
CLAUDE_NTFY_CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/claude-ntfy"
CLAUDE_NTFY_CONFIG_FILE="${CLAUDE_NTFY_CONFIG_DIR}/config.json"

# Load a single config file
# Returns JSON object (empty if file missing)
# Returns error if JSON is invalid
load_config() {
  local config_file="$1"

  if [[ ! -f "$config_file" ]]; then
    echo '{}'
    return 0
  fi

  if ! jq empty "$config_file" 2>/dev/null; then
    echo "Error: Invalid JSON in $config_file" >&2
    return 1
  fi

  jq -c '.' "$config_file"
}

# Validate config has required fields
validate_config() {
  local config="$1"

  local topic
  topic=$(printf '%s' "$config" | jq -r '.topic // empty')

  if [[ -z "$topic" ]]; then
    echo "Error: Configuration missing required field: topic" >&2
    return 1
  fi

  return 0
}

# Resolve complete configuration from all sources
# Precedence: env vars > user config ($XDG_CONFIG_HOME/claude-ntfy/config.json) > defaults
resolve_config() {
  local config='{}'

  # Load user config (XDG compliant, stable across plugin updates)
  config=$(load_config "$CLAUDE_NTFY_CONFIG_FILE") || return 1

  # Apply environment variable overrides (highest priority)
  if [[ -n "${NTFY_SERVER_URL:-}" ]]; then
    config=$(printf '%s' "$config" | jq --arg url "$NTFY_SERVER_URL" '.server_url = $url')
  fi
  if [[ -n "${NTFY_TOPIC:-}" ]]; then
    config=$(printf '%s' "$config" | jq --arg topic "$NTFY_TOPIC" '.topic = $topic')
  fi
  if [[ -n "${NTFY_TOKEN:-}" ]]; then
    config=$(printf '%s' "$config" | jq --arg token "$NTFY_TOKEN" '.token = $token')
  fi

  # Apply defaults for missing values
  config=$(printf '%s' "$config" | jq -c '.server_url //= "http://localhost:8080"')

  validate_config "$config" || return 1

  echo "$config"
}

# Get a config value with optional default
config_value() {
  local config="$1"
  local field="$2"
  local default="${3:-}"

  local value
  value=$(printf '%s' "$config" | jq -r ".$field // empty")

  if [[ -z "$value" ]]; then
    echo "$default"
  else
    echo "$value"
  fi
}
