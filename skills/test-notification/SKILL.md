---
name: test-notification
description: Use this skill when the user wants to test, verify, or debug their ntfy notification setup. Triggers on requests like "test notification", "send test message", "verify ntfy works", or "check notification setup".
version: 1.0.0
---

# Test Notification

Send a test notification to verify the ntfy setup is working correctly.

## Steps

### 1. Check configuration

Verify the required environment variables are set:

```bash
echo "NTFY_SERVER_URL=${NTFY_SERVER_URL:-http://localhost:8080}"
echo "NTFY_TOPIC=${NTFY_TOPIC:-(not set)}"
```

If `NTFY_TOPIC` is not set, ask the user to configure it first (suggest the **setup** skill).

### 2. Send test notification

Send a test message using curl:

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
- **Connection refused**: The ntfy server is not running. Suggest the **setup-server** skill.
- **Other errors**: Show the full response and help debug.

### 4. Troubleshooting

If the notification was sent but not received:
- Verify the user is subscribed to the correct topic (`$NTFY_TOPIC`)
- Check the server URL matches (`$NTFY_SERVER_URL`)
- Try opening `$NTFY_SERVER_URL/$NTFY_TOPIC` in a browser to see messages
