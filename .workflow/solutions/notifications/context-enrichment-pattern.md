# Solution: Context Enrichment Pattern in Notifications

## Problem

Notification messages that lack contextual information make it difficult to:
- Identify which user/machine triggered the action
- Correlate notifications across multiple systems
- Understand the source of actions in multi-user environments
- Debug issues across distributed teams

## Solution: Add System Context to Messages

Extract and include system context (hostname, username) in notification messages to provide clearer tracking and correlation.

### Implementation Pattern

```bash
# 1. Extract system information
HOSTNAME=$(hostname 2>/dev/null || echo "unknown")
USERNAME=$(whoami 2>/dev/null || echo "unknown")
USER_HOST="${USERNAME}@${HOSTNAME}"

# 2. Include in message title
TITLE="Action on ${USER_HOST}"

# 3. Include in message body
MESSAGE="${MESSAGE}"$'\n'"_${USER_HOST} in ${PROJECT}_"
```

## Key Principles

### 1. Graceful Degradation

Always provide fallback values:

```bash
HOSTNAME=$(hostname 2>/dev/null || echo "unknown")
USERNAME=$(whoami 2>/dev/null || echo "unknown")
```

**Benefits:**
- Script works even if commands fail
- No error logs pollution
- Transparent failure handling
- User sees "unknown" rather than error

### 2. Consistent Format

Use `user@hostname` format across all messages:

```
john@mycomputer
admin@server-01
root@production-node
```

**Why:**
- Familiar format (SSH-like)
- Easy to parse and recognize
- Standard across Unix/Linux communities
- Readable in notifications

### 3. Message Placement Strategy

**In Title:**
```
"Action on user@hostname"
"Permission request from user@hostname"
```

**In Body:**
```
Original message here
_user@hostname in project_
```

**Benefits:**
- Title provides quick identification
- Body maintains detailed context
- Both locations work for different notification clients
- Doesn't break existing message flow

### 4. Context Nesting

For nested contexts, show full path:

```bash
_${USERNAME}@${HOSTNAME} in ${PROJECT}_
```

**Examples:**
- _john@laptop in my-project_
- _admin@server-01 in production-app_
- _unknown@unknown in unknown_

### 5. Handling Special Characters

Sanitize values that might contain special characters:

```bash
# For display in titles (keep simple)
TITLE="Action on ${USER_HOST}"

# For display in body (can use formatting)
MESSAGE="${MESSAGE}"$'\n'"_${USER_HOST}_"
```

**Why:**
- Prevents injection issues
- Maintains message readability
- Handles special characters safely

## Application: claude-ntfy Notifications

### Stop Event
```
Title: Claude Code finished on jasonhch@myhost
Body: Session completed in **project**.
      _jasonhch@myhost_
```

### PermissionRequest Event
```
Title: Claude Code needs permission (jasonhch@myhost)
Body: **tool** needs approval
      _jasonhch@myhost in project_
```

### Notification Event
```
Title: Original Title
Body: Original message
      _jasonhch@myhost in project_
```

## Advantages

1. **Better Traceability** - Know exactly who/where actions came from
2. **Debugging Aid** - Correlate notifications with specific users
3. **Multi-User Safe** - Clear distinction in shared environments
4. **Graceful Degradation** - Works even if commands unavailable
5. **Minimal Overhead** - Simple command execution
6. **No Breaking Changes** - Preserves existing message format
7. **Familiar Format** - Uses standard `user@host` convention

## Disadvantages

1. **Additional Commands** - `hostname` and `whoami` execution (negligible overhead)
2. **Message Length** - Slightly longer notifications
3. **Parsing** - Clients must handle longer titles/messages
4. **Privacy** - Exposes username and hostname (consider environment)

## Mitigation Strategies

### For Message Length
- Keep titles concise
- Put detailed context in body
- Use abbreviations if needed
- Enable message truncation if supported

### For Privacy Concerns
- Consider masking username (e.g., `user-1@host-1`)
- Document that context is included
- Ensure topic/channel is secured
- Add authentication tokens if needed

### For Multiple Systems
- Use consistent hostname format across infrastructure
- Automate hostname standardization
- Consider FQDN (fully qualified domain names)
- Document naming conventions

## Testing Strategy

```bash
# Test with actual values
echo "Hostname: $(hostname)"
echo "Username: $(whoami)"

# Test with missing commands
bash -c "HOME=/tmp whoami 2>/dev/null || echo 'unknown'"

# Test message format
USER_HOST="john@laptop"
PROJECT="my-project"
MESSAGE="Test"$'\n'"_${USER_HOST} in ${PROJECT}_"
echo "$MESSAGE"
```

## When to Use This Pattern

**✓ Good for:**
- Multi-user systems
- Distributed/remote teams
- Debugging and troubleshooting
- Audit trail requirements
- CI/CD notifications
- Scheduled task notifications
- Security event notifications
- Any notification that benefits from source identification

**✗ Avoid for:**
- Highly privacy-sensitive systems
- Anonymous notification requirements
- Very short message limits
- Systems where identity is not relevant

## Variations

### Variation 1: Extended Context

```bash
# Include more details
USER_HOST="${USERNAME}@${HOSTNAME}:${PWD}"
USER_HOST="${USERNAME}@${HOSTNAME} (${SHELL})"
```

### Variation 2: Abbreviated Format

```bash
# Shorter version
USER_HOST="${USERNAME:0:1}@${HOSTNAME:0:8}"  # j@mycompu
```

### Variation 3: Environment-Specific

```bash
# Different format per environment
if [[ "$ENVIRONMENT" == "production" ]]; then
  USER_HOST="[PROD] ${USERNAME}@${HOSTNAME}"
else
  USER_HOST="${USERNAME}@${HOSTNAME}"
fi
```

### Variation 4: Conditional Inclusion

```bash
# Only include if multi-user environment
if [[ $(who | wc -l) -gt 1 ]]; then
  CONTEXT="_${USER_HOST}_"
else
  CONTEXT=""
fi
```

## Related Patterns

- **Message Formatting Pattern** - Consistent notification templates
- **Graceful Degradation Pattern** - Handling missing commands/data
- **Context Enrichment Pattern** - Adding metadata to messages
- **Audit Trail Pattern** - Recording who did what when

## Example: Complete Implementation

```bash
#!/bin/bash

# Extract context
HOSTNAME=$(hostname 2>/dev/null || echo "unknown")
USERNAME=$(whoami 2>/dev/null || echo "unknown")
USER_HOST="${USERNAME}@${HOSTNAME}"
PROJECT=$(pwd | xargs basename)

# Build message
TITLE="Action by ${USER_HOST}"
MESSAGE="Something happened"$'\n'"_${USER_HOST} in ${PROJECT}_"

# Send notification
echo "Title: $TITLE"
echo "Message: $MESSAGE"
```

## Best Practices

1. **Always provide fallbacks** - Use "unknown" rather than errors
2. **Keep format consistent** - Use same format across all messages
3. **Document format** - Add comment explaining the format
4. **Test edge cases** - Ensure graceful degradation works
5. **Consider privacy** - Document what's being captured
6. **Make it optional** - Consider config flag to enable/disable
7. **Monitor overhead** - Ensure minimal performance impact

## Conclusion

The context enrichment pattern provides valuable debugging and traceability information by including hostname and username in notifications. It's a lightweight addition that significantly improves the usefulness of notifications in multi-user and distributed environments.
