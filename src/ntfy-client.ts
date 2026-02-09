import type { NtfyConfig, NtfyMessage } from "./types.js";

export class NtfyClient {
  private readonly url: string;
  private readonly token?: string;

  constructor(config: NtfyConfig) {
    this.url = `${config.serverUrl}/${config.topic}`;
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

    const response = await fetch(this.url, {
      method: "POST",
      headers,
      body: message.message,
    });

    if (!response.ok) {
      throw new Error(
        `ntfy publish failed: ${response.status} ${response.statusText}`
      );
    }
  }
}
