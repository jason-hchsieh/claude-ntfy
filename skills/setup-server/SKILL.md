---
name: setup-server
description: Use this skill when the user wants to set up, configure, or start an ntfy notification server for use with claude-ntfy. Triggers on requests like "set up ntfy", "configure notifications", "start ntfy server", or "set up notification server".
version: 1.0.0
---

# Setup ntfy Server

Guide the user through setting up a self-hosted ntfy server and configuring the claude-ntfy plugin.

## Steps

### 1. Check Docker availability

Run `docker --version` and `docker compose version` to verify Docker is installed.

If Docker is not available, tell the user:
- They need Docker installed to run a self-hosted ntfy server
- Alternatively, they can use the public `https://ntfy.sh` service and skip to step 3

### 2. Start the ntfy server

The plugin includes a Docker Compose file. Start it:

```bash
docker compose -f $CLAUDE_PLUGIN_ROOT/docker/docker-compose.yml up -d
```

Verify it's running:

```bash
curl -s http://localhost:8080/v1/health | head -c 200
```

Expected: a JSON response indicating the server is healthy. If it fails, check:
- Port 8080 is not in use (`lsof -i :8080`)
- Docker daemon is running

### 3. Configure environment variables

Ask the user for their preferred topic name (e.g., `claude-alerts`). Then set the environment variables:

```bash
export NTFY_TOPIC="<user-chosen-topic>"
export NTFY_SERVER_URL="http://localhost:8080"
```

If using the public ntfy.sh service instead:

```bash
export NTFY_TOPIC="<user-chosen-topic>"
export NTFY_SERVER_URL="https://ntfy.sh"
```

For authenticated servers, also set:

```bash
export NTFY_TOKEN="<bearer-token>"
```

### 4. Subscribe to notifications

Tell the user how to receive notifications:

- **Web:** Open `$NTFY_SERVER_URL/$NTFY_TOPIC` in a browser
- **Mobile:** Install the ntfy app ([Android](https://play.google.com/store/apps/details?id=io.heckel.ntfy), [iOS](https://apps.apple.com/app/ntfy/id1625396347)) and subscribe to the topic
- **Desktop:** Use `ntfy subscribe $NTFY_TOPIC` CLI

### 5. Verify setup

Suggest the user run the **test-notification** skill to send a test message and confirm everything works.
