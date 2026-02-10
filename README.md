# claude-ntfy

A Claude Code plugin that sends push notifications via [ntfy](https://ntfy.sh).

Provides two notification channels:
- **MCP Server** — Claude can call `send_notification` to send notifications on demand
- **Hooks** — Automatic notifications when Claude stops, requests permission, or sends notification events

## Prerequisites

- Node.js 22+
- A self-hosted ntfy server (or use the public ntfy.sh service)

## Install as Plugin

```bash
claude plugin add /path/to/claude-ntfy
```

This registers the MCP server and hooks automatically.

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

Create `~/.claude-ntfy.json`:

```json
{
  "server_url": "http://localhost:8080",
  "topic": "claude-alerts"
}
```

Or create a project-specific `.claude-ntfy.json`:

```json
{
  "topic": "my-project-alerts"
}
```

For more configuration options, see [docs/CONFIG.md](docs/CONFIG.md).

### 3. Build

```bash
pnpm install
pnpm run build
```

## Manual Configuration

If not using the plugin install, configure each channel manually:

### MCP Server (on-demand notifications)

Add to your Claude Code MCP settings (`~/.claude.json` or project `.mcp.json`):

```json
{
  "mcpServers": {
    "claude-ntfy": {
      "command": "npx",
      "args": ["claude-ntfy"],
      "env": {
        "NTFY_TOPIC": "claude-alerts",
        "NTFY_SERVER_URL": "http://localhost:8080"
      }
    }
  }
}
```

Claude will then have access to the `send_notification` tool.

### Hooks (automatic notifications)

Add to `.claude/settings.json` in your project (or `~/.claude/settings.json` globally):

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/claude-ntfy/hooks/notify.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/claude-ntfy/hooks/notify.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/claude-ntfy/hooks/notify.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

Make sure the hook environment has `NTFY_TOPIC` (and optionally `NTFY_SERVER_URL`, `NTFY_TOKEN`) set.

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
| `setup-server` | Guide through ntfy server setup with Docker, env vars, and subscription |
| `test-notification` | Send a test notification and verify the setup works |

## Configuration Methods

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NTFY_TOPIC` | Yes | — | ntfy topic to publish to |
| `NTFY_SERVER_URL` | No | `http://localhost:8080` | ntfy server URL |
| `NTFY_TOKEN` | No | — | Bearer token for authentication |

### Configuration Files

Create JSON configuration files for persistent settings:

**Global User Config** (`~/.claude-ntfy.json`):
```json
{
  "server_url": "http://localhost:8080",
  "topic": "claude-alerts",
  "token": "tk_optional_token"
}
```

**Project Config** (`.claude-ntfy.json` or `.claude/ntfy.json`):
```json
{
  "topic": "project-specific-topic"
}
```

**Precedence** (highest to lowest):
1. Environment variables
2. Project config (`.claude-ntfy.json` or `.claude/ntfy.json`)
3. User config (`~/.claude-ntfy.json`)
4. Defaults (server: `http://localhost:8080`)

For detailed configuration guide, see [docs/CONFIG.md](docs/CONFIG.md).

## Development

```bash
pnpm install
pnpm test            # Run tests
pnpm test:watch      # Run tests in watch mode
pnpm run build       # Build
pnpm run lint        # Type check
```

## License

MIT
