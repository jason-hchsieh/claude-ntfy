---
category: solution
problem: "Creating auto-discovered Claude Code plugin skills"
tags: [claude-code, plugin, skills]
confidence: high
created: 2026-02-09
---

# Claude Code Plugin Skill Structure

## Problem

Need to create skills that Claude Code auto-discovers and activates based on task context.

## Solution

### Directory Structure

```
skills/
└── skill-name/
    └── SKILL.md        # Required — must be named exactly SKILL.md
```

### SKILL.md Format

```markdown
---
name: Human-Readable Skill Name
description: Use this skill when the user wants to... Triggers on requests like "keyword1", "keyword2".
version: 1.0.0
---

# Skill Title

Detailed instructions for Claude to follow when this skill activates.

## Steps

### 1. First step
Instructions with bash commands Claude should run...

### 2. Second step
More instructions...
```

## Key Points

- Skills are auto-discovered from `skills/*/SKILL.md` — no manifest registration needed
- The `description` field in frontmatter controls when the skill activates
- Include trigger phrases in the description for better matching
- Skills can reference `$CLAUDE_PLUGIN_ROOT` for portable paths
- Skills can cross-reference other skills by name (e.g., "suggest the **setup-server** skill")
