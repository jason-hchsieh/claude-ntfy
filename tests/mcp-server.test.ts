import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { createServer } from "../src/mcp-server.js";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { Client } from "@modelcontextprotocol/sdk/client";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";

// Mock the NtfyClient
const mockPublish = vi.fn().mockResolvedValue(undefined);
vi.mock("../src/ntfy-client.js", () => ({
  NtfyClient: class {
    publish = mockPublish;
  },
}));

vi.mock("../src/config.js", () => ({
  loadConfig: vi.fn().mockReturnValue({
    serverUrl: "http://localhost:8080",
    topic: "test-topic",
  }),
}));

describe("createServer", () => {
  let server: McpServer;
  let client: Client;

  beforeEach(async () => {
    mockPublish.mockReset().mockResolvedValue(undefined);
    server = createServer();
    client = new Client({ name: "test-client", version: "0.1.0" });
    const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
    await Promise.all([
      server.connect(serverTransport),
      client.connect(clientTransport),
    ]);
  });

  afterEach(async () => {
    await client.close();
    await server.close();
  });

  it("returns an McpServer instance", () => {
    expect(server).toBeInstanceOf(McpServer);
  });

  it("registers the send_notification tool", async () => {
    const { tools } = await client.listTools();
    expect(tools).toHaveLength(1);
    expect(tools[0].name).toBe("send_notification");
  });

  it("sends a notification and returns success", async () => {
    const result = await client.callTool({
      name: "send_notification",
      arguments: { message: "Hello world" },
    });

    expect(mockPublish).toHaveBeenCalledOnce();
    expect(mockPublish).toHaveBeenCalledWith({ message: "Hello world", title: undefined });
    expect(result.isError).toBeFalsy();
    expect(result.content).toEqual([
      { type: "text", text: "Notification sent: Hello world" },
    ]);
  });

  it("includes title when provided", async () => {
    const result = await client.callTool({
      name: "send_notification",
      arguments: { message: "Body text", title: "My Title" },
    });

    expect(mockPublish).toHaveBeenCalledWith({ message: "Body text", title: "My Title" });
    expect(result.content).toEqual([
      { type: "text", text: "Notification sent: My Title" },
    ]);
  });

  it("returns isError when publish fails", async () => {
    mockPublish.mockRejectedValue(new Error("Connection refused"));

    const result = await client.callTool({
      name: "send_notification",
      arguments: { message: "Will fail" },
    });

    expect(result.isError).toBe(true);
    expect(result.content).toEqual([
      { type: "text", text: "Failed to send notification: Connection refused" },
    ]);
  });
});
