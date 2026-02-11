---
name: test-notification
description: Use this skill when the user wants to test, verify, or debug their ntfy notification setup. Triggers on requests like "test notification", "send test message", "verify ntfy works", or "check notification setup".
version: 1.1.0
---

# Test Notification

Send a test notification to verify the ntfy setup is working correctly.

## Steps

### 1. Detect configuration

Run the detect script to see the current configuration state:

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/detect-config.sh"
```

This shows env vars, config files (`~/.config/claude-ntfy/config.json` and `~/.claude/claude-ntfy/config.json`), resolved configuration, and server connectivity.

If the topic is not configured, ask the user to configure it first (suggest the **setup** skill).

### 2. Send test notification

Send a test message using curl with the resolved configuration:

```bash
curl -H "Title: Claude Code Test" \
     -d "This is a test notification from claude-ntfy. If you see this, your setup is working!" \
     "${NTFY_SERVER_URL:-http://localhost:8080}/${NTFY_TOPIC}"
```

If `NTFY_TOKEN` is set, include authentication:

```bash
curl -H "Title: Claude Code Test" \
     -H "Authorization: Bearer ${NTFY_TOKEN}" \
     -d "This is a test notification from claude-ntfy. If you see this, your setup is working!" \
     "${NTFY_SERVER_URL:-http://localhost:8080}/${NTFY_TOPIC}"
```

### 3. Verify result

Check the curl response:

- **HTTP 200**: Notification sent successfully. Tell the user to check their ntfy client (web, mobile, or desktop) for the message.
- **HTTP 401/403**: Authentication issue. The `NTFY_TOKEN` may be incorrect or missing.
- **Connection refused**: The ntfy server is not running. Suggest the **setup** skill.
- **Other errors**: Show the full response and help debug.

### 4. Troubleshooting

If the notification was sent but not received:
- Verify the user is subscribed to the correct topic (`$NTFY_TOPIC`)
- Check the server URL matches (`$NTFY_SERVER_URL`)
- Try opening `$NTFY_SERVER_URL/$NTFY_TOPIC` in a browser to see messages
- Run `bash "$CLAUDE_PLUGIN_ROOT/scripts/detect-config.sh"` to verify all config sources
