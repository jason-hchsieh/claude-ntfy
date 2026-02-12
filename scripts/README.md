# Scripts

Shared scripts for the claude-ntfy plugin. All scripts source `config.sh` for configuration loading.

## Scripts

### config.sh — Configuration Library

Shared library sourced by all other scripts. Not meant to be run directly.

**Provides:**
- `load_config <file>` — Load and validate a JSON config file
- `validate_config <json>` — Validate required fields (topic)
- `resolve_config` — Resolve config from all sources (env vars > XDG config > defaults)
- `config_value <json> <field> [default]` — Extract a field from config JSON
- `set_config_vars <json>` — Set `NTFY_SERVER_URL`, `NTFY_TOPIC`, `NTFY_TOKEN` from config JSON
- `build_auth_headers [token]` — Set `NTFY_HEADERS` array for curl authentication
- `CLAUDE_NTFY_CONFIG_FILE` — Path to user config file (`$XDG_CONFIG_HOME/claude-ntfy/config.json`)

**Usage in other scripts:**
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

CONFIG=$(resolve_config) || exit 1
set_config_vars "$CONFIG"
build_auth_headers
```

See [docs/CONFIG.md](../docs/CONFIG.md) for configuration details.

### notify.sh — Notification Hook

Hook entry point called by Claude Code for `Stop`, `PermissionRequest`, and `Notification` events. Reads event JSON from stdin, formats a contextual message, and sends it via ntfy.

**Called by:** `hooks/hooks.json` (not run manually)

**Title format:** `Event | Project (branch) | Username @ Hostname`
*(branch is included only if the project is a git repository)*

| Event | Tags | Priority | Message |
|-------|------|----------|---------|
| Stop | white_check_mark | 3 (default) | Session completed. |
| PermissionRequest | warning | 4 (high) | **tool**: \`command\` |
| Notification | bell | 3 (default) | Event title and message |

### detect-config.sh — Configuration Diagnostics

Displays all configuration sources, the resolved configuration, and server connectivity status. Useful for debugging configuration issues.

```bash
bash scripts/detect-config.sh
```

**Output sections:**
1. **Environment Variables** — Shows which `NTFY_*` env vars are set
2. **Config Files** — Shows config file contents or reports missing/invalid
3. **Resolved Configuration** — Final merged config after precedence rules
4. **Server Connectivity** — Health check against the ntfy server

### test-ntfy.sh — Test Notification

Sends a test notification to verify the ntfy setup is working. Reports success or failure with actionable error messages.

```bash
bash scripts/test-ntfy.sh
```

**Steps performed:**
1. Load and display configuration
2. Check server health (`/v1/health` endpoint)
3. Send a test notification
4. Report result with HTTP status code

**Exit codes:**

| HTTP Code | Meaning | Suggested Fix |
|-----------|---------|---------------|
| 200 | Success | Check ntfy client for message |
| 401/403 | Auth failure | Check `NTFY_TOKEN` |
| 404 | Topic not found | Check topic name |
| 000 | Connection error | Check server URL |

## Configuration

All scripts use the same configuration precedence:

1. **Environment variables** (`NTFY_SERVER_URL`, `NTFY_TOPIC`, `NTFY_TOKEN`)
2. **Config file** (`~/.config/claude-ntfy/config.json`)
3. **Defaults** (server: `http://localhost:8080`)

See [docs/CONFIG.md](../docs/CONFIG.md) for the full configuration guide.

## Verification

```bash
bash -n scripts/config.sh         # Syntax check
bash -n scripts/notify.sh
bash -n scripts/detect-config.sh
bash -n scripts/test-ntfy.sh
shellcheck scripts/*.sh           # Lint
bats tests/config.sh.bats         # Unit tests
```
