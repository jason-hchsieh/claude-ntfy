---
category: solution
problem: "Setting up an MCP server in TypeScript with @modelcontextprotocol/sdk v1.26.0"
tags: [mcp, typescript, sdk]
confidence: high
created: 2026-02-09
---

# MCP Server TypeScript Setup

## Problem

The `@modelcontextprotocol/sdk` v1.26.0 has confusing exports. The high-level `McpServer` class is NOT exported from the main `@modelcontextprotocol/sdk/server` path — only the deprecated `Server` class is.

## Solution

### Correct Import Paths

```typescript
// McpServer (high-level, recommended)
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";

// StdioServerTransport (for CLI entry point)
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

// Client + InMemoryTransport (for testing)
import { Client } from "@modelcontextprotocol/sdk/client";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
```

### Wrong Import (common mistake)

```typescript
// WRONG — only exports deprecated Server class
import { McpServer } from "@modelcontextprotocol/sdk/server";
```

### Tool Registration Pattern

```typescript
import { z } from "zod";

server.registerTool("tool_name", {
  description: "Tool description",
  inputSchema: {
    message: z.string().min(1).max(4096).describe("Field description"),
    optionalField: z.string().optional().describe("Optional field"),
  },
}, async ({ message, optionalField }) => {
  // Always wrap in try-catch for graceful error handling
  try {
    // ... tool logic
    return {
      content: [{ type: "text" as const, text: "Success message" }],
    };
  } catch (error) {
    const msg = error instanceof Error ? error.message : "Unknown error";
    return {
      content: [{ type: "text" as const, text: `Failed: ${msg}` }],
      isError: true,
    };
  }
});
```

### Testing with InMemoryTransport

```typescript
const server = createServer();
const client = new Client({ name: "test-client", version: "0.1.0" });
const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();

await Promise.all([
  server.connect(serverTransport),
  client.connect(clientTransport),
]);

// Now use client.listTools(), client.callTool(), etc.
```

## Key Dependencies

- `@modelcontextprotocol/sdk` — MCP server SDK
- `zod` — required peer dependency for input schema validation
