# Configuration

claude-ntfy can be configured via JSON configuration files or environment variables. Environment variables take precedence over configuration files.

## Quick Start

The simplest way is to set the required environment variable:

```bash
export NTFY_TOPIC="claude-alerts"
# Optional:
export NTFY_SERVER_URL="http://localhost:8080"
export NTFY_TOKEN="tk_your_token"
```

For persistent configuration, create a config file.

## Configuration Files

### File Locations (search order)

claude-ntfy looks for configuration files in this order:

1. **Project-level config** (highest priority after env vars):
   - `.claude-ntfy.json` (project root)
   - `.claude/ntfy.json` (Claude Code settings directory)

2. **User-level config**:
   - `~/.claude-ntfy.json` (user home directory)

3. **Defaults**:
   - Server: `http://localhost:8080`

The **first file found** is used. Only **environment variables override** configuration files.

### Configuration Schema

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

## Examples

### Global User Configuration

Save to `~/.claude-ntfy.json`:

```json
{
  "server_url": "https://ntfy.example.com",
  "topic": "my-alerts",
  "token": "tk_abc123xyz"
}
```

### Project-Specific Configuration

Save to `.claude-ntfy.json` in your project root:

```json
{
  "server_url": "http://localhost:8080",
  "topic": "my-project-alerts"
}
```

Or in `.claude/ntfy.json`:

```json
{
  "topic": "claude-dev-alerts"
}
```

### With Environment Variables

Environment variables **always** take precedence:

```bash
# This will override topic from config files
export NTFY_TOPIC="override-topic"

# But server_url will come from config file
```

## Precedence (highest to lowest)

1. **Environment Variables** (if set)
   - `NTFY_SERVER_URL`
   - `NTFY_TOPIC`
   - `NTFY_TOKEN`

2. **Project Config** (first found)
   - `.claude-ntfy.json`
   - `.claude/ntfy.json`

3. **User Config**
   - `~/.claude-ntfy.json`

4. **Defaults**
   - `server_url`: `http://localhost:8080`

## Migration from Environment Variables

If you're currently using only environment variables, here's how to migrate:

### Before (env vars only)

```bash
export NTFY_TOPIC="claude-alerts"
export NTFY_SERVER_URL="https://ntfy.example.com"
export NTFY_TOKEN="tk_abc123xyz"
```

### After (config file)

Create `~/.claude-ntfy.json`:

```json
{
  "server_url": "https://ntfy.example.com",
  "topic": "claude-alerts",
  "token": "tk_abc123xyz"
}
```

Then you only need:
```bash
# NTFY_TOPIC is now optional (read from config)
# Or override for specific shells/projects
```

## Configuration Validation

- **Invalid JSON**: Configuration file will be skipped with a warning
- **Missing required `topic`**: An error will be shown if neither a config file nor `NTFY_TOPIC` env var is set
- **Missing config files**: Not an error — the next location is checked

## Debugging

To see which configuration is being used, set `NTFY_DEBUG=1`:

```bash
NTFY_DEBUG=1 /path/to/claude-ntfy/hooks/notify.sh < event.json
```

This will show:
- Which config files were checked
- Which values were loaded
- Final resolved configuration
