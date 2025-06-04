# Test Suite Documentation

This directory contains the comprehensive test suite for the MediaWiki Lua project.

## Structure

````plaintext
tests/
├── README.md                 # This file
├── env/                      # Test environment setup
│   ├── module-loader.lua     # Module loading utilities
│   └── wiki-lua-env.lua      # MediaWiki environment mock
├── unit/                     # Unit tests for individual modules
│   ├── test_array.lua        # Array module tests
│   ├── test_codestandards.lua # CodeStandards module tests
│   ├── test_funclib.lua      # Funclib module tests
│   ├── test_functools.lua    # Functools module tests
│   └── test_tabletools.lua   # TableTools module tests
├── integration/              # Integration tests
│   ├── test_module_loading.lua  # Module loading integration
│   ├── test_api_compatibility.lua # API compatibility tests
│   └── test_cross_module.lua    # Cross-module interaction tests
├── performance/              # Performance tests
│   └── test_benchmarks.lua   # Performance benchmarks
├── fixtures/                 # Test data and fixtures
│   └── sample_data.lua       # Sample test data
└── scripts/                  # Test automation scripts
    └── run_all_tests.sh      # Main test runner
```plaintext

## Running Tests

### Run All Tests
```bash
cd /home/adher/wiki-lua
bash tests/scripts/run_all_tests.sh
```plaintext

### Run Specific Test Categories
```bash
# Unit tests only
lua tests/unit/test_array.lua

# Integration tests only
lua tests/integration/test_module_loading.lua

# Performance tests only
lua tests/performance/test_benchmarks.lua
```plaintext

## Test Environment

All tests use the MediaWiki environment mock located in `tests/env/wiki-lua-env.lua`. This provides the necessary `mw` and `libraryUtil` globals that MediaWiki modules expect.

## Test Standards

- All test files should be executable standalone
- Use descriptive test names and clear assertions
- Include both positive and negative test cases
- Performance tests should include benchmarks and regression detection
- Integration tests should verify cross-module functionality

## Current API

After the recent migration, modules use the following CodeStandards API:

- `standards.validateParameters(name, parameters, args)` - Parameter validation
- `standards.trackPerformance(name, func)` - Performance monitoring
- `standards.createError(level, message, source, details)` - Error creation
- `standards.ERROR_LEVELS.*` - Error level constants

## Migration Status

✅ **Completed**: Core module migration to new CodeStandards API
✅ **Completed**: Legacy compatibility layer removal
🔄 **In Progress**: Test suite reorganization and modernization
📋 **Pending**: Performance regression testing setup
````
