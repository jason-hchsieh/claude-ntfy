# claude-ntfy

A pure bash plugin to send push notifications from Claude Code sessions via ntfy.

## Project Structure

```
hooks/
  notify.sh         # Unified ntfy notification hook (Stop, Notification, PermissionRequest)
  hooks.json        # Plugin hook configuration
skills/
  setup-server/     # Skill: guide ntfy server setup
  test-notification/ # Skill: send test notification
docker/             # Docker compose for self-hosted ntfy
.claude-plugin/
  plugin.json       # Plugin manifest
```

## Verification

```bash
bash -n hooks/notify.sh       # Syntax check
shellcheck hooks/notify.sh    # Lint (if shellcheck installed)
```

## Conventions

- Shell scripts use `set -euo pipefail`
- Use `jq` for JSON parsing in hooks
- Use `curl` for HTTP requests to ntfy
