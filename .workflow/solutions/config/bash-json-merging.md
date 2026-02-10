# Solution: Safe JSON Merging in Bash

## Problem
Need to merge two JSON objects in bash where:
- Values can contain special characters, quotes, and newlines
- Using `jq --argjson` with shell variables often fails with parsing errors
- Shell variable expansion introduces quoting issues

## Solution: Use Pipe-Based Merging

Instead of passing JSON as `--argjson` arguments, use stdin piping:

```bash
_merge_json_objects() {
  local base="$1"
  local override="$2"

  # Write both JSON objects and merge using jq
  printf '%s\n%s\n' "$base" "$override" | \
    jq -cs '[.[0], .[1]] | .[0] * .[1]'
}
```

### Key Points

1. **Use `printf` instead of `echo`**: Safer variable substitution
2. **Pipe JSON directly to jq**: Avoids --argjson parsing issues
3. **Use `-cs` flags**: Compact output + slurp mode for array input
4. **Array syntax `.[0] * .[1]`**: Merges two objects from piped input

### Advantages

- No shell escaping issues
- Handles JSON with special characters safely
- Simple and maintainable
- Works with multiline JSON
- Compact output

### Disadvantages

- Slightly more overhead than direct --argjson
- Requires jq (but that's already a dependency)
- Not suitable for very large JSON objects

## Alternative Patterns

### Pattern 1: Use Temp Files (Avoided)
```bash
echo "$base" > /tmp/base.json
echo "$override" > /tmp/override.json
jq -s '.[0] * .[1]' /tmp/base.json /tmp/override.json
# Problem: Temp file cleanup complexity
```

### Pattern 2: Use Environment Variables
```bash
base_var="$base" override_var="$override"
jq -n --arg base "$base_var" --arg override "$override_var" \
  '($base | fromjson) * ($override | fromjson)'
# Problem: Requires nested fromjson, complex
```

### Pattern 3: Direct Pipe (Recommended)
```bash
printf '%s\n%s\n' "$base" "$override" | jq -cs '.[0] * .[1]'
# Recommended: Clean, simple, safe
```

## When to Use

- ✓ Merging configuration objects
- ✓ Combining JSON from multiple sources
- ✓ When variables contain user input or special characters
- ✗ When dealing with extremely large JSON (performance critical)
- ✗ In time-critical loops (overhead of piping)

## Testing

Test with edge cases:
```bash
# URLs with special characters
base='{"url":"http://example.com:8080"}'
override='{"url":"http://other.com"}'

# Tokens with special characters
base='{"token":"tk_abc-123_xyz"}'
override='{"token":"tk_new-456_def"}'

# Newlines in values (should work)
base=$'{"msg":"line1\nline2"}'
override='{}'
```

All merge correctly with pipe-based approach.
