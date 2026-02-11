#!/usr/bin/env bash
# Configuration loading for claude-ntfy
# Supports: environment variables > plugin config file > defaults

set -euo pipefail

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
# Precedence: env vars > plugin config ($CLAUDE_PLUGIN_ROOT/config.json) > user config > defaults
resolve_config() {
  local config='{}'

  # Load user config (stable across plugin version updates)
  if [[ -f "${HOME}/.config/claude-ntfy/config.json" ]]; then
    config=$(load_config "${HOME}/.config/claude-ntfy/config.json") || return 1
  fi

  # Load plugin config if available (overrides user config)
  if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" && -f "${CLAUDE_PLUGIN_ROOT}/config.json" ]]; then
    local plugin_config
    plugin_config=$(load_config "${CLAUDE_PLUGIN_ROOT}/config.json") || return 1
    config=$(printf '%s\n%s\n' "$config" "$plugin_config" | jq -cs '.[0] * .[1]')
  fi

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
