import type { NtfyConfig, NtfyMessage } from "./types.js";

const TIMEOUT_MS = 10_000;

export class NtfyClient {
  private readonly url: string;
  private readonly token?: string;

  constructor(config: NtfyConfig) {
    this.url = `${config.serverUrl}/${encodeURIComponent(config.topic)}`;
    this.token = config.token;
  }

  async publish(message: NtfyMessage): Promise<void> {
    const headers: Record<string, string> = {};

    if (message.title) {
      headers["Title"] = message.title;
    }
    if (this.token) {
      headers["Authorization"] = `Bearer ${this.token}`;
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

    try {
      const response = await fetch(this.url, {
        method: "POST",
        headers,
        body: message.message,
        signal: controller.signal,
      });

      if (!response.ok) {
        throw new Error(
          `ntfy publish failed: ${response.status} ${response.statusText}`
        );
      }
    } catch (error) {
      if (error instanceof DOMException && error.name === "AbortError") {
        throw new Error(`ntfy publish timed out after ${TIMEOUT_MS}ms`);
      }
      throw error;
    } finally {
      clearTimeout(timeout);
    }
  }
}
