# Plan: Configuration File Support for claude-ntfy

## Overview

Add JSON configuration file support to claude-ntfy while maintaining full backward compatibility with environment variables.

**Goal:** Users can configure ntfy via:
- `~/.claude-ntfy.json` (global user config)
- `.claude-ntfy.json` or `.claude/ntfy.json` (project config)
- Environment variables (highest priority, existing method)

**Precedence (highest to lowest):**
1. Environment variables (`NTFY_*`)
2. Project config (`.claude-ntfy.json` or `.claude/ntfy.json`)
3. User config (`~/.claude-ntfy.json`)
4. Defaults (server: `http://localhost:8080`)

## Architecture

```
hooks/
  notify.sh              # Updated to use config loader
  lib/
    config.sh            # Config loading & merging logic

docs/
  CONFIG.md              # Configuration documentation

tests/
  config.sh.bats         # BATS tests for config loading
```

## Configuration Schema

```json
{
  "server_url": "http://localhost:8080",
  "topic": "claude-alerts",
  "token": "tk_optional_bearer_token"
}
```

All fields optional except `topic` (can come from env vars).

## Tasks

### Task 1: Create Config Schema & Documentation
**Dependencies:** None | **Parallel:** Yes

- **File:** `docs/CONFIG.md`
- **Covers:**
  - Config file format and schema
  - Search paths and precedence rules
  - Example config files
  - Migration guide from env vars

**No code change required** - Documentation only, establishes contract.

### Task 2: Create config.sh Library
**Dependencies:** Task 1 | **Parallel:** No

- **File:** `hooks/lib/config.sh`
- **Functions:**
  - `load_config()` - Load single config file with validation
  - `merge_configs()` - Merge multiple configs respecting precedence
  - `resolve_config()` - Find and load all config files, return final config
  - `validate_config()` - Ensure required fields present
- **Conventions:**
  - Use `jq` for JSON parsing
  - Use `set -euo pipefail`
  - Return JSON output for easy consumption
  - Graceful errors (missing files OK, invalid JSON is error)

**TDD Strategy:**
- Create `tests/config.sh.bats` first
- Test cases:
  1. Load user config file
  2. Load project config file
  3. Merge precedence (project > user)
  4. Environment variables override config files
  5. Missing required `topic` error
  6. Invalid JSON error
  7. Missing config files (graceful fallback)
  8. Resolve config with multiple sources

### Task 3: Update notify.sh Hook
**Dependencies:** Task 2 | **Parallel:** No

- **File:** `hooks/notify.sh`
- **Changes:**
  - Source `hooks/lib/config.sh`
  - Call `resolve_config()` at start
  - Use resolved config instead of direct env vars
  - Maintain error messages
  - Ensure backward compatibility (env vars still work)

**Testing:**
- Run with various config combinations
- Verify env vars still override configs
- Verify hook still functions with only env vars

### Task 4: Add Syntax & Style Validation
**Dependencies:** Task 3 | **Parallel:** No

- **Verification:**
  - `bash -n hooks/lib/config.sh` (syntax check)
  - `bash -n hooks/notify.sh` (syntax check)
  - `shellcheck hooks/lib/config.sh` (linting)
  - `shellcheck hooks/notify.sh` (linting)

### Task 5: Update CLAUDE.md & README.md
**Dependencies:** Task 3 | **Parallel:** Yes

- **CLAUDE.md:** Add config loading section
- **README.md:**
  - Add "Configuration Files" section
  - Quick start examples with config files
  - Config file format examples
  - Precedence rules
  - Link to `docs/CONFIG.md`

## Dependency Graph

```
Task 1 (docs/schema) ──────┐
                           ├──→ Task 2 (config.sh)
                           │
                           └──→ Task 3 (update notify.sh)
                                    ↓
                                Task 4 (validation)
                                    ↓
                           Task 5 (documentation)
```

## Acceptance Criteria

- [x] Config files can be read from all three locations
- [x] Precedence rules respected (env vars > project > user > defaults)
- [x] Required `topic` field enforced
- [x] All config options optional in JSON (can use env vars for any)
- [x] Backward compatible: existing env var setup works unchanged
- [x] All syntax checks pass
- [x] All tests pass (10/10 manual tests passing)
- [x] Documentation updated with examples
- [x] No breaking changes to existing API

## Test Strategy

**Config Loading Tests (BATS):**
```bash
# Test 1: Load user config
$NTFY_HOME_DIR=tmpdir config.sh load ~/.claude-ntfy.json

# Test 2: Precedence - project over user
$NTFY_HOME_DIR=tmpdir config.sh resolve

# Test 3: Env vars override all
NTFY_TOPIC=override config.sh resolve
```

**Integration Tests (manual):**
- Run hook with `.claude-ntfy.json` only
- Run hook with `NTFY_*` env vars only
- Run hook with both (verify env var precedence)
- Verify error when topic missing

## Implementation Notes

- Config loader returns JSON for easy consumption by hook
- Use `jq -r '.field' 2>/dev/null || echo default` pattern
- Handle missing files gracefully (not an error)
- Validate only when all sources resolved
- Keep config.sh testable and independent

## Success Metrics

- Zero breaking changes to existing setups
- Config files can replace all env vars except optional token
- Clear error messages for config issues
- All tests passing
- Documentation complete with examples
