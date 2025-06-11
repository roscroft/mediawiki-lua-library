# Testing Guide

Comprehensive testing framework for the MediaWiki Lua Module Library.

## Test Pipeline Overview

The project uses a 4-stage test pipeline:

1. **Syntax Validation**: Lua syntax checking and linting
2. **Basic Execution**: Module compilation and unit tests  
3. **Mocked Environment**: Docker-based MediaWiki environment testing
4. **Scribunto Integration**: Full MediaWiki + Scribunto integration testing

## Running Tests

### Quick Test Commands

```bash
# Run full test pipeline
bash tests/scripts/test-pipeline.sh

# Run specific test stages
lua scripts/test-unified.lua --suite=core
lua scripts/test-unified.lua --suite=integration
lua scripts/test-unified.lua --suite=all

# Using VS Code
# Ctrl+Shift+P → "Tasks: Run Task" → "Run Tests (Unified)"
```

### Test Suites Available

- **Core Functional Patterns**: Basic functionality tests
- **Functional Patterns Validation**: Advanced pattern tests
- **Module Integration Tests**: Cross-module compatibility
- **Dependencies Simplification**: Dependency resolution tests

## Test Structure

```text
tests/
├── unit/                  # Unit tests for individual modules
├── integration/           # Integration tests
├── fixtures/              # Test data and mocks
├── scripts/              # Test pipeline scripts
└── run_all_tests.lua     # Main test runner
```

## Writing Tests

### Unit Test Example

```lua
-- Test Array module functionality
local Array = require('Array')

local function test_array_operations()
    local arr = Array:new({1, 2, 3})
    local result = arr:map(function(x) return x * 2 end)
    assert(result[1] == 2, "Array map failed")
    assert(result[2] == 4, "Array map failed")
    assert(result[3] == 6, "Array map failed")
end
```

### Integration Test Example

```lua
-- Test module integration
local function test_module_integration()
    local Array = require('Array')
    local Functools = require('Functools')
    
    local result = Array:new({1,2,3})
        :map(Functools.partial(function(x,y) return x + y end, 10))
    
    assert(result[1] == 11, "Integration failed")
end
```

## Continuous Integration

GitHub Actions automatically runs all tests on:
- Every push to main branch
- Every pull request
- Daily scheduled runs

For CI/CD details, see [GitHub Actions](GitHub-Actions).
