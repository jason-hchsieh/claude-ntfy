# claude-ntfy

A pure bash plugin to send push notifications from Claude Code sessions via ntfy.

## Project Structure

```
hooks/
  notify.sh         # Unified ntfy notification hook (Stop, Notification, PermissionRequest)
  lib/
    config.sh       # Configuration loading and merging
  hooks.json        # Plugin hook configuration
skills/
  setup/            # Skill: guide ntfy setup (server, config, or both)
  test-ntfy/        # Skill: send test notification
scripts/
  detect-config.sh  # Detect and display current ntfy configuration
docker/             # Docker compose for self-hosted ntfy
docs/
  CONFIG.md         # Configuration file documentation
.claude-plugin/
  plugin.json       # Plugin manifest
```

## Configuration

The plugin supports configuration via:
- **Environment variables** (highest priority): `NTFY_SERVER_URL`, `NTFY_TOPIC`, `NTFY_TOKEN`
- **User config** (`$XDG_CONFIG_HOME/claude-ntfy/config.json`, defaults to `~/.config/claude-ntfy/config.json`)
- **Defaults** (server: `http://localhost:8080`)

See [docs/CONFIG.md](docs/CONFIG.md) for detailed configuration instructions.

## Verification

```bash
bash -n hooks/lib/config.sh   # Syntax check config loader
bash -n hooks/notify.sh       # Syntax check hook script
bash -n scripts/detect-config.sh  # Syntax check detect script
shellcheck hooks/lib/config.sh hooks/notify.sh scripts/detect-config.sh  # Lint (if shellcheck installed)
bash scripts/detect-config.sh # Show current configuration
```

## Conventions

- Shell scripts use `set -euo pipefail`
- Use `jq` for JSON parsing (compact output with `-c`)
- Use `printf '%s'` for safe variable substitution
- Use `curl` for HTTP requests to ntfy
- Config loader returns JSON with merge and validation support
