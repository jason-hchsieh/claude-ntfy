---
name: test-ntfy
description: Use this skill when the user wants to test, verify, or debug their ntfy notification setup. Triggers on requests like "test notification", "send test message", "verify ntfy works", or "check notification setup".
version: 2.1.0
---

# Test Notification

Send a test notification to verify the ntfy setup is working correctly.

## Reference

- Script: [`scripts/test-ntfy.sh`](../../scripts/README.md#test-ntfysh--test-notification)
- Config: [`docs/CONFIG.md`](../../docs/CONFIG.md)

## Steps

### 1. Run the test script

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/test-ntfy.sh"
```

This script loads configuration, checks server health, sends a test notification, and reports the result. See [`scripts/README.md`](../../scripts/README.md) for details.

### 2. Interpret results

| Result | Meaning | Action |
|--------|---------|--------|
| OK (HTTP 200) | Setup working | Ask user to check their ntfy client |
| FAIL (HTTP 401/403) | Auth failure | Check `NTFY_TOKEN` value |
| FAIL (HTTP 404) | Topic not found | Check topic name in config |
| FAIL (connection error) | Server unreachable | Check server URL |
| Config error | No topic configured | Suggest the `/setup` skill |

### 3. Troubleshooting

If the test passes but the user doesn't receive notifications:
- Verify subscription to the correct topic
- Check the server URL matches
- Try opening `$NTFY_SERVER_URL/$NTFY_TOPIC` in a browser
- Run the diagnostics script to inspect all config sources:
  ```bash
  bash "$CLAUDE_PLUGIN_ROOT/scripts/detect-config.sh"
  ```
