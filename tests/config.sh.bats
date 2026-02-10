#!/usr/bin/env bats
# Tests for hooks/lib/config.sh configuration loading

# Setup test environment
setup() {
  export TEST_TMPDIR="$(mktemp -d)"
  export HOME="$TEST_TMPDIR/home"
  mkdir -p "$HOME"

  # Source the config library
  source "$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)/../hooks/lib/config.sh"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
  unset NTFY_SERVER_URL NTFY_TOPIC NTFY_TOKEN
}

# Test 1: Load valid config file
@test "load_config: Load valid JSON config file" {
  cat > "$HOME/.claude-ntfy.json" << 'EOF'
{
  "server_url": "http://example.com:8080",
  "topic": "test-topic",
  "token": "tk_test123"
}
EOF

  result=$(load_config "$HOME/.claude-ntfy.json")

  [ "$(echo "$result" | jq -r '.server_url')" = "http://example.com:8080" ]
  [ "$(echo "$result" | jq -r '.topic')" = "test-topic" ]
  [ "$(echo "$result" | jq -r '.token')" = "tk_test123" ]
}

# Test 2: Load config with partial fields
@test "load_config: Load config with only required fields" {
  cat > "$HOME/.claude-ntfy.json" << 'EOF'
{
  "topic": "minimal-topic"
}
EOF

  result=$(load_config "$HOME/.claude-ntfy.json")

  [ "$(echo "$result" | jq -r '.topic')" = "minimal-topic" ]
  [ "$(echo "$result" | jq -r '.server_url')" = "null" ]
}

# Test 3: Missing config file returns empty JSON
@test "load_config: Missing file returns empty object" {
  result=$(load_config "$HOME/nonexistent.json")

  [ "$(echo "$result" | jq -r 'keys | length')" = "0" ]
}

# Test 4: Invalid JSON returns error
@test "load_config: Invalid JSON returns error code" {
  cat > "$HOME/bad.json" << 'EOF'
{
  "broken": json syntax
}
EOF

  ! load_config "$HOME/bad.json" > /dev/null 2>&1
}

# Test 5: Find and load user config
@test "resolve_config: Find user config file" {
  cat > "$HOME/.claude-ntfy.json" << 'EOF'
{
  "topic": "user-topic",
  "server_url": "http://user.example.com"
}
EOF

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.topic')" = "user-topic" ]
  [ "$(echo "$result" | jq -r '.server_url')" = "http://user.example.com" ]
}

# Test 6: Project config takes precedence over user config
@test "resolve_config: Project config overrides user config" {
  mkdir -p "$TEST_TMPDIR/project"
  cd "$TEST_TMPDIR/project"

  cat > "$HOME/.claude-ntfy.json" << 'EOF'
{
  "topic": "user-topic",
  "server_url": "http://user.example.com"
}
EOF

  cat > ".claude-ntfy.json" << 'EOF'
{
  "topic": "project-topic"
}
EOF

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.topic')" = "project-topic" ]
}

# Test 7: Environment variables override config files
@test "resolve_config: Environment variables override all configs" {
  mkdir -p "$TEST_TMPDIR/project"
  cd "$TEST_TMPDIR/project"

  cat > "$HOME/.claude-ntfy.json" << 'EOF'
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

# Test 8: Alternative project config location .claude/ntfy.json
@test "resolve_config: Find .claude/ntfy.json alternative location" {
  mkdir -p "$TEST_TMPDIR/project/.claude"
  cd "$TEST_TMPDIR/project"

  cat > ".claude/ntfy.json" << 'EOF'
{
  "topic": "claude-dir-topic",
  "server_url": "http://claude-dir.example.com"
}
EOF

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.topic')" = "claude-dir-topic" ]
}

# Test 9: .claude-ntfy.json preferred over .claude/ntfy.json
@test "resolve_config: Prefer .claude-ntfy.json over .claude/ntfy.json" {
  mkdir -p "$TEST_TMPDIR/project/.claude"
  cd "$TEST_TMPDIR/project"

  cat > ".claude-ntfy.json" << 'EOF'
{
  "topic": "root-topic"
}
EOF

  cat > ".claude/ntfy.json" << 'EOF'
{
  "topic": "claude-dir-topic"
}
EOF

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.topic')" = "root-topic" ]
}

# Test 10: Default server_url when not in config
@test "resolve_config: Use default server_url" {
  mkdir -p "$TEST_TMPDIR/project"
  cd "$TEST_TMPDIR/project"

  cat > ".claude-ntfy.json" << 'EOF'
{
  "topic": "test-topic"
}
EOF

  result=$(resolve_config)

  [ "$(echo "$result" | jq -r '.server_url')" = "http://localhost:8080" ]
}

# Test 11: Merge precedence - env vars > project > user > defaults
@test "resolve_config: Complete precedence chain" {
  mkdir -p "$TEST_TMPDIR/project"
  cd "$TEST_TMPDIR/project"

  cat > "$HOME/.claude-ntfy.json" << 'EOF'
{
  "server_url": "http://user.example.com",
  "topic": "user-topic",
  "token": "tk_user"
}
EOF

  cat > ".claude-ntfy.json" << 'EOF'
{
  "server_url": "http://project.example.com"
}
EOF

  export NTFY_TOKEN="tk_env"

  result=$(resolve_config)

  # topic from user config (project doesn't override)
  [ "$(echo "$result" | jq -r '.topic')" = "user-topic" ]
  # server_url from project config (overrides user)
  [ "$(echo "$result" | jq -r '.server_url')" = "http://project.example.com" ]
  # token from env var (overrides all configs)
  [ "$(echo "$result" | jq -r '.token')" = "tk_env" ]
}

# Test 12: Validate config - require topic
@test "validate_config: Require topic field" {
  config='{"server_url": "http://example.com"}'

  ! validate_config "$config" > /dev/null 2>&1
}

# Test 13: Validate config - topic present
@test "validate_config: Accept config with topic" {
  config='{"topic": "test-topic"}'

  validate_config "$config" > /dev/null 2>&1
}

# Test 14: Empty topic string is invalid
@test "validate_config: Reject empty topic" {
  config='{"topic": ""}'

  ! validate_config "$config" > /dev/null 2>&1
}

# Test 15: Merge two configs with correct precedence
@test "merge_configs: Merge user and project configs" {
  user_config='{"server_url": "http://user.example.com", "topic": "user-topic", "token": "tk_user"}'
  project_config='{"server_url": "http://project.example.com"}'

  result=$(merge_configs "$user_config" "$project_config")

  # Project overrides user for server_url
  [ "$(echo "$result" | jq -r '.server_url')" = "http://project.example.com" ]
  # User topic preserved when project doesn't override
  [ "$(echo "$result" | jq -r '.topic')" = "user-topic" ]
  # User token preserved
  [ "$(echo "$result" | jq -r '.token')" = "tk_user" ]
}

# Test 16: Merge with environment variables
@test "merge_configs: Apply environment variable overrides" {
  base_config='{"server_url": "http://example.com", "topic": "config-topic", "token": "tk_config"}'

  export NTFY_TOPIC="env-topic"

  result=$(merge_configs "$base_config" "" "true")  # true = apply env vars

  [ "$(echo "$result" | jq -r '.topic')" = "env-topic" ]
  [ "$(echo "$result" | jq -r '.server_url')" = "http://example.com" ]
  [ "$(echo "$result" | jq -r '.token')" = "tk_config" ]
}
