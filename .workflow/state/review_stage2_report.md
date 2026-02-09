# Stage 2: Code Quality Review

## Summary

| Priority | Count | Status |
|----------|-------|--------|
| P1 (Critical) | 2 | Must fix |
| P2 (Recommended) | 4 | Should fix |
| P3 (Optional) | 2 | Nice to have |

---

## P1 Issues (Must Fix)

### P1-1: Missing error handling in MCP server tool handler
**File:** `src/mcp-server.ts:21-25`

The tool handler doesn't catch errors from `client.publish()`. If ntfy is unreachable, the error propagates as an unhandled exception instead of returning an `isError` response.

**Fix:** Wrap in try-catch, return `{ isError: true }` on failure.

### P1-2: Missing fetch timeout
**File:** `src/ntfy-client.ts:22-26`

No timeout on the fetch call. If the ntfy server is unresponsive, the MCP server hangs indefinitely, blocking Claude Code.

**Fix:** Add `AbortController` with a 10-second timeout.

---

## P2 Issues (Should Fix)

### P2-1: No input length validation in MCP tool schema
**File:** `src/mcp-server.ts:17-19`

The zod schema accepts any string length. ntfy has a ~4KB message limit. Add `.max(4096)` to message and `.max(256)` to title.

### P2-2: Missing URL protocol validation in config
**File:** `src/config.ts:11`

`NTFY_SERVER_URL` isn't validated to be http/https. Could accept `file://` or other schemes.

### P2-3: Topic not URL-encoded
**File:** `src/ntfy-client.ts:8`

Topic is concatenated directly into the URL without encoding. Special characters in topic name could break the URL.

### P2-4: Insufficient MCP server test coverage
**File:** `tests/mcp-server.test.ts`

Only 1 test (instance creation). Missing tests for tool invocation, error handling, and response format.

---

## P3 Issues (Optional)

### P3-1: Entry point lacks error handling
**File:** `src/index.ts:6-8`

Top-level await without try-catch. Process crashes with unhandled rejection if startup fails.

### P3-2: Hook stderr suppressed
**Files:** `hooks/notify-on-stop.sh:27`, `hooks/notify-on-notification.sh:27`

`>/dev/null 2>&1` suppresses all output, making debugging impossible.

---

## Strengths
- Clean separation of concerns (types, config, client, server)
- Good TypeScript strict mode usage
- Minimal dependencies, no bloat
- Modern Node.js patterns (native fetch, ESM, top-level await)
- Solid test coverage for config (5 tests) and HTTP client (7 tests)
- Well-structured shell scripts with `set -euo pipefail`

---

## Recommendation

**Fix P1 issues before production use.** P2 issues are recommended for a robust v1.0.
