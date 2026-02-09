import type { NtfyConfig } from "./types.js";

const DEFAULT_SERVER_URL = "http://localhost:8080";

export function loadConfig(): NtfyConfig {
  const topic = process.env.NTFY_TOPIC;
  if (!topic) {
    throw new Error("NTFY_TOPIC environment variable is required");
  }

  const serverUrl = (process.env.NTFY_SERVER_URL ?? DEFAULT_SERVER_URL).replace(
    /\/$/,
    ""
  );
  const token = process.env.NTFY_TOKEN || undefined;

  return { serverUrl, topic, token };
}
