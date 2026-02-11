#!/usr/bin/env bats
# Tests for hooks/lib/config.sh configuration loading

# Setup test environment
setup() {
  export TEST_TMPDIR="$(mktemp -d)"
  export CLAUDE_PLUGIN_ROOT="$TEST_TMPDIR/plugin"
  mkdir -p "$CLAUDE_PLUGIN_ROOT"

  # Source the config library
  source "$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)/../hooks/lib/config.sh"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
  unset NTFY_SERVER_URL NTFY_TOPIC NTFY_TOKEN CLAUDE_PLUGIN_ROOT
}

# Test 1: Load valid config file
@test "load_config: Load valid JSON config file" {
  cat > "$CLAUDE_PLUGIN_ROOT/config.json" << 'EOF'
{
  "server_url": "http://example.com:8080",
  "topic": "test-topic",
  "token": "tk_test123"
}
EOF

  result=$(load_config "$CLAUDE_PLUGIN_ROOT/config.json")

  [ "$(echo "$result" | jq -r '.server_url')" = "http://example.com:8080" ]
  [ "$(echo "$result" | jq -r '.topic')" = "test-topic" ]
  [ "$(echo "$result" | jq -r '.token')" = "tk_test123" ]
}

# Test 2: Load config with partial fields
@test "load_config: Load config with only required fields" {
  cat > "$CLAUDE_PLUGIN_ROOT/config.json" << 'EOF'
{
  "topic": "minimal-topic"
}
EOF

  result=$(load_config "$CLAUDE_PLUGIN_ROOT/config.json")

  [ "$(echo "$result" | jq -r '.topic')" = "minimal-topic" ]
  [ "$(echo "$result" | jq -r '.server_url')" = "null" ]
}

# Test 3: Missing config file returns empty JSON
@test "load_config: Missing file returns empty object" {
  result=$(load_config "$CLAUDE_PLUGIN_ROOT/nonexistent.json")

  [ "$(echo "$result" | jq -r 'keys | length')" = "0" ]
}

# Test 4: Invalid JSON returns error
@test "load_config: Invalid JSON returns error code" {
  cat > "$CLAUDE_PLUGIN_ROOT/bad.json" << 'EOF'
{
  "broken": json syntax
}
EOF

  ! load_config "$CLAUDE_PLUGIN_ROOT/bad.json" > /dev/null 2>&1
}

# Test 5: Resolve config from plugin config file
@test "resolve_config: Load plugin config file" {
  cat > "$CLAUDE_PLUGIN_ROOT/config.json" << 'EOF'
{
  "topic": "plugin-topic",
  "server_url": "http://plugin.example.com"
}
EOF

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.topic')" = "plugin-topic" ]
  [ "$(echo "$result" | jq -r '.server_url')" = "http://plugin.example.com" ]
}

# Test 6: Environment variables override plugin config
@test "resolve_config: Environment variables override plugin config" {
  cat > "$CLAUDE_PLUGIN_ROOT/config.json" << 'EOF'
{
  "topic": "config-topic",
  "server_url": "http://config.example.com",
  "token": "tk_config"
}
EOF

  export NTFY_TOPIC="env-topic"
  export NTFY_TOKEN="tk_env"

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.topic')" = "env-topic" ]
  [ "$(echo "$result" | jq -r '.token')" = "tk_env" ]
  [ "$(echo "$result" | jq -r '.server_url')" = "http://config.example.com" ]
}

# Test 7: Default server_url when not in config
@test "resolve_config: Use default server_url" {
  cat > "$CLAUDE_PLUGIN_ROOT/config.json" << 'EOF'
{
  "topic": "test-topic"
}
EOF

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.server_url')" = "http://localhost:8080" ]
}

# Test 8: Environment-only configuration (no config file)
@test "resolve_config: Work with env vars only" {
  export NTFY_TOPIC="env-only-topic"
  export NTFY_SERVER_URL="http://env.example.com"

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.topic')" = "env-only-topic" ]
  [ "$(echo "$result" | jq -r '.server_url')" = "http://env.example.com" ]
}

# Test 9: Fail when no topic provided
@test "resolve_config: Fail without topic" {
  # No config file, no env vars
  ! resolve_config > /dev/null 2>&1
}

# Test 10: Missing CLAUDE_PLUGIN_ROOT falls back to env/defaults
@test "resolve_config: Work without CLAUDE_PLUGIN_ROOT" {
  unset CLAUDE_PLUGIN_ROOT
  export NTFY_TOPIC="fallback-topic"

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.topic')" = "fallback-topic" ]
  [ "$(echo "$result" | jq -r '.server_url')" = "http://localhost:8080" ]
}

# Test 11: Validate config - require topic
@test "validate_config: Require topic field" {
  config='{"server_url": "http://example.com"}'

  ! validate_config "$config" > /dev/null 2>&1
}

# Test 12: Validate config - topic present
@test "validate_config: Accept config with topic" {
  config='{"topic": "test-topic"}'

  validate_config "$config" > /dev/null 2>&1
}

# Test 13: Empty topic string is invalid
@test "validate_config: Reject empty topic" {
  config='{"topic": ""}'

  ! validate_config "$config" > /dev/null 2>&1
}

# Test 14: config_value helper
@test "config_value: Extract field from config" {
  config='{"server_url": "http://example.com", "topic": "test"}'

  [ "$(config_value "$config" "server_url")" = "http://example.com" ]
  [ "$(config_value "$config" "topic")" = "test" ]
}

# Test 15: config_value with default
@test "config_value: Return default for missing field" {
  config='{"topic": "test"}'

  [ "$(config_value "$config" "token" "default-token")" = "default-token" ]
}
