---
category: anti-pattern
title: "Using vi.fn().mockImplementation for class constructors"
severity: medium
created: 2026-02-09
---

# Anti-Pattern: vi.fn() for Class Mocks

## What Goes Wrong

```typescript
vi.mock("../src/my-class.js", () => ({
  MyClass: vi.fn().mockImplementation(() => ({ method: vi.fn() })),
}));
// TypeError: MyClass is not a constructor
```

Vitest validates that mocks used with `new` are actual functions/classes, not spy wrappers.

## Correct Approach

```typescript
const mockMethod = vi.fn();
vi.mock("../src/my-class.js", () => ({
  MyClass: class {
    method = mockMethod;
  },
}));
```
