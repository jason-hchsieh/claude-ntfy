---
name: setup
description: Use this skill when the user wants to set up ntfy notifications for claude-ntfy. Triggers on requests like "set up ntfy", "configure notifications", "initialize ntfy", or "setup notification server". Supports both new server setup and configuration of existing servers.
version: 3.0.0
---

# Setup ntfy Notifications

Guide the user through setting up ntfy notifications for claude-ntfy. Supports both new server setup and configuration of existing servers.

## Overview

This skill helps with three scenarios:
1. **New Server Setup** - Start a self-hosted ntfy server using Docker
2. **Existing Server** - Configure claude-ntfy to use an existing ntfy server
3. **Public Service (ntfy.sh)** - Use the free public ntfy.sh service

## Step 0: Detect Existing Configuration

Before asking anything, run the detect script to see what's already configured:

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/detect-config.sh"
```

This shows environment variables, config files, resolved configuration, and server connectivity. Use the output to skip steps that are already done and guide the user to what's missing.

## Step 1: Clarify Setup Type

Ask the user which setup applies to them:

```
Which setup scenario applies to you?

1. New Server Setup
   → Start a self-hosted ntfy server using Docker Compose
   → Good for: Local development, isolated setup, full control

2. Existing Server
   → Configure to use an existing ntfy server
   → Good for: Production setups, shared infrastructure, already running

3. Public Service (ntfy.sh)
   → Use the public ntfy.sh service (no setup needed)
   → Good for: Quick testing, no infrastructure cost

Please choose: 1, 2, or 3
```

---

## Scenario 1: New Server Setup

### Step 1.1: Check Docker Availability

Run `docker --version` and `docker compose version` to verify Docker is installed.

If Docker is not available, tell the user:
- They need Docker installed to run a self-hosted ntfy server
- Alternatively, they can use the public `https://ntfy.sh` service

### Step 1.2: Start the ntfy Server

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

### Step 1.3: Choose Configuration Method

Ask the user how they want to configure claude-ntfy:

```
How would you like to configure claude-ntfy?

A. Environment Variables (Temporary)
   export NTFY_TOPIC="claude-alerts"
   export NTFY_SERVER_URL="http://localhost:8080"

B. Plugin Config File (Persistent)
   Create config.json in the plugin directory
   Good for: Permanent setup, survives shell restarts

Please choose: A or B
```

### Step 1.4: Set Configuration

**If A (Environment Variables):**

Ask for the topic name and provide the export commands:

```bash
export NTFY_TOPIC="claude-alerts"
export NTFY_SERVER_URL="http://localhost:8080"
```

**If B (Plugin Config File):**

Ask for the topic name, then create `$CLAUDE_PLUGIN_ROOT/config.json`:

```json
{
  "server_url": "http://localhost:8080",
  "topic": "claude-alerts"
}
```

### Step 1.5: Verify Configuration

Guide through verification:

```bash
# Send a test notification
curl -H "Title: Test" \
     -d "Claude-ntfy is working!" \
     http://localhost:8080/claude-alerts
```

---

## Scenario 2: Existing Server Configuration

### Step 2.1: Detect Existing Configuration

Check for existing configuration:

```bash
# Check environment variables
echo "NTFY_SERVER_URL: ${NTFY_SERVER_URL:-not set}"
echo "NTFY_TOPIC: ${NTFY_TOPIC:-not set}"
echo "NTFY_TOKEN: ${NTFY_TOKEN:-not set}"

# Check plugin config file
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
  cat "${CLAUDE_PLUGIN_ROOT}/config.json" 2>/dev/null || echo "Plugin config not found"
fi
```

If configuration exists, show what was found and ask if user wants to:
- Keep existing configuration
- Update it
- Create a new configuration

### Step 2.2: Gather Server Information

If no configuration found, ask the user for:

```
Please provide the following information:

1. Server URL (e.g., https://ntfy.example.com or http://localhost:8080)
   Server URL: [user input]

2. Topic name (e.g., claude-alerts)
   Topic: [user input]

3. Authentication token (if required, leave blank if not)
   Token (optional): [user input]
```

### Step 2.3: Configuration Options

After gathering information, offer configuration options:

```
How would you like to store this configuration?

A. Environment Variables (for this shell session)
   export NTFY_SERVER_URL="<url>"
   export NTFY_TOPIC="<topic>"
   [if token] export NTFY_TOKEN="<token>"

B. Plugin Config File ($CLAUDE_PLUGIN_ROOT/config.json)
   Persistent across sessions
   Stored with the plugin

Please choose: A or B
```

### Step 2.4: Create Configuration

**If A (Environment Variables):**

Provide the export commands with the user's values.

**If B (Plugin Config File):**

Create `$CLAUDE_PLUGIN_ROOT/config.json`:

```json
{
  "server_url": "<user-provided-url>",
  "topic": "<user-provided-topic>"
}
```

If token is provided, include it:

```json
{
  "server_url": "<user-provided-url>",
  "topic": "<user-provided-topic>",
  "token": "<user-provided-token>"
}
```

If token is included, set restrictive permissions:

```bash
chmod 600 "$CLAUDE_PLUGIN_ROOT/config.json"
```

### Step 2.5: Verify Connection

Test the configuration:

```bash
# Test connectivity
curl -I "<server-url>/v1/health"
```

Expected: HTTP 200 response

---

## Scenario 3: Public Service (ntfy.sh)

### Step 3.1: Choose Configuration Method

ntfy.sh is public, so just configure the topic and URL:

```
Using ntfy.sh (public service)

Server: https://ntfy.sh
Topic: [ask user for topic name]
```

### Step 3.2: Create Configuration

Use the same configuration options as Scenario 2.3:

```bash
# Environment variable
export NTFY_SERVER_URL="https://ntfy.sh"
export NTFY_TOPIC="<user-chosen-topic>"
```

Or in `$CLAUDE_PLUGIN_ROOT/config.json`:

```json
{
  "server_url": "https://ntfy.sh",
  "topic": "<user-chosen-topic>"
}
```

---

## Configuration File Format Reference

### $CLAUDE_PLUGIN_ROOT/config.json

```json
{
  "server_url": "http://localhost:8080",
  "topic": "claude-alerts",
  "token": "tk_optional_bearer_token"
}
```

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `server_url` | No | `http://localhost:8080` | ntfy server URL |
| `topic` | Yes | — | ntfy topic to publish to |
| `token` | No | — | Bearer token for authentication |

---

## Configuration Precedence

When claude-ntfy loads, it uses this precedence (highest to lowest):

1. **Environment variables** (`NTFY_SERVER_URL`, `NTFY_TOPIC`, `NTFY_TOKEN`)
2. **Plugin config** (`$CLAUDE_PLUGIN_ROOT/config.json`)
3. **Defaults** (server: `http://localhost:8080`)

---

## Verification Checklist

After setup, verify:

- [ ] Server is running/reachable
- [ ] Configuration loaded correctly
- [ ] NTFY_TOPIC is set (required)
- [ ] NTFY_SERVER_URL is accessible
- [ ] NTFY_TOKEN is correct (if using authentication)
- [ ] Plugin is installed: `claude plugin list | grep ntfy`

---

## Next Steps

After setup is complete:

1. **Install the plugin** (if not already installed):
   ```bash
   claude plugin add /path/to/claude-ntfy
   ```

2. **Test notifications** using the `test-notification` skill:
   ```
   "Send a test notification to verify setup"
   ```

3. **Start Claude Code** - Notifications will now be sent automatically

---

## Troubleshooting

### Configuration not being recognized

```bash
# Check current configuration
echo "Server: ${NTFY_SERVER_URL:-not set}"
echo "Topic: ${NTFY_TOPIC:-not set}"

# Check plugin config file
cat "${CLAUDE_PLUGIN_ROOT}/config.json" 2>/dev/null || echo "Plugin config not found"
```

Precedence: env vars > plugin config > defaults

### Server connection issues

```bash
# Test connectivity to server
curl -I "${NTFY_SERVER_URL:-http://localhost:8080}/v1/health"

# If using Docker locally, check it's running
docker ps | grep ntfy

# Check if port is in use
lsof -i :8080
```

### Authentication failures

- Verify `NTFY_TOKEN` is set correctly
- Check token format (should be `tk_...`)
- Verify server requires authentication

### Docker issues

- Ensure Docker daemon is running
- Check disk space: `docker system df`
- Review logs: `docker logs ntfy`

---

## Reference

- ntfy Documentation: https://docs.ntfy.sh/
- Configuration Guide: See [docs/CONFIG.md](../../docs/CONFIG.md)
- Test Notification Skill: Use `test-notification` skill after setup
