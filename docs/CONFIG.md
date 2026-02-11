# Configuration

claude-ntfy can be configured via environment variables or a plugin config file.

## Quick Start

The simplest way is to set the required environment variable:

```bash
export NTFY_TOPIC="claude-alerts"
# Optional:
export NTFY_SERVER_URL="http://localhost:8080"
export NTFY_TOKEN="tk_your_token"
```

For persistent configuration, create a config file.

## Configuration File

### Location

claude-ntfy reads configuration from:

```
$CLAUDE_PLUGIN_ROOT/config.json
```

`$CLAUDE_PLUGIN_ROOT` is set by Claude Code to the plugin's installation directory. Use the `/setup` skill to create this file automatically.

### Schema

```json
{
  "server_url": "http://localhost:8080",
  "topic": "claude-alerts",
  "token": "tk_optional_bearer_token"
}
```

**Fields:**

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `server_url` | No | `http://localhost:8080` | ntfy server URL |
| `topic` | Yes* | — | ntfy topic to publish to |
| `token` | No | — | Bearer token for authentication |

*Required unless provided via `NTFY_TOPIC` environment variable.

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NTFY_TOPIC` | Yes | — | ntfy topic to publish to |
| `NTFY_SERVER_URL` | No | `http://localhost:8080` | ntfy server URL |
| `NTFY_TOKEN` | No | — | Bearer token for authentication |

## Precedence (highest to lowest)

1. **Environment Variables** (if set)
   - `NTFY_SERVER_URL`
   - `NTFY_TOPIC`
   - `NTFY_TOKEN`

2. **Plugin Config**
   - `$CLAUDE_PLUGIN_ROOT/config.json`

3. **Defaults**
   - `server_url`: `http://localhost:8080`

## Examples

### Config File

Create `config.json` in the plugin directory:

```json
{
  "server_url": "https://ntfy.example.com",
  "topic": "my-alerts",
  "token": "tk_abc123xyz"
}
```

### Environment Variable Override

Environment variables **always** take precedence over the config file:

```bash
# This will override topic from config file
export NTFY_TOPIC="override-topic"

# But server_url will come from config file
```

## Migration from ~/.claude-ntfy.json

If you previously used `~/.claude-ntfy.json`, move it to the plugin directory:

```bash
# Find your plugin root
# It's typically at ~/.claude/plugins/cache/<plugin-path>

# Copy your config
cp ~/.claude-ntfy.json "$CLAUDE_PLUGIN_ROOT/config.json"

# Or use the /setup skill to reconfigure
```

## Configuration Validation

- **Invalid JSON**: Configuration file will be skipped with a warning
- **Missing required `topic`**: An error will be shown if neither config file nor `NTFY_TOPIC` env var provides it
- **Missing config file**: Not an error — defaults and env vars are used
