import { describe, it, expect, vi, beforeEach } from "vitest";
import { createServer } from "../src/mcp-server.js";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";

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
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it("returns an McpServer instance", () => {
    const server = createServer();
    expect(server).toBeInstanceOf(McpServer);
  });
});
