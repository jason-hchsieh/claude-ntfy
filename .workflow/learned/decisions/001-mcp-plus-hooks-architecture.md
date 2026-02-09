---
category: decision
title: "Use both MCP server and hooks for Claude Code integration"
status: accepted
created: 2026-02-09
---

# Decision: MCP Server + Hooks Architecture

## Context

Claude Code supports two extension mechanisms:
1. **MCP servers** — provide tools Claude can call on demand
2. **Hooks** — shell commands triggered by lifecycle events

## Decision

Use both:
- **MCP server** for on-demand notifications (`send_notification` tool)
- **Hooks** for automatic notifications on `Stop` and `Notification` events

## Rationale

- MCP server gives Claude explicit control over when to notify
- Hooks run automatically without Claude needing to decide
- Users can enable one or both depending on their needs
- Hook scripts are simple shell scripts (no Node.js runtime needed)
- MCP server enables richer integration (structured input, validation)

## Trade-offs

- Two configuration points (MCP config + hooks config)
- Hook scripts duplicate some logic (env var reading, curl calls)
- Hooks can't access MCP server state (they're independent processes)
