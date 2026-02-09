# claude-ntfy

A Claude Code plugin that sends push notifications via [ntfy](https://ntfy.sh).

Provides two notification channels:
- **MCP Server** — Claude can call `send_notification` to send notifications on demand
- **Hooks** — Automatic notifications when Claude stops or sends notification events

## Prerequisites

- Node.js 22+
- A self-hosted ntfy server (or use the public ntfy.sh service)

## Quick Start

### 1. Start an ntfy server

```bash
cd docker
docker compose up -d
```

This starts ntfy on `http://localhost:8080`.

### 2. Set environment variables

```bash
export NTFY_TOPIC="claude-alerts"
export NTFY_SERVER_URL="http://localhost:8080"  # optional, this is the default
# export NTFY_TOKEN="tk_your_token"             # optional, for authenticated servers
```

### 3. Build

```bash
pnpm install
pnpm run build
```

### 4. Configure Claude Code

#### MCP Server (on-demand notifications)

Add to your Claude Code MCP settings (`~/.claude.json` or project `.mcp.json`):

```json
{
  "mcpServers": {
    "ntfy": {
      "command": "node",
      "args": ["/absolute/path/to/claude-ntfy/dist/index.js"],
      "env": {
        "NTFY_TOPIC": "claude-alerts",
        "NTFY_SERVER_URL": "http://localhost:8080"
      }
    }
  }
}
```

Claude will then have access to the `send_notification` tool.

#### Hooks (automatic notifications)

Add to `.claude/settings.json` in your project (or `~/.claude/settings.json` globally):

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/claude-ntfy/hooks/notify-on-stop.sh",
            "async": true
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/claude-ntfy/hooks/notify-on-notification.sh",
            "async": true
          }
        ]
      }
    ]
  }
}
```

Make sure the hook environment has `NTFY_TOPIC` (and optionally `NTFY_SERVER_URL`, `NTFY_TOKEN`) set.

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NTFY_TOPIC` | Yes | — | ntfy topic to publish to |
| `NTFY_SERVER_URL` | No | `http://localhost:8080` | ntfy server URL |
| `NTFY_TOKEN` | No | — | Bearer token for authentication |

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
