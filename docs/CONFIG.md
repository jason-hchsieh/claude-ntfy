# Configuration

claude-ntfy can be configured via environment variables or config files.

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

### Locations

claude-ntfy searches for config files in this order (later files override earlier ones):

1. **`~/.claude/claude-ntfy/config.json`** — Claude-native path
2. **`~/.config/claude-ntfy/config.json`** — XDG Base Directory spec (`$XDG_CONFIG_HOME/claude-ntfy/config.json`)

The recommended location is `~/.config/claude-ntfy/config.json` (XDG-compliant).

### Creating a Config File

```bash
mkdir -p ~/.config/claude-ntfy
cat > ~/.config/claude-ntfy/config.json << 'EOF'
{
  "server_url": "http://localhost:8080",
  "topic": "claude-alerts"
}
EOF
```

Or use the `/setup` skill to create this file interactively.

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

2. **XDG Config**
   - `~/.config/claude-ntfy/config.json`

3. **Claude Dir Config**
   - `~/.claude/claude-ntfy/config.json`

4. **Defaults**
   - `server_url`: `http://localhost:8080`

## Examples

### XDG Config File

Create `~/.config/claude-ntfy/config.json`:

```json
{
  "server_url": "https://ntfy.example.com",
  "topic": "my-alerts",
  "token": "tk_abc123xyz"
}
```

### Claude Dir Config File

Alternatively, create `~/.claude/claude-ntfy/config.json`:

```json
{
  "server_url": "https://ntfy.example.com",
  "topic": "my-alerts"
}
```

Note: If both files exist, XDG config takes priority over Claude dir config.

### Environment Variable Override

Environment variables **always** take precedence over config files:

```bash
# This will override topic from config file
export NTFY_TOPIC="override-topic"

# But server_url will come from config file
```

## Detecting Configuration

Run the detect script to see all config sources and the resolved configuration:

```bash
bash scripts/detect-config.sh
```

This shows:
- Environment variables (set or not)
- Config files found and their contents
- Final resolved configuration
- Server connectivity status

## Configuration Validation

- **Invalid JSON**: Configuration file will be skipped with a warning
- **Missing required `topic`**: An error will be shown if neither config file nor `NTFY_TOPIC` env var provides it
- **Missing config file**: Not an error — defaults and env vars are used
