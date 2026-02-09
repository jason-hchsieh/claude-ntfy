---
category: anti-pattern
title: "Importing McpServer from wrong path"
severity: high
created: 2026-02-09
---

# Anti-Pattern: Wrong MCP SDK Import Path

## What Goes Wrong

```typescript
// WRONG — McpServer is NOT exported from this path
import { McpServer } from "@modelcontextprotocol/sdk/server";
// Runtime error: McpServer is not a constructor
```

The `@modelcontextprotocol/sdk/server` path only exports the deprecated `Server` class.

## Correct Approach

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
```

## Why This Happens

The SDK's `server/index.js` re-exports from the old API but doesn't include the newer `McpServer` class from `server/mcp.js`. This is a packaging issue in SDK v1.26.0.
