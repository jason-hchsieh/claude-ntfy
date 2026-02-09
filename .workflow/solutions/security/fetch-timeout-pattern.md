---
category: solution
problem: "Adding timeout to native fetch() calls"
tags: [fetch, timeout, node, security]
confidence: high
created: 2026-02-09
---

# Fetch Timeout with AbortController

## Problem

Native `fetch()` has no built-in timeout. An unresponsive server causes indefinite hangs.

## Solution

```typescript
const TIMEOUT_MS = 10_000;

async function fetchWithTimeout(url: string, init: RequestInit): Promise<Response> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const response = await fetch(url, { ...init, signal: controller.signal });
    return response;
  } catch (error) {
    if (error instanceof DOMException && error.name === "AbortError") {
      throw new Error(`Request timed out after ${TIMEOUT_MS}ms`);
    }
    throw error;
  } finally {
    clearTimeout(timeout);
  }
}
```

## Key Points

- Always `clearTimeout` in `finally` to avoid leaks
- Catch `AbortError` by checking `error.name === "AbortError"` (it's a `DOMException`)
- Re-throw non-abort errors unchanged
