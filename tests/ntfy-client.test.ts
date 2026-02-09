import { describe, it, expect, vi, beforeEach } from "vitest";
import { NtfyClient } from "../src/ntfy-client.js";
import type { NtfyConfig } from "../src/types.js";

describe("NtfyClient", () => {
  let client: NtfyClient;
  const baseConfig: NtfyConfig = {
    serverUrl: "https://ntfy.example.com",
    topic: "test-topic",
  };

  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it("sends a POST request to the correct URL", async () => {
    const mockFetch = vi.fn().mockResolvedValue({ ok: true });
    vi.stubGlobal("fetch", mockFetch);

    client = new NtfyClient(baseConfig);
    await client.publish({ message: "Hello" });

    expect(mockFetch).toHaveBeenCalledOnce();
    const [url] = mockFetch.mock.calls[0];
    expect(url).toBe("https://ntfy.example.com/test-topic");
  });

  it("sends message as request body", async () => {
    const mockFetch = vi.fn().mockResolvedValue({ ok: true });
    vi.stubGlobal("fetch", mockFetch);

    client = new NtfyClient(baseConfig);
    await client.publish({ message: "Test message" });

    const [, options] = mockFetch.mock.calls[0];
    expect(options.method).toBe("POST");
    expect(options.body).toBe("Test message");
  });

  it("includes title header when title is provided", async () => {
    const mockFetch = vi.fn().mockResolvedValue({ ok: true });
    vi.stubGlobal("fetch", mockFetch);

    client = new NtfyClient(baseConfig);
    await client.publish({ title: "My Title", message: "Body" });

    const [, options] = mockFetch.mock.calls[0];
    expect(options.headers["Title"]).toBe("My Title");
  });

  it("does not include title header when title is omitted", async () => {
    const mockFetch = vi.fn().mockResolvedValue({ ok: true });
    vi.stubGlobal("fetch", mockFetch);

    client = new NtfyClient(baseConfig);
    await client.publish({ message: "No title" });

    const [, options] = mockFetch.mock.calls[0];
    expect(options.headers["Title"]).toBeUndefined();
  });

  it("includes Authorization header when token is configured", async () => {
    const mockFetch = vi.fn().mockResolvedValue({ ok: true });
    vi.stubGlobal("fetch", mockFetch);

    client = new NtfyClient({ ...baseConfig, token: "tk_secret" });
    await client.publish({ message: "Authed" });

    const [, options] = mockFetch.mock.calls[0];
    expect(options.headers["Authorization"]).toBe("Bearer tk_secret");
  });

  it("does not include Authorization header when no token", async () => {
    const mockFetch = vi.fn().mockResolvedValue({ ok: true });
    vi.stubGlobal("fetch", mockFetch);

    client = new NtfyClient(baseConfig);
    await client.publish({ message: "No auth" });

    const [, options] = mockFetch.mock.calls[0];
    expect(options.headers["Authorization"]).toBeUndefined();
  });

  it("throws on non-ok response", async () => {
    const mockFetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 403,
      statusText: "Forbidden",
    });
    vi.stubGlobal("fetch", mockFetch);

    client = new NtfyClient(baseConfig);

    await expect(client.publish({ message: "Fail" })).rejects.toThrow("403");
  });

  it("passes an AbortSignal to fetch for timeout", async () => {
    const mockFetch = vi.fn().mockResolvedValue({ ok: true });
    vi.stubGlobal("fetch", mockFetch);

    client = new NtfyClient(baseConfig);
    await client.publish({ message: "Hello" });

    const [, options] = mockFetch.mock.calls[0];
    expect(options.signal).toBeInstanceOf(AbortSignal);
  });

  it("throws on fetch abort (timeout)", async () => {
    const mockFetch = vi.fn().mockRejectedValue(new DOMException("The operation was aborted", "AbortError"));
    vi.stubGlobal("fetch", mockFetch);

    client = new NtfyClient(baseConfig);

    await expect(client.publish({ message: "Slow" })).rejects.toThrow("timed out");
  });

  it("URL-encodes the topic", async () => {
    const mockFetch = vi.fn().mockResolvedValue({ ok: true });
    vi.stubGlobal("fetch", mockFetch);

    client = new NtfyClient({ ...baseConfig, topic: "my topic/special" });
    await client.publish({ message: "Hello" });

    const [url] = mockFetch.mock.calls[0];
    expect(url).toBe("https://ntfy.example.com/my%20topic%2Fspecial");
  });
});
