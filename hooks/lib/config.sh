#!/usr/bin/env bash
# Configuration loading and merging for claude-ntfy
# Supports JSON config files with environment variable overrides

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

# Merge two JSON objects with override precedence
_merge_json_objects() {
  local base="$1"
  local override="$2"

  printf '%s\n%s\n' "$base" "$override" | jq -cs '[.[0], .[1]] | .[0] * .[1]'
}

# Merge two JSON config objects (right overwrites left)
# merge_configs <base_config_json> <override_config_json> [apply_env_vars]
merge_configs() {
  local base="${1:-'{}'}"
  local override="${2:-'{}'}"
  local apply_env="${3:-false}"

  if [[ -z "$override" ]]; then
    override='{}'
  fi

  local merged
  merged=$(_merge_json_objects "$base" "$override")

  if [[ "$apply_env" == "true" ]]; then
    if [[ -n "${NTFY_SERVER_URL:-}" ]]; then
      merged=$(printf '%s' "$merged" | jq --arg url "$NTFY_SERVER_URL" '.server_url = $url')
    fi
    if [[ -n "${NTFY_TOPIC:-}" ]]; then
      merged=$(printf '%s' "$merged" | jq --arg topic "$NTFY_TOPIC" '.topic = $topic')
    fi
    if [[ -n "${NTFY_TOKEN:-}" ]]; then
      merged=$(printf '%s' "$merged" | jq --arg token "$NTFY_TOKEN" '.token = $token')
    fi
  fi

  echo "$merged"
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
# Precedence: env vars > project config > user config > defaults
resolve_config() {
  local user_config='{}'
  local project_config='{}'
  local final_config

  if [[ -f "$HOME/.claude-ntfy.json" ]]; then
    user_config=$(load_config "$HOME/.claude-ntfy.json") || return 1
  fi

  if [[ -f "./.claude-ntfy.json" ]]; then
    project_config=$(load_config "./.claude-ntfy.json") || return 1
  elif [[ -f "./.claude/ntfy.json" ]]; then
    project_config=$(load_config "./.claude/ntfy.json") || return 1
  fi

  final_config=$(merge_configs "$user_config" "$project_config" "true")

  final_config=$(printf '%s' "$final_config" | jq -c '.server_url //= "http://localhost:8080"')

  validate_config "$final_config" || return 1

  echo "$final_config"
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
