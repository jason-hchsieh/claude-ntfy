---
category: solution
problem: "Mocking class constructors in Vitest"
tags: [vitest, testing, mocking]
confidence: high
created: 2026-02-09
---

# Vitest: Mocking Class Constructors

## Problem

When mocking a module that exports a class, using `vi.fn().mockImplementation()` fails with "is not a constructor" in Vitest.

## Anti-Pattern

```typescript
// WRONG — fails with "not a constructor"
vi.mock("../src/my-class.js", () => ({
  MyClass: vi.fn().mockImplementation(() => ({
    method: vi.fn(),
  })),
}));
```

## Solution

Use a real `class` in the mock factory:

```typescript
const mockMethod = vi.fn().mockResolvedValue(undefined);
vi.mock("../src/my-class.js", () => ({
  MyClass: class {
    method = mockMethod;
  },
}));
```

Define `mockMethod` outside the mock factory so tests can access it for assertions and `.mockReset()`.
