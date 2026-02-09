---
category: decision
title: "Environment variables for configuration"
status: accepted
created: 2026-02-09
---

# Decision: Environment Variable Configuration

## Context

MCP servers receive env vars from their host (Claude Code passes `env` from config). Hook scripts inherit the shell environment.

## Decision

Use environment variables (`NTFY_SERVER_URL`, `NTFY_TOPIC`, `NTFY_TOKEN`) for all configuration. No config files.

## Rationale

- MCP servers already receive env from Claude Code config
- Hooks naturally read env vars
- Simplest approach — no config file parsing needed
- Secrets (tokens) are better in env vars than files
- Follows 12-factor app principles
