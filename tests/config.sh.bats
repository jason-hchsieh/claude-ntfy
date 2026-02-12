#!/usr/bin/env bats
# Tests for scripts/config.sh configuration loading
# Config paths: env vars > XDG (~/.config/claude-ntfy/) > defaults

# Setup test environment
setup() {
  export TEST_TMPDIR="$(mktemp -d)"

  # Override HOME so tests use temp directories for config files
  export REAL_HOME="$HOME"
  export HOME="$TEST_TMPDIR/home"
  mkdir -p "$HOME"

  # Override XDG_CONFIG_HOME to use temp directory
  export XDG_CONFIG_HOME="$TEST_TMPDIR/xdg-config"
  mkdir -p "$XDG_CONFIG_HOME/claude-ntfy"

  # Source the config library
  source "$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)/../scripts/config.sh"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
  export HOME="$REAL_HOME"
  unset NTFY_SERVER_URL NTFY_TOPIC NTFY_TOKEN XDG_CONFIG_HOME REAL_HOME TEST_TMPDIR
}

# ── load_config tests ─────────────────────────────────────────────

# Test 1: Load valid config file
@test "load_config: Load valid JSON config file" {
  cat > "$TEST_TMPDIR/config.json" << 'EOF'
{
  "server_url": "http://example.com:8080",
  "topic": "test-topic",
  "token": "tk_test123"
}
EOF

  result=$(load_config "$TEST_TMPDIR/config.json")

  [ "$(echo "$result" | jq -r '.server_url')" = "http://example.com:8080" ]
  [ "$(echo "$result" | jq -r '.topic')" = "test-topic" ]
  [ "$(echo "$result" | jq -r '.token')" = "tk_test123" ]
}

# Test 2: Load config with partial fields
@test "load_config: Load config with only required fields" {
  cat > "$TEST_TMPDIR/config.json" << 'EOF'
{
  "topic": "minimal-topic"
}
EOF

  result=$(load_config "$TEST_TMPDIR/config.json")

  [ "$(echo "$result" | jq -r '.topic')" = "minimal-topic" ]
  [ "$(echo "$result" | jq -r '.server_url')" = "null" ]
}

# Test 3: Missing config file returns empty JSON
@test "load_config: Missing file returns empty object" {
  result=$(load_config "$TEST_TMPDIR/nonexistent.json")

  [ "$(echo "$result" | jq -r 'keys | length')" = "0" ]
}

# Test 4: Invalid JSON returns error
@test "load_config: Invalid JSON returns error code" {
  cat > "$TEST_TMPDIR/bad.json" << 'EOF'
{
  "broken": json syntax
}
EOF

  ! load_config "$TEST_TMPDIR/bad.json" > /dev/null 2>&1
}

# ── resolve_config tests ──────────────────────────────────────────

# Test 5: Resolve config from XDG config file
@test "resolve_config: Load config file" {
  cat > "$XDG_CONFIG_HOME/claude-ntfy/config.json" << 'EOF'
{
  "topic": "xdg-topic",
  "server_url": "http://xdg.example.com"
}
EOF

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.topic')" = "xdg-topic" ]
  [ "$(echo "$result" | jq -r '.server_url')" = "http://xdg.example.com" ]
}

# Test 6: Environment variables override config file
@test "resolve_config: Environment variables override config file" {
  cat > "$XDG_CONFIG_HOME/claude-ntfy/config.json" << 'EOF'
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
  # server_url comes from config file (not overridden by env)
  [ "$(echo "$result" | jq -r '.server_url')" = "http://config.example.com" ]
}

# Test 7: Default server_url when not in config
@test "resolve_config: Use default server_url" {
  cat > "$XDG_CONFIG_HOME/claude-ntfy/config.json" << 'EOF'
{
  "topic": "test-topic"
}
EOF

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.server_url')" = "http://localhost:8080" ]
}

# Test 8: Environment-only configuration (no config files)
@test "resolve_config: Work with env vars only" {
  export NTFY_TOPIC="env-only-topic"
  export NTFY_SERVER_URL="http://env.example.com"

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.topic')" = "env-only-topic" ]
  [ "$(echo "$result" | jq -r '.server_url')" = "http://env.example.com" ]
}

# Test 9: Fail when no topic provided
@test "resolve_config: Fail without topic" {
  # No config files, no env vars
  ! resolve_config > /dev/null 2>&1
}

# Test 10: Config file with all fields
@test "resolve_config: Load config with all fields" {
  cat > "$XDG_CONFIG_HOME/claude-ntfy/config.json" << 'EOF'
{
  "server_url": "https://ntfy.example.com",
  "topic": "full-topic",
  "token": "tk_full123"
}
EOF

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.server_url')" = "https://ntfy.example.com" ]
  [ "$(echo "$result" | jq -r '.topic')" = "full-topic" ]
  [ "$(echo "$result" | jq -r '.token')" = "tk_full123" ]
}

# ── validate_config tests ─────────────────────────────────────────

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

# ── config_value tests ────────────────────────────────────────────

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

# ── set_config_vars tests ────────────────────────────────────────

# Test 16: set_config_vars sets all variables
@test "set_config_vars: Set all variables from config" {
  config='{"server_url": "http://example.com", "topic": "test-topic", "token": "tk_123"}'

  set_config_vars "$config"

  [ "$NTFY_SERVER_URL" = "http://example.com" ]
  [ "$NTFY_TOPIC" = "test-topic" ]
  [ "$NTFY_TOKEN" = "tk_123" ]
}

# Test 17: set_config_vars with missing token
@test "set_config_vars: Empty token when not in config" {
  config='{"server_url": "http://example.com", "topic": "test-topic"}'

  set_config_vars "$config"

  [ "$NTFY_SERVER_URL" = "http://example.com" ]
  [ "$NTFY_TOPIC" = "test-topic" ]
  [ -z "$NTFY_TOKEN" ]
}

# ── build_auth_headers tests ─────────────────────────────────────

# Test 18: build_auth_headers with token
@test "build_auth_headers: Set headers when token present" {
  NTFY_TOKEN="tk_test"

  build_auth_headers

  [ "${#NTFY_HEADERS[@]}" = "2" ]
  [ "${NTFY_HEADERS[0]}" = "-H" ]
  [ "${NTFY_HEADERS[1]}" = "Authorization: Bearer tk_test" ]
}

# Test 19: build_auth_headers without token
@test "build_auth_headers: Empty headers when no token" {
  NTFY_TOKEN=""

  build_auth_headers

  [ "${#NTFY_HEADERS[@]}" = "0" ]
}

# Test 20: build_auth_headers with explicit token argument
@test "build_auth_headers: Use explicit token argument" {
  NTFY_TOKEN=""

  build_auth_headers "tk_explicit"

  [ "${#NTFY_HEADERS[@]}" = "2" ]
  [ "${NTFY_HEADERS[1]}" = "Authorization: Bearer tk_explicit" ]
}
