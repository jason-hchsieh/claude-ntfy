# Solution: Interactive User Choice Pattern in Skills

## Problem

Creating a skill that:
- Presents multiple scenarios to the user
- Guides different workflows based on user choice
- Provides step-by-step instructions for each path
- Remains readable and maintainable

## Solution: Scenario-Based Structure

Organize skill as distinct scenarios with clear branching logic:

```markdown
# Skill Title

## Step 1: Clarify Choice

Ask the user which applies:

```
Which scenario applies to you?

1. New Setup
2. Existing Setup
3. Alternative Option

Please choose: 1, 2, or 3
```

## Scenario 1: New Setup

### Step 1.1: First Action
[Instructions]

### Step 1.2: Second Action
[Instructions]

## Scenario 2: Existing Setup

### Step 2.1: First Action
[Instructions]

### Step 2.2: Second Action
[Instructions]

## Scenario 3: Alternative Option

[Instructions]
```

## Key Principles

### 1. Clear Choice Menu

Present numbered options with descriptions:

```
1. New Server Setup
   → Start a self-hosted server using Docker
   → Good for: Local development

2. Existing Server
   → Configure to use existing server
   → Good for: Production setups

3. Public Service
   → Use public service (no setup)
   → Good for: Quick testing

Please choose: 1, 2, or 3
```

**Why this works:**
- Numbers make it easy to reference
- Descriptions help user decide
- Use cases clarify when to use each

### 2. Scenario-Specific Steps

After user chooses, show numbered steps:

```
## Scenario 1: New Server Setup

### Step 1.1: Check Prerequisites
[Instructions]

### Step 1.2: Start Server
[Instructions]

### Step 1.3: Verify Installation
[Instructions]
```

**Why this works:**
- Consistent numbering (scenario.step)
- Each step is atomic and testable
- Easy to follow sequentially

### 3. Configuration Options

When offering choices, explain each option:

```
How would you like to configure?

A. Environment Variables
   export VAR="value"
   → Temporary, for this session

B. Config File
   Create ~/.config/file.json
   → Persistent, reusable

C. Skip Configuration
   Use defaults
   → Simplest, may not work for all

Please choose: A, B, or C
```

**Benefits:**
- Each option has clear use case
- User understands trade-offs
- Letter-based selection is intuitive

### 4. Code Blocks for Actions

Show exact commands users should run:

```bash
# Check if installed
docker --version

# Start the service
docker compose up -d

# Verify it works
curl http://localhost:8080/health
```

**Best practices:**
- Include verification commands
- Show expected output
- Provide troubleshooting hints

### 5. Format Specifications

When showing file formats, provide examples:

```json
{
  "server_url": "http://localhost:8080",
  "topic": "claude-alerts",
  "token": "tk_optional"
}
```

**Include:**
- Full example with all fields
- Explanation of each field
- Optional vs required indicators

### 6. Verification Checklists

After setup, provide verification:

```
After setup, verify:

- [ ] Server is running/reachable
- [ ] Configuration loaded correctly
- [ ] Required fields are set
- [ ] Plugin is installed
- [ ] First notification sends successfully
```

**Why:**
- Confirms setup is complete
- Catches common issues
- Provides next steps

### 7. Troubleshooting Guide

Include common issues at the end:

```
## Troubleshooting

### Configuration not being recognized
- Check precedence: env vars > project > user > defaults
- Verify files exist and have correct format
- Test with `echo $VARIABLE`

### Connection issues
- Test connectivity manually
- Check port availability
- Review server logs

### Authentication failures
- Verify token format
- Check token expiration
- Review server authentication settings
```

**Structure:**
- Problem heading
- Check points (bullets)
- Example commands where helpful

## Pattern: Multiple Configuration Methods

When supporting multiple ways to configure:

```
### Configuration Methods

1. **Environment Variables** (temporary)
   - Set in current shell
   - Highest precedence
   - Good for testing

2. **User Config** (persistent)
   - Stored in home directory
   - Survives shell restarts
   - Good for development

3. **Project Config** (team-shared)
   - Stored in project root
   - Shared with team
   - Good for production

### Configuration Precedence

1. Environment variables (highest)
2. Project config
3. User config
4. Defaults (lowest)
```

**Benefits:**
- User understands all options
- Clear precedence rules
- Guides selection

## Pattern: File Format Reference

When documenting configuration files:

```
### Global User Config (~/.config/app.json)

```json
{
  "setting1": "value1",
  "setting2": "value2"
}
```

### Project Config (./config.json)

```json
{
  "project_setting": "value"
}
```

### Field Reference

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| setting1 | Yes | — | Does X |
| setting2 | No | default | Does Y |
```

**Includes:**
- Multiple examples
- Clear differences
- Field documentation

## When to Use This Pattern

**✓ Good for:**
- Multi-scenario setups
- Configuration workflows
- User onboarding
- First-time setup guides
- Multiple authentication methods
- Platform selection (Docker, cloud, local, etc.)

**✗ Avoid for:**
- Simple single-path tasks
- API documentation (use API reference instead)
- Detailed technical specs (use separate docs)
- Real-time troubleshooting (use chat)

## Advantages

1. **User-friendly** - Clear choices and paths
2. **Comprehensive** - Covers all scenarios
3. **Maintainable** - Well-organized sections
4. **Accessible** - Works for all skill levels
5. **Actionable** - Contains exact commands
6. **Self-contained** - Includes verification

## Disadvantages

1. **Length** - Can be lengthy for complex scenarios
2. **Maintenance** - Multiple paths to keep in sync
3. **Scrolling** - Users must navigate document
4. **Ambiguity** - User must choose correct path

## Mitigation Strategies

### For length:
- Use section headings extensively
- Provide table of contents
- Link to related documents
- Keep steps concise

### For maintenance:
- Use version numbers (v1.0, v2.0)
- Document breaking changes
- Test all paths regularly
- Version configuration formats

### For navigation:
- Start with clear choice menu
- Use numbered steps consistently
- Provide "Next Steps" section
- Include troubleshooting at end

### For ambiguity:
- Provide clear use cases
- Explain trade-offs
- Show decision tree
- Include "How to choose" section

## Example: Complete Pattern

```markdown
# Setup Guide

## Choose Your Setup Type

1. **Development** - Local setup with Docker
2. **Production** - Connect to existing server
3. **Testing** - Use public service

## Development Setup (Scenario 1)

### Step 1.1: Prerequisites
[Check requirements]

### Step 1.2: Start Server
[Docker commands]

### Step 1.3: Configure
[Environment variables]

## Production Setup (Scenario 2)

### Step 2.1: Server Information
[Gather details]

### Step 2.2: Configuration
[Config file creation]

## Testing Setup (Scenario 3)

### Step 3.1: Quick Start
[Minimal steps]

## Verification

- [ ] Server is accessible
- [ ] Configuration works
- [ ] First operation succeeds

## Troubleshooting

[Common issues and solutions]
```

## Related Patterns

- **Configuration Precedence Pattern** - How to manage multiple config sources
- **Step-by-Step Guide Pattern** - Breaking down sequential tasks
- **Decision Tree Pattern** - Guiding complex choices
- **Troubleshooting Guide Pattern** - Systematic problem-solving
