import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { NtfyClient } from "./ntfy-client.js";
import { loadConfig } from "./config.js";

export function createServer(): McpServer {
  const config = loadConfig();
  const client = new NtfyClient(config);

  const server = new McpServer({
    name: "claude-ntfy",
    version: "0.1.0",
  });

  server.registerTool("send_notification", {
    description: "Send a push notification via ntfy",
    inputSchema: {
      message: z.string().describe("The notification message body"),
      title: z.string().optional().describe("Optional notification title"),
    },
  }, async ({ message, title }) => {
    await client.publish({ message, title });
    return {
      content: [{ type: "text" as const, text: `Notification sent: ${title ?? message}` }],
    };
  });

  return server;
}
