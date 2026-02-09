# claude-ntfy

A tool to send notifications from Claude Code sessions.

## Tech Stack

- **Language:** TypeScript
- **Runtime:** Node.js
- **Testing:** Vitest
- **Package Manager:** pnpm

## Commands

```bash
pnpm install         # Install dependencies
pnpm test            # Run tests
pnpm run build       # Build the project
pnpm run lint        # Lint code
```

## Project Structure

```
src/           # Source code
tests/         # Test files
.workflow/     # Mycelium workflow state (do not edit manually)
```

## Conventions

- Write tests first (TDD) — tests go in `tests/` mirroring `src/` structure
- Use ESM imports (`import`/`export`, not `require`)
- Prefer `const` over `let`; avoid `var`
- Use strict TypeScript (`strict: true` in tsconfig)
