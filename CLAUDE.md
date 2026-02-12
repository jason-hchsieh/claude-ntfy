# claude-ntfy

A pure bash plugin to send push notifications from Claude Code sessions via ntfy.

## Project Structure

```
hooks/
  hooks.json        # Plugin hook configuration
scripts/
  README.md         # Script usage and purpose documentation
  config.sh         # Configuration loading library
  notify.sh         # Unified ntfy notification hook (Stop, Notification, PermissionRequest)
  detect-config.sh  # Detect and display current ntfy configuration
  test-ntfy.sh      # Send test notification
skills/
  setup/            # Skill: guide ntfy setup (server, config, or both)
  test-ntfy/        # Skill: send test notification
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
bash -n scripts/config.sh        # Syntax check config loader
bash -n scripts/notify.sh        # Syntax check hook script
bash -n scripts/detect-config.sh # Syntax check detect script
bash -n scripts/test-ntfy.sh     # Syntax check test script
shellcheck scripts/*.sh          # Lint
bash scripts/detect-config.sh # Show current configuration
bash scripts/test-ntfy.sh     # Send test notification
```

## Conventions

- Shell scripts use `set -euo pipefail`
- Use `jq` for JSON parsing (compact output with `-c`)
- Use `printf '%s'` for safe variable substitution
- Use `curl` for HTTP requests to ntfy
- Config loader returns JSON with merge and validation support
