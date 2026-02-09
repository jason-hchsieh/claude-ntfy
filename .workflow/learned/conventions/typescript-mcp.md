---
category: convention
title: "TypeScript MCP server conventions"
created: 2026-02-09
---

# TypeScript MCP Server Conventions

## Import Paths

Always use the specific subpath imports for MCP SDK v1.26.0:

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
```

## Tool Error Handling

Always wrap tool handlers in try-catch and return `isError: true`:

```typescript
async (args) => {
  try {
    // ... logic
    return { content: [{ type: "text" as const, text: "OK" }] };
  } catch (error) {
    return {
      content: [{ type: "text" as const, text: `Failed: ${error.message}` }],
      isError: true,
    };
  }
}
```

## Input Validation

Use zod `.min()` / `.max()` constraints on all string inputs to prevent abuse:

```typescript
inputSchema: {
  message: z.string().min(1).max(4096),
  title: z.string().max(256).optional(),
}
```

## HTTP Clients

- Use native `fetch()` (Node 22+) — no extra dependencies
- Always add `AbortController` timeout (10s default)
- URL-encode user-provided path segments with `encodeURIComponent()`
- Validate URL protocols (http/https only)

## Testing

- Use `InMemoryTransport` + `Client` for MCP server integration tests
- Use `class` syntax (not `vi.fn().mockImplementation()`) for mocking constructors
