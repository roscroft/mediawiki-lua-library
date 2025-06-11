# Development Guide

Complete guide for developing with the MediaWiki Lua Module Library.

## Project Architecture

### Repository Structure

```text
├── src/modules/           # Source code (authoritative files)
├── build/modules/         # Build artifacts (symlinks for MediaWiki)
├── scripts/               # Core development scripts (unified)
├── tests/                 # Comprehensive test suite
├── examples/              # Usage examples and demos
└── .github/workflows/     # CI/CD automation
```

### Key Principles

- **Source of Truth**: `src/modules/` contains authoritative code
- **Unified Scripts**: Consolidated tools replace multiple variants
- **Clean History**: Temporary files and completed migrations removed

## Development Workflow

### VS Code Integration (Recommended)

1. **Start MediaWiki**: `Ctrl+Shift+P` → "Tasks: Run Task" → "Start MediaWiki Container"
2. **View Dashboard**: `Ctrl+Shift+P` → "Tasks: Run Task" → "View Performance Dashboard" 
3. **Auto-fix Code**: `Ctrl+Shift+P` → "Tasks: Run Task" → "Auto-fix Lua and Markdown"
4. **Run Tests**: `Ctrl+Shift+T` (or use "Run Test Pipeline" task)

### Command Line Workflow

```bash
# Development environment
make setup                    # First-time setup
make fix                     # Auto-fix linting issues
make test                    # Run test pipeline
make lint                    # Run linters only

# GitHub Actions related
make ci-test                 # Run CI pipeline locally (fast)
make ci-local                # Run full CI pipeline with Docker
make validate-workflows      # Validate GitHub Actions workflows

# Individual operations
./scripts/auto-fix.sh        # Auto-fix Lua and Markdown
bash tests/scripts/test-pipeline.sh  # Run tests
docker stop mediawiki-lua    # Stop MediaWiki container
```

## Module Development

### Core Modules

- **Array.lua** - Functional array operations
- **Functools.lua** - Functional programming library
- **CodeStandards.lua** - Error handling and monitoring
- **PerformanceDashboard.lua** - Performance visualization

### Development Patterns

- **Functional Programming**: Pure functions, combinators, monads
- **Error Handling**: Standardized error management
- **Performance Monitoring**: Real-time metrics and visualization
- **Testing**: 4-stage test pipeline with Docker integration

For more details, see [Testing](Testing) and [Security](Security) guides.
