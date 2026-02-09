import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { loadConfig } from "../src/config.js";

describe("loadConfig", () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it("loads config from environment variables", () => {
    process.env.NTFY_SERVER_URL = "https://ntfy.example.com";
    process.env.NTFY_TOPIC = "my-topic";
    process.env.NTFY_TOKEN = "tk_secret";

    const config = loadConfig();

    expect(config.serverUrl).toBe("https://ntfy.example.com");
    expect(config.topic).toBe("my-topic");
    expect(config.token).toBe("tk_secret");
  });

  it("uses default server URL when not provided", () => {
    process.env.NTFY_TOPIC = "my-topic";
    delete process.env.NTFY_SERVER_URL;

    const config = loadConfig();

    expect(config.serverUrl).toBe("http://localhost:8080");
  });

  it("throws when NTFY_TOPIC is missing", () => {
    delete process.env.NTFY_TOPIC;

    expect(() => loadConfig()).toThrow("NTFY_TOPIC");
  });

  it("sets token to undefined when not provided", () => {
    process.env.NTFY_TOPIC = "my-topic";
    delete process.env.NTFY_TOKEN;

    const config = loadConfig();

    expect(config.token).toBeUndefined();
  });

  it("strips trailing slash from server URL", () => {
    process.env.NTFY_SERVER_URL = "https://ntfy.example.com/";
    process.env.NTFY_TOPIC = "my-topic";

    const config = loadConfig();

    expect(config.serverUrl).toBe("https://ntfy.example.com");
  });

  it("accepts http:// protocol", () => {
    process.env.NTFY_SERVER_URL = "http://ntfy.local:8080";
    process.env.NTFY_TOPIC = "my-topic";

    const config = loadConfig();

    expect(config.serverUrl).toBe("http://ntfy.local:8080");
  });

  it("accepts https:// protocol", () => {
    process.env.NTFY_SERVER_URL = "https://ntfy.example.com";
    process.env.NTFY_TOPIC = "my-topic";

    const config = loadConfig();

    expect(config.serverUrl).toBe("https://ntfy.example.com");
  });

  it("rejects non-http protocols", () => {
    process.env.NTFY_SERVER_URL = "file:///etc/passwd";
    process.env.NTFY_TOPIC = "my-topic";

    expect(() => loadConfig()).toThrow("http");
  });

  it("rejects invalid URLs", () => {
    process.env.NTFY_SERVER_URL = "not-a-url";
    process.env.NTFY_TOPIC = "my-topic";

    expect(() => loadConfig()).toThrow("Invalid");
  });
});
