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
  setup-server/     # Skill: guide ntfy server setup
  test-notification/ # Skill: send test notification
docker/             # Docker compose for self-hosted ntfy
docs/
  CONFIG.md         # Configuration file documentation
.claude-plugin/
  plugin.json       # Plugin manifest
```

## Configuration

The plugin supports configuration via:
- **Environment variables** (highest priority): `NTFY_SERVER_URL`, `NTFY_TOPIC`, `NTFY_TOKEN`
- **Project config** (`.claude-ntfy.json` or `.claude/ntfy.json`)
- **User config** (`~/.claude-ntfy.json`)
- **Defaults** (server: `http://localhost:8080`)

See [docs/CONFIG.md](docs/CONFIG.md) for detailed configuration instructions.

## Verification

```bash
bash -n hooks/lib/config.sh   # Syntax check config loader
bash -n hooks/notify.sh       # Syntax check hook script
shellcheck hooks/lib/config.sh hooks/notify.sh  # Lint (if shellcheck installed)
```

## Conventions

- Shell scripts use `set -euo pipefail`
- Use `jq` for JSON parsing (compact output with `-c`)
- Use `printf '%s'` for safe variable substitution
- Use `curl` for HTTP requests to ntfy
- Config loader returns JSON with merge and validation support
