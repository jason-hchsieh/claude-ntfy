import type { NtfyConfig } from "./types.js";

const DEFAULT_SERVER_URL = "http://localhost:8080";

export function loadConfig(): NtfyConfig {
  const topic = process.env.NTFY_TOPIC;
  if (!topic) {
    throw new Error("NTFY_TOPIC environment variable is required");
  }

  const rawUrl = (process.env.NTFY_SERVER_URL ?? DEFAULT_SERVER_URL).replace(
    /\/$/,
    ""
  );

  let serverUrl: string;
  try {
    const parsed = new URL(rawUrl);
    if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
      throw new Error(
        `Invalid protocol "${parsed.protocol}" — only http: and https: are allowed`
      );
    }
    serverUrl = rawUrl;
  } catch (error) {
    if (error instanceof TypeError) {
      throw new Error(`Invalid NTFY_SERVER_URL: "${rawUrl}" is not a valid URL`);
    }
    throw error;
  }

  const token = process.env.NTFY_TOKEN || undefined;

  return { serverUrl, topic, token };
}
