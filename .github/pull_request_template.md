## 📋 Pull Request Description

### Summary
<!-- Provide a brief summary of what this PR accomplishes -->

### Type of Change
<!-- Mark the relevant option with an [x] -->
- [ ] 🐛 Bug fix (non-breaking change that fixes an issue)
- [ ] ✨ New feature (non-breaking change that adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update (improves or adds to documentation)
- [ ] 🔧 Code refactoring (no functional changes)
- [ ] 🧪 Test improvements (adds or improves tests)
- [ ] 🚀 Performance improvement (improves performance without changing functionality)
- [ ] 🔒 Security fix (addresses security vulnerabilities)

### Related Issues
<!-- Link any related GitHub issues -->
Fixes #(issue_number)
Relates to #(issue_number)

## Changes Made
<!-- Describe the specific changes made -->
-
-
-

## 🧪 Testing & Validation

### Required CI Checks
<!-- These must pass before merge -->
- [ ] **Syntax Validation & Linting** - Lua syntax and style checks
- [ ] **Basic Execution Testing** - Module compilation and unit tests  
- [ ] **Mocked Environment Testing** - Docker-based testing
- [ ] **Scribunto Integration Testing** - Full MediaWiki integration

### Manual Testing
- [ ] Local tests pass (`make test`)
- [ ] Linting passes (`make lint`) 
- [ ] CI pipeline passes locally (`make ci-test`)
- [ ] Performance testing (if applicable)

### Test Evidence
<!-- Include command output or screenshots -->
```bash
# Paste test command output here
```

## 🔒 Security & Quality

### Security Checklist
- [ ] No hardcoded secrets or credentials
- [ ] Input validation implemented for new functions
- [ ] Error handling follows CodeStandards.lua patterns
- [ ] No sensitive data in commit history

### Code Quality
<!-- Verify code quality standards -->
- [ ] Code follows the project's style guidelines
- [ ] Self-review of the code performed
- [ ] Code is well-commented, particularly in hard-to-understand areas
- [ ] No debug print statements or commented-out code left in

## Documentation
<!-- Ensure documentation is updated -->
- [ ] Documentation has been updated (if needed)
- [ ] README.md updated (if needed)
- [ ] API documentation updated (if applicable)
- [ ] Examples updated (if applicable)

## Backward Compatibility
<!-- Consider impact on existing users -->
- [ ] This change is backward compatible
- [ ] Breaking changes are documented
- [ ] Migration guide provided (if applicable)
- [ ] Deprecation warnings added (if applicable)

## Performance Impact
<!-- Consider performance implications -->
- [ ] No performance impact
- [ ] Performance improved
- [ ] Performance impact acceptable and documented
- [ ] Performance tests included

## Security Considerations
<!-- Security review -->
- [ ] No security implications
- [ ] Security implications reviewed and documented
- [ ] No sensitive data exposed
- [ ] Input validation added (if applicable)

## Additional Notes
<!-- Any additional information that reviewers should know -->

## Screenshots/Examples
<!-- If applicable, add screenshots or code examples -->

```lua
-- Example of new functionality
local result = NewModule.newFunction({
    parameter = "value"
})
```

## Checklist for Reviewers
<!-- For reviewers to use -->
- [ ] Code review completed
- [ ] Tests reviewed and adequate
- [ ] Documentation reviewed
- [ ] No obvious security issues
- [ ] Performance considerations reviewed
