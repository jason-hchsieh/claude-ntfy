# Solution: Configuration Precedence Pattern in Bash

## Problem

Building a configuration system that merges multiple sources (env vars, config files, defaults) while maintaining clear precedence rules.

## Solution: Layered Configuration Loading

Implement a precedence chain where each layer overrides the previous:

1. **Base Layer**: Defaults (hardcoded)
2. **User Layer**: User home directory config
3. **Project Layer**: Project-specific config
4. **Override Layer**: Environment variables

## Implementation Pattern

```bash
# Load base defaults
config='{"server_url":"http://localhost:8080"}'

# Load and merge user config if exists
if [[ -f "$HOME/.config-file.json" ]]; then
  user_config=$(load_config "$HOME/.config-file.json")
  config=$(merge_configs "$config" "$user_config")
fi

# Load and merge project config if exists
if [[ -f "./.config-file.json" ]]; then
  project_config=$(load_config "./.config-file.json")
  config=$(merge_configs "$config" "$project_config")
fi

# Apply environment variable overrides
config=$(apply_env_overrides "$config")
```

## Key Components

### 1. load_config Function
```bash
load_config() {
  local file="$1"
  [[ ! -f "$file" ]] && echo '{}' && return 0
  jq -c '.' "$file"
}
```

**Features:**
- Returns empty object for missing files (not an error)
- Validates JSON syntax
- Returns compact JSON

### 2. merge_configs Function
```bash
merge_configs() {
  local base="$1"
  local override="$2"
  printf '%s\n%s\n' "$base" "$override" | \
    jq -cs '.[0] * .[1]'
}
```

**Features:**
- Right side (override) takes precedence
- Preserves fields from base if not in override
- Safe handling of special characters

### 3. validate_config Function
```bash
validate_config() {
  local config="$1"
  local topic=$(echo "$config" | jq -r '.topic // empty')
  [[ -z "$topic" ]] && echo "Error: topic required" >&2 && return 1
}
```

**Features:**
- Checks for required fields
- Clear error messages
- Simple and composable

## Configuration File Locations

```
~/.claude-ntfy.json          # User level (lowest priority)
./.claude-ntfy.json          # Project level
./.claude/ntfy.json          # Alternative project location
NTFY_* env vars              # Highest priority
```

## Search Algorithm

```bash
resolve_config() {
  local config='{}'

  # Check each location in reverse priority order
  [[ -f "$HOME/.claude-ntfy.json" ]] && \
    config=$(merge_configs "$config" "$(load_config ...)")

  [[ -f "./.claude-ntfy.json" ]] && \
    config=$(merge_configs "$config" "$(load_config ...)")

  # Apply env var overrides (highest priority)
  config=$(apply_env_overrides "$config")

  # Validate and return
  validate_config "$config" && echo "$config"
}
```

## Environment Variable Override Pattern

```bash
apply_env_overrides() {
  local config="$1"

  # Only override if env var is set
  [[ -n "${NTFY_TOPIC:-}" ]] && \
    config=$(echo "$config" | jq --arg t "$NTFY_TOPIC" '.topic = $t')

  [[ -n "${NTFY_SERVER_URL:-}" ]] && \
    config=$(echo "$config" | jq --arg s "$NTFY_SERVER_URL" '.server_url = $s')

  echo "$config"
}
```

**Pattern:**
- Check `${VAR:-}` to avoid unset errors
- Only apply if set (preserve config values for unset vars)
- Each field is independent

## Advantages

1. **Clear Precedence**: Easy to understand what overrides what
2. **Composable**: Each function is independent
3. **Testable**: Can test each layer separately
4. **Extensible**: Easy to add new sources (CLI flags, vault, etc.)
5. **Safe**: Validates configuration at end
6. **Backward Compatible**: Environment variables still work

## Usage Examples

### Example 1: Config File Only
```bash
~/.claude-ntfy.json:
{
  "server_url": "http://ntfy.example.com",
  "topic": "my-topic"
}
```
Result: Uses config file values

### Example 2: Partial Config + Defaults
```bash
./.claude-ntfy.json:
{
  "topic": "project-topic"
}
```
Result: Uses project topic, default server URL

### Example 3: Override with Env Var
```bash
./.claude-ntfy.json:
{
  "server_url": "http://config.com",
  "topic": "config-topic"
}

NTFY_TOPIC=env-topic bash script.sh
```
Result: server_url from config, topic from env var

## Testing Strategy

```bash
# Test each layer
test_load_config()
test_merge_precedence()
test_env_override()
test_missing_required()
test_defaults_applied()
```

## When to Use

- ✓ Any multi-source configuration system
- ✓ CLI tools with env var support
- ✓ Plugins or extensions
- ✓ Development tools with local overrides
- ✗ Real-time configuration (no hot reload)
- ✗ Large distributed config systems (use dedicated tools)

## Variations

### Variation 1: CLI Arguments (Highest Priority)
```bash
while [[ $# -gt 0 ]]; do
  case "$1" in
    --topic) TOPIC="$2"; shift 2 ;;
  esac
done
```

### Variation 2: Multiple Config Directories
```bash
for dir in /etc/app ~/.config/app ./.config; do
  [[ -f "$dir/config.json" ]] && load_config "$dir/config.json"
done
```

### Variation 3: Config Format Detection
```bash
case "${config_file##*.}" in
  json) jq '.' "$file" ;;
  yaml) yq '.' "$file" ;;
  toml) toml-parser "$file" ;;
esac
```
