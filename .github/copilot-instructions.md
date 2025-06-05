# GitHub Copilot Business Rules & Context

## Project Context
- **Project**: MediaWiki Lua Module Library
- **Purpose**: Functional programming utilities for MediaWiki
- **Language**: Lua 5.1 (MediaWiki compatible)

## Documentation Rules
1. **Always append to existing files** in docs/ directory
2. **Development notes** go to `docs/development-history.md`
3. **Never create new markdown files** in root directory
4. **Use established file structure** in docs/

## Code Standards
- Follow functional programming principles
- Use JSDoc-style type annotations
- Maintain backward compatibility
- Include comprehensive error handling

## Security Requirements
- Never commit secrets or passwords
- Use environment variables for configuration
- Template files for sensitive configurations
- Follow least privilege principle

## File Organization
- Source code: `src/modules/` (authoritative source files)
- Documentation: `docs/`
- Tests: `tests/`
- Scripts: `scripts/`
- Build artifacts: `build/modules/` (symlinks only - DO NOT EDIT)

## Development Rules
- **ALWAYS edit files in `src/modules/`** - these are the authoritative source files
- **NEVER edit files in `build/modules/`** - these are build artifacts (symlinks)
- Use `src/modules/` for all code changes and fixes
- `build/modules/` is automatically generated via symlinks for MediaWiki compatibility
- Do not apply CodeStandards.lua integrations unless specifically requested 