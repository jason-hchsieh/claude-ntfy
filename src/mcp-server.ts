import { createRequire } from "node:module";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { NtfyClient } from "./ntfy-client.js";
import { loadConfig } from "./config.js";

const require = createRequire(import.meta.url);
const { version } = require("../package.json") as { version: string };

export function createServer(): McpServer {
  const config = loadConfig();
  const client = new NtfyClient(config);

  const server = new McpServer({
    name: "claude-ntfy",
    version,
  });

  server.registerTool("send_notification", {
    description: "Send a push notification via ntfy",
    inputSchema: {
      message: z.string().min(1).max(4096).describe("The notification message body"),
      title: z.string().max(256).optional().describe("Optional notification title"),
    },
  }, async ({ message, title }) => {
    try {
      await client.publish({ message, title });
      return {
        content: [{ type: "text" as const, text: `Notification sent: ${title ?? message}` }],
      };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : "Unknown error";
      return {
        content: [{ type: "text" as const, text: `Failed to send notification: ${errorMsg}` }],
        isError: true,
      };
    }
  });

  return server;
}
