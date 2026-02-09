# Plan: Claude Code ntfy Plugin

## Overview

Build a Claude Code plugin that provides ntfy notification capabilities through two channels:
1. **MCP Server** — on-demand tool for Claude to send notifications (`send_notification`)
2. **Hooks** — automatic notifications on key events (Stop, Notification)
3. **Docker setup** — helper to spin up a self-hosted ntfy server

## Architecture

```
claude-ntfy/
├── src/
│   ├── ntfy-client.ts        # Core ntfy HTTP client
│   ├── mcp-server.ts         # MCP server exposing send_notification tool
│   ├── config.ts             # Configuration loading (env vars, config file)
│   └── types.ts              # Shared TypeScript types
├── hooks/
│   ├── notify-on-stop.sh     # Hook script: send notification when Claude stops
│   └── notify-on-notification.sh  # Hook script: forward Claude notifications to ntfy
├── docker/
│   └── docker-compose.yml    # Self-hosted ntfy server setup
├── tests/
│   ├── ntfy-client.test.ts   # Tests for ntfy client
│   ├── mcp-server.test.ts    # Tests for MCP server
│   └── config.test.ts        # Tests for config loading
├── package.json
├── tsconfig.json
└── README.md                 # Setup & usage instructions
```

## Configuration

The plugin reads configuration from environment variables:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NTFY_SERVER_URL` | Yes | `http://localhost:8080` | ntfy server URL |
| `NTFY_TOPIC` | Yes | — | Topic to publish to |
| `NTFY_TOKEN` | No | — | Bearer token for auth |

## Tasks

### Task 1: Core Types & Config
**TDD** | No dependencies

- **Test:** `tests/config.test.ts` — validate config loading from env vars, defaults, error on missing required fields
- **Implement:** `src/types.ts` (NtfyMessage, NtfyConfig types) + `src/config.ts` (loadConfig function)

### Task 2: ntfy HTTP Client
**TDD** | Depends on: Task 1

- **Test:** `tests/ntfy-client.test.ts` — test publish message, auth header, error handling, server URL construction
- **Implement:** `src/ntfy-client.ts` — `NtfyClient` class with `publish(message: NtfyMessage)` method using native `fetch()`

### Task 3: MCP Server
**TDD** | Depends on: Task 2

- **Test:** `tests/mcp-server.test.ts` — test tool registration, tool call handling, input validation
- **Implement:** `src/mcp-server.ts` — MCP server using `@modelcontextprotocol/sdk` with `send_notification` tool
- **Dependencies:** `@modelcontextprotocol/sdk`, `zod`

### Task 4: Hook Scripts
Depends on: Task 2

- **Implement:** `hooks/notify-on-stop.sh` — reads stdin JSON, sends notification via curl to ntfy
- **Implement:** `hooks/notify-on-notification.sh` — forwards Claude notification events to ntfy
- Both scripts read config from env vars (`NTFY_SERVER_URL`, `NTFY_TOPIC`, `NTFY_TOKEN`)

### Task 5: Docker Compose for ntfy Server
No dependencies (parallel)

- **Implement:** `docker/docker-compose.yml` — self-hosted ntfy server with persistent storage
- Basic config: port 8080, data volume, cache volume

### Task 6: Build & Package Configuration
Depends on: Task 3

- Update `package.json` with bin entry, dependencies, build scripts
- Add MCP server entry point (`bin` field)
- Ensure `pnpm run build` produces working dist output

### Task 7: Documentation & Claude Code Integration Config
Depends on: Task 4, Task 5, Task 6

- Create sample `.claude/settings.json` showing hook configuration
- Create sample MCP server configuration for Claude Code
- README with setup instructions

## Dependency Graph

```
Task 1 (types/config) ──→ Task 2 (ntfy client) ──→ Task 3 (MCP server) ──→ Task 6 (build)
                                                  ↘                                       ↘
Task 5 (docker) ─────────────────────────────────── Task 4 (hooks) ──────────→ Task 7 (docs)
```

## Tech Decisions

- **Native `fetch()`** for HTTP — no axios/node-fetch needed (Node 22 built-in)
- **`@modelcontextprotocol/sdk`** for MCP server — official TypeScript SDK
- **Shell scripts for hooks** — hooks must be executable commands, shell is simplest
- **No framework** — keep it minimal, just the MCP SDK + zod for validation
