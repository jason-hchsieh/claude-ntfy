#!/usr/bin/env node

import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { createServer } from "./mcp-server.js";

try {
  const server = createServer();
  const transport = new StdioServerTransport();
  await server.connect(transport);
} catch (error) {
  console.error("Failed to start claude-ntfy MCP server:", error);
  process.exit(1);
}
