# claude-ntfy

A pure bash Claude Code plugin that sends push notifications via [ntfy](https://ntfy.sh).

Provides automatic notifications through hooks:
- **Stop** — Notified when Claude Code session ends
- **PermissionRequest** — Notified when Claude requests tool approval
- **Notification** — Notified for other Claude Code events

## Prerequisites

- bash 4.0+
- jq (for JSON parsing)
- curl (for HTTP requests)
- A self-hosted ntfy server (or use the public [ntfy.sh](https://ntfy.sh) service)

## Install as Plugin

```bash
claude plugin add /path/to/claude-ntfy
```

This registers the notification hooks automatically.

## Quick Start

### 1. Start an ntfy server

```bash
cd docker
docker compose up -d
```

This starts ntfy on `http://localhost:8080`.

### 2. Configure

Choose one method:

**Option A: Environment Variables**

```bash
export NTFY_TOPIC="claude-alerts"
export NTFY_SERVER_URL="http://localhost:8080"  # optional, this is the default
# export NTFY_TOKEN="tk_your_token"             # optional, for authenticated servers
```

**Option B: Configuration File**

Create `config.json` in the plugin directory (`$CLAUDE_PLUGIN_ROOT/config.json`):

```json
{
  "server_url": "http://localhost:8080",
  "topic": "claude-alerts"
}
```

Use the `/setup` skill to create this file interactively.

For more configuration options, see [docs/CONFIG.md](docs/CONFIG.md).

### 3. Install the Plugin

```bash
claude plugin add /path/to/claude-ntfy
```

The plugin will register the notification hooks automatically.

## How It Works

The plugin automatically sends notifications for these Claude Code events:

1. **Stop** — When your Claude Code session ends
   - Message: "Claude Code finished"
   - Example: "Session completed in my-project"

2. **PermissionRequest** — When Claude requests tool approval
   - Message: "Claude Code needs permission"
   - Shows the tool name and command being requested

3. **Notification** — For other Claude Code notifications
   - Forwards the notification title and message
   - Includes project context

Configuration can be provided via:
- Environment variables (`NTFY_SERVER_URL`, `NTFY_TOPIC`, `NTFY_TOKEN`)
- Plugin config file (`$CLAUDE_PLUGIN_ROOT/config.json`)
- Defaults (server: `http://localhost:8080`)

## Hook Events

The unified `hooks/notify.sh` script handles all events with contextual messages:

| Event | Title | Message |
|-------|-------|---------|
| `Stop` | Claude Code finished | Session completed in \<project\>. |
| `PermissionRequest` | Claude Code needs permission | \<tool\>: \<command\> |
| `Notification` | (from event) | (from event) (\<project\>) |

## Skills

| Skill | Description |
|-------|-------------|
| `setup` | Guide through ntfy server setup with Docker, env vars, and subscription |
| `test-notification` | Send a test notification and verify the setup works |

## Configuration Methods

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NTFY_TOPIC` | Yes | — | ntfy topic to publish to |
| `NTFY_SERVER_URL` | No | `http://localhost:8080` | ntfy server URL |
| `NTFY_TOKEN` | No | — | Bearer token for authentication |

### Configuration File

Create `config.json` in the plugin directory for persistent settings:

**Plugin Config** (`$CLAUDE_PLUGIN_ROOT/config.json`):
```json
{
  "server_url": "http://localhost:8080",
  "topic": "claude-alerts",
  "token": "tk_optional_token"
}
```

**Precedence** (highest to lowest):
1. Environment variables
2. Plugin config (`$CLAUDE_PLUGIN_ROOT/config.json`)
3. Defaults (server: `http://localhost:8080`)

For detailed configuration guide, see [docs/CONFIG.md](docs/CONFIG.md).

## Development

### Verify Script Syntax

```bash
bash -n hooks/lib/config.sh       # Check config loader
bash -n hooks/notify.sh           # Check notification hook
```

### Lint with shellcheck

```bash
shellcheck hooks/lib/config.sh hooks/notify.sh
```

### Run Tests

```bash
# BATS test framework (if installed)
bats tests/config.sh.bats

# Or run manual tests
bash tests/config.sh.bats
```

See [tests/config.sh.bats](tests/config.sh.bats) for comprehensive test coverage.

## License

MIT
