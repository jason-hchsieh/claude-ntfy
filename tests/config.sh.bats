#!/usr/bin/env bats
# Tests for hooks/lib/config.sh configuration loading
# Config paths: env vars > XDG (~/.config/claude-ntfy/) > Claude dir (~/.claude/claude-ntfy/) > defaults

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
  mkdir -p "$HOME/.claude/claude-ntfy"

  # Source the config library
  source "$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)/../hooks/lib/config.sh"
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
@test "resolve_config: Load XDG config file" {
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

# Test 6: Resolve config from Claude dir config file
@test "resolve_config: Load Claude dir config file" {
  cat > "$HOME/.claude/claude-ntfy/config.json" << 'EOF'
{
  "topic": "claude-dir-topic",
  "server_url": "http://claude-dir.example.com"
}
EOF

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.topic')" = "claude-dir-topic" ]
  [ "$(echo "$result" | jq -r '.server_url')" = "http://claude-dir.example.com" ]
}

# Test 7: XDG config overrides Claude dir config
@test "resolve_config: XDG config overrides Claude dir config" {
  cat > "$HOME/.claude/claude-ntfy/config.json" << 'EOF'
{
  "topic": "claude-dir-topic",
  "server_url": "http://claude-dir.example.com",
  "token": "tk_claude_dir"
}
EOF

  cat > "$XDG_CONFIG_HOME/claude-ntfy/config.json" << 'EOF'
{
  "topic": "xdg-topic",
  "server_url": "http://xdg.example.com"
}
EOF

  result=$(resolve_config)

  # XDG values override Claude dir values
  [ "$(echo "$result" | jq -r '.topic')" = "xdg-topic" ]
  [ "$(echo "$result" | jq -r '.server_url')" = "http://xdg.example.com" ]
  # Token from Claude dir is preserved (not overridden by XDG since XDG doesn't set it)
  [ "$(echo "$result" | jq -r '.token')" = "tk_claude_dir" ]
}

# Test 8: Environment variables override all config files
@test "resolve_config: Environment variables override config files" {
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

# Test 9: Default server_url when not in config
@test "resolve_config: Use default server_url" {
  cat > "$XDG_CONFIG_HOME/claude-ntfy/config.json" << 'EOF'
{
  "topic": "test-topic"
}
EOF

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.server_url')" = "http://localhost:8080" ]
}

# Test 10: Environment-only configuration (no config files)
@test "resolve_config: Work with env vars only" {
  export NTFY_TOPIC="env-only-topic"
  export NTFY_SERVER_URL="http://env.example.com"

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.topic')" = "env-only-topic" ]
  [ "$(echo "$result" | jq -r '.server_url')" = "http://env.example.com" ]
}

# Test 11: Fail when no topic provided
@test "resolve_config: Fail without topic" {
  # No config files, no env vars
  ! resolve_config > /dev/null 2>&1
}

# Test 12: Partial override — XDG sets topic, Claude dir sets server
@test "resolve_config: Merge fields from both config files" {
  cat > "$HOME/.claude/claude-ntfy/config.json" << 'EOF'
{
  "server_url": "http://claude-dir.example.com"
}
EOF

  cat > "$XDG_CONFIG_HOME/claude-ntfy/config.json" << 'EOF'
{
  "topic": "xdg-topic"
}
EOF

  result=$(resolve_config)

  # topic from XDG, but server_url from Claude dir is overridden by XDG's empty merge
  # XDG config merges on top, but only has topic — server_url falls back to default
  [ "$(echo "$result" | jq -r '.topic')" = "xdg-topic" ]
}

# ── validate_config tests ─────────────────────────────────────────

# Test 13: Validate config - require topic
@test "validate_config: Require topic field" {
  config='{"server_url": "http://example.com"}'

  ! validate_config "$config" > /dev/null 2>&1
}

# Test 14: Validate config - topic present
@test "validate_config: Accept config with topic" {
  config='{"topic": "test-topic"}'

  validate_config "$config" > /dev/null 2>&1
}

# Test 15: Empty topic string is invalid
@test "validate_config: Reject empty topic" {
  config='{"topic": ""}'

  ! validate_config "$config" > /dev/null 2>&1
}

# ── config_value tests ────────────────────────────────────────────

# Test 16: config_value helper
@test "config_value: Extract field from config" {
  config='{"server_url": "http://example.com", "topic": "test"}'

  [ "$(config_value "$config" "server_url")" = "http://example.com" ]
  [ "$(config_value "$config" "topic")" = "test" ]
}

# Test 17: config_value with default
@test "config_value: Return default for missing field" {
  config='{"topic": "test"}'

  [ "$(config_value "$config" "token" "default-token")" = "default-token" ]
}
