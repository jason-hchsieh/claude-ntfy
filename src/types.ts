export interface NtfyConfig {
  serverUrl: string;
  topic: string;
  token?: string;
}

export interface NtfyMessage {
  title?: string;
  message: string;
}
