# Solution: Integration Testing for Bash Scripts with JSON

## Problem

Testing bash scripts that:
- Parse JSON with jq
- Merge configuration objects
- Handle file I/O
- Work in different environments

## Solution: Multi-Layer Testing Approach

### Layer 1: Inline Function Tests (BATS Compatible)

Test functions directly without external dependencies:

```bash
bash << 'EOF'
source hooks/lib/config.sh

# Test 1: load_config
result=$(load_config "nonexistent.json")
[[ "$result" == "{}" ]] && echo "✓ Missing file" || echo "✗ Failed"

# Test 2: validate_config
! validate_config '{}' >/dev/null 2>&1 && echo "✓ Validation" || echo "✗ Failed"

# Test 3: merge_configs
merged=$(merge_configs '{"a":"1"}' '{"b":"2"}')
[[ "$(echo "$merged" | jq -r '.a')" == "1" ]] && echo "✓ Merge" || echo "✗ Failed"
EOF
```

**Advantages:**
- No external test framework needed
- Tests run in subprocess (clean environment)
- Easy to add new tests
- Output is human-readable

**Disadvantages:**
- Limited error messages
- No setup/teardown
- Harder to organize large test suites

### Layer 2: Temporary Directory Fixtures

For file-based tests:

```bash
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Create test config
cat > "$TEST_DIR/config.json" << 'EOF'
{
  "server_url": "http://example.com",
  "topic": "test"
}
EOF

# Test loading from temp file
result=$(load_config "$TEST_DIR/config.json")
[[ "$(echo "$result" | jq -r '.topic')" == "test" ]] && echo "✓ File load"
```

**Key Pattern:**
- Create temp directory
- Set trap for cleanup (runs on exit)
- Test with actual files
- Clean up automatically

### Layer 3: Environment Isolation

For testing configuration precedence:

```bash
bash << 'EOF'
source hooks/lib/config.sh

# Create isolated test environment
export HOME="/tmp/test_home"
mkdir -p "$HOME"
cd /tmp/test_project

# Create user config
cat > "$HOME/.claude-ntfy.json" << 'EOF2'
{"topic": "user-topic", "server_url": "http://user.com"}
EOF2

# Create project config
cat > "./.claude-ntfy.json" << 'EOF2'
{"server_url": "http://project.com"}
EOF2

# Test precedence
result=$(resolve_config)
project_server=$(echo "$result" | jq -r '.server_url')
[[ "$project_server" == "http://project.com" ]] && echo "✓ Precedence"
EOF
```

**Key Points:**
- Use subshell with `bash << 'EOF'`
- Override HOME for isolation
- Each test gets clean environment
- No side effects on actual system

## Testing Pattern Reference

### Test Pattern 1: Load and Validate
```bash
test_load_and_validate() {
  local result=$(load_config "$test_file")
  [[ $? -eq 0 ]] && echo "✓ Loaded" || return 1
  validate_config "$result" && echo "✓ Valid" || return 1
}
```

### Test Pattern 2: Merge Precedence
```bash
test_merge() {
  local merged=$(merge_configs '{"a":"1","b":"2"}' '{"b":"3"}')
  [[ "$(echo "$merged" | jq -r '.a')" == "1" ]] || return 1
  [[ "$(echo "$merged" | jq -r '.b')" == "3" ]] || return 1
  echo "✓ Merge correct"
}
```

### Test Pattern 3: Environment Override
```bash
test_env_override() {
  export NTFY_TOPIC="override"
  local result=$(merge_configs '{"topic":"original"}' '{}' "true")
  [[ "$(echo "$result" | jq -r '.topic')" == "override" ]] && echo "✓ Override"
  unset NTFY_TOPIC
}
```

### Test Pattern 4: Error Cases
```bash
test_error_handling() {
  ! load_config "bad.json" >/dev/null 2>&1 && echo "✓ Error detected" || return 1
  ! validate_config '{}' >/dev/null 2>&1 && echo "✓ Validation failed" || return 1
}
```

## Test Execution Strategy

### Option 1: Inline Testing (Fastest)
```bash
# Run tests in current shell
bash << 'TESTS'
source hooks/lib/config.sh
# Run all tests
TESTS
```

### Option 2: Subprocess Testing (Isolated)
```bash
# Each test in separate subshell for isolation
for test in test_*; do
  bash -c "source hooks/lib/config.sh; $test" && echo "✓ $test" || echo "✗ $test"
done
```

### Option 3: BATS Framework (Comprehensive)
```bash
# Use BATS for formal test suite
bats tests/*.bats
```

## Coverage Checklist

- [ ] Happy path: Normal config loading
- [ ] Missing files: Graceful handling
- [ ] Invalid JSON: Error detection
- [ ] Precedence: Correct override order
- [ ] Defaults: Applied when missing
- [ ] Validation: Required fields checked
- [ ] Env vars: Override config correctly
- [ ] Edge cases: Special characters, empty values
- [ ] Error messages: Clear and helpful

## Tips and Tricks

### Tip 1: Debug Output
```bash
set -x  # Enable debug mode
source hooks/lib/config.sh
# Shows all commands as executed
```

### Tip 2: Capture Stderr
```bash
result=$(load_config "bad.json" 2>&1)
[[ "$result" == *"Invalid JSON"* ]] && echo "✓ Error message correct"
```

### Tip 3: Compare JSON
```bash
result=$(resolve_config)
expected='{"topic":"test","server_url":"http://localhost:8080"}'
# Compare as jq objects (ignores formatting)
[[ "$(echo "$result" | jq -S .)" == "$(echo "$expected" | jq -S .)" ]]
```

### Tip 4: Test with Real Config Format
```bash
# Create realistic test configs
cat > "$TEST_DIR/.claude-ntfy.json" << 'EOF'
{
  "server_url": "https://ntfy.example.com",
  "topic": "my-org-alerts",
  "token": "tk_live_abc123xyz"
}
EOF
```

## Automated Testing

Create a test script:

```bash
#!/usr/bin/env bash
# test-config.sh

set -euo pipefail

PASSED=0
FAILED=0

run_test() {
  local name="$1"
  local test="$2"

  if bash -c "$test" >/dev/null 2>&1; then
    echo "✓ $name"
    ((PASSED++))
  else
    echo "✗ $name"
    ((FAILED++))
  fi
}

run_test "Load config" 'source hooks/lib/config.sh; [[ -n "$(load_config)"' ]]
run_test "Validate config" 'source hooks/lib/config.sh; validate_config "{\"topic\":\"t\"}"'

echo "---"
echo "Passed: $PASSED, Failed: $FAILED"
[[ $FAILED -eq 0 ]]
```

## When to Use Each Approach

| Approach | Use When | Avoid When |
|----------|----------|-----------|
| Inline Tests | Quick verification | Many tests, need organization |
| Temp Files | Testing file I/O | No disk I/O needed |
| Environment Isolation | Testing config precedence | Tests are independent |
| BATS | Comprehensive test suite | Just checking if it works |
| Automated Scripts | CI/CD pipeline | Manual testing |
