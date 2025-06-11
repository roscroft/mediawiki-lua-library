---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: ['bug', 'triage']
assignees: ''
---

## Bug Description

A clear and concise description of what the bug is.

## To Reproduce

Steps to reproduce the behavior:

1. Load module '...'
2. Call function '....'
3. Pass parameters '....'
4. See error

## Expected Behavior

A clear and concise description of what you expected to happen.

## Actual Behavior

What actually happened, including error messages.

## Environment

- **MediaWiki Version**: [e.g., 1.39.0]
- **Scribunto Version**: [e.g., 1.6.0]
- **Lua Version**: [e.g., 5.1.5]
- **Module Version**: [e.g., v1.0.0]
- **Browser**: [if relevant]

## Code Sample

```lua
-- Minimal code example that reproduces the issue
local Array = require('Module:Array')
local arr = Array.new({1, 2, 3})
-- Error occurs here:
local result = arr:someFunction()
```

## Error Output

```
[Include any error messages or stack traces]
```

## Additional Context

Add any other context about the problem here. Screenshots, related issues, etc.

## Checklist

- [ ] I have searched existing issues to ensure this is not a duplicate
- [ ] I have tested this with the latest version
- [ ] I have provided a minimal reproduction case
- [ ] I have included relevant error messages
