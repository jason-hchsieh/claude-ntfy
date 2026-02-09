# claude-ntfy

A tool to send notifications from Claude Code sessions.

## Tech Stack

- **Language:** TypeScript
- **Runtime:** Node.js
- **Testing:** Vitest
- **Package Manager:** pnpm

## Commands

```bash
pnpm install         # Install dependencies
pnpm test            # Run tests
pnpm run build       # Build the project
pnpm run lint        # Lint code
```

## Project Structure

```
src/
  index.ts          # MCP server entry point (stdio transport)
  mcp-server.ts     # McpServer with send_notification tool
  ntfy-client.ts    # NtfyClient HTTP client (native fetch)
  config.ts         # Environment variable config loading
  types.ts          # NtfyConfig, NtfyMessage interfaces
tests/              # Test files mirroring src/
hooks/
  notify.sh         # Unified ntfy notification hook (Stop, Notification, PermissionRequest)
  hooks.json        # Plugin hook configuration
skills/
  setup-server/     # Skill: guide ntfy server setup
  test-notification/ # Skill: send test notification
docker/             # Docker compose for self-hosted ntfy
.workflow/          # Mycelium workflow state (do not edit manually)
```

## Key Dependencies

- `@modelcontextprotocol/sdk` — MCP server (import from `server/mcp.js` for McpServer, `server/stdio.js` for StdioServerTransport)
- `zod` — Schema validation for MCP tool inputs

## Conventions

- Write tests first (TDD) — tests go in `tests/` mirroring `src/` structure
- Use ESM imports (`import`/`export`, not `require`)
- Prefer `const` over `let`; avoid `var`
- Use strict TypeScript (`strict: true` in tsconfig)
