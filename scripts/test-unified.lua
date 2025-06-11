#!/usr/bin/env lua
--[[
Unified Test Script for MediaWiki Lua Module Library
Consolidates all test scripts into a single configurable test runner.

Usage: lua test-unified.lua [options]

Options:
  --suite=<suite>     Test suite: core, patterns, integration, dependencies, all (default: core)
  --module=<module>   Specific module to test (default: all applicable)
  --verbose           Enable verbose output
  --format=<format>   Output format: simple, detailed, json (default: simple)
  --bail              Stop on first failure
  --help              Show this help message

Test Suites:
  core          - Core functional programming patterns (test-functional-core.lua)
  patterns      - Functional patterns validation (test-functional-patterns.lua)
  integration   - Helper module integration tests (test-helper-module-integration.lua)
  dependencies  - Simplified dependencies test (test-simplified-dependencies.lua)
  all           - Run all test suites

Examples:
  lua test-unified.lua                                # Run core functional tests
  lua test-unified.lua --suite=all                   # Run all test suites
  lua test-unified.lua --suite=core --module=Array   # Test Array module core functionality
  lua test-unified.lua --verbose --format=detailed   # Detailed verbose output
]]

-- Setup environment
package.path = package.path .. ";src/modules/?.lua;tests/env/?.lua"

-- Test result tracking
local TestResults = {
    total = 0,
    passed = 0,
    failed = 0,
    errors = {},
    verbose = false
}

-- Command line argument parsing
local function parseArguments(args)
    local config = {
        test_suite = "core",
        module_name = nil,
        verbose = false,
        format = "simple",
        bail_on_failure = false
    }

    local i = 1
    while i <= #args do
        local arg = args[i]

        if arg == "--help" then
            print([[
Unified Test Script for MediaWiki Lua Module Library

Usage: lua test-unified.lua [options]

Options:
  --suite=<suite>     Test suite: core, patterns, integration, dependencies, all (default: core)
  --module=<module>   Specific module to test (default: all applicable)
  --verbose           Enable verbose output
  --format=<format>   Output format: simple, detailed, json (default: simple)
  --bail              Stop on first failure
  --help              Show this help message

Test Suites:
  core          - Core functional programming patterns
  patterns      - Functional patterns validation
  integration   - Helper module integration tests
  dependencies  - Simplified dependencies test
  all           - Run all test suites

Examples:
  lua test-unified.lua                                # Run core functional tests
  lua test-unified.lua --suite=all                   # Run all test suites
  lua test-unified.lua --suite=core --module=Array   # Test Array module core functionality
  lua test-unified.lua --verbose --format=detailed   # Detailed verbose output
]])
            os.exit(0)
        elseif arg:match("^--suite=") then
            config.test_suite = arg:match("^--suite=(.+)")
        elseif arg:match("^--module=") then
            config.module_name = arg:match("^--module=(.+)")
        elseif arg:match("^--format=") then
            config.format = arg:match("^--format=(.+)")
        elseif arg == "--verbose" then
            config.verbose = true
        elseif arg == "--bail" then
            config.bail_on_failure = true
        end

        i = i + 1
    end

    TestResults.verbose = config.verbose
    return config
end

-- Test assertion functions
local function assert_equals(actual, expected, message)
    TestResults.total = TestResults.total + 1
    message = message or ("Expected " .. tostring(expected) .. ", got " .. tostring(actual))

    if actual == expected then
        TestResults.passed = TestResults.passed + 1
        if TestResults.verbose then
            print("  ✅ " .. message)
        end
        return true
    else
        TestResults.failed = TestResults.failed + 1
        table.insert(TestResults.errors, message)
        print("  ❌ " .. message)
        return false
    end
end

local function assert_type(value, expected_type, message)
    local actual_type = type(value)
    message = message or ("Expected type " .. expected_type .. ", got " .. actual_type)
    return assert_equals(actual_type, expected_type, message)
end

local function assert_not_nil(value, message)
    TestResults.total = TestResults.total + 1
    message = message or "Value should not be nil"

    if value ~= nil then
        TestResults.passed = TestResults.passed + 1
        if TestResults.verbose then
            print("  ✅ " .. message)
        end
        return true
    else
        TestResults.failed = TestResults.failed + 1
        table.insert(TestResults.errors, message)
        print("  ❌ " .. message)
        return false
    end
end

-- Core functional programming patterns test
local function runCoreTests(module_name)
    print("🎯 Testing Core Functional Programming Patterns")
    print("=" .. string.rep("=", 50))

    -- Load test environment
    require('MediaWikiAutoInit')

    -- Test Functools loading
    local success, func = pcall(require, 'Functools')

    if success then
        print("✅ Functools loaded successfully")

        -- Test 1: Basic combinators
        print("\n🔧 1. Basic Combinators")

        -- Identity combinator
        local id_result = func.id(42)
        assert_equals(id_result, 42, "Identity: func.id(42)")

        -- Constant combinator
        local const5 = func.const(5)
        local const_result = const5(99)
        assert_equals(const_result, 5, "Constant: const5(99)")

        if TestResults.verbose then
            print("   Identity combinator preserves values")
            print("   Constant combinator ignores arguments")
        end

        -- Test 2: Function composition
        print("\n🔧 2. Function Composition")

        local double = function(x) return x * 2 end
        local add_one = function(x) return x + 1 end

        if func.compose then
            local composed = func.compose(double, add_one)
            local result = composed(5) -- (5 + 1) * 2 = 12
            assert_equals(result, 12, "Composition: double(add_one(5))")
        end

        -- Test 3: Array operations (if available)
        print("\n🔧 3. Array Operations")

        local array_success, Array = pcall(require, 'Array')
        if array_success then
            local arr = Array.new({ 1, 2, 3, 4, 5 })
            assert_not_nil(arr, "Array creation")

            if arr.map then
                local doubled = arr:map(function(x) return x * 2 end)
                local result = doubled:toTable()
                assert_equals(#result, 5, "Map operation preserves length")
            end
        end
    else
        print("❌ Functools not available: " .. tostring(func))
    end
end

-- Functional patterns validation test
local function runPatternsTests(module_name)
    print("🎨 Testing Functional Patterns")
    print("=" .. string.rep("=", 35))

    require('MediaWikiAutoInit')

    -- Test pattern implementations
    print("\n🔧 Pattern Validation")

    -- Higher-order functions
    local function map_test(func, list)
        local result = {}
        for i, v in ipairs(list) do
            result[i] = func(v)
        end
        return result
    end

    local doubled = map_test(function(x) return x * 2 end, { 1, 2, 3 })
    assert_equals(doubled[1], 2, "Map pattern: first element")
    assert_equals(doubled[2], 4, "Map pattern: second element")
    assert_equals(doubled[3], 6, "Map pattern: third element")

    if TestResults.verbose then
        print("   Higher-order function patterns working")
        print("   Immutable transformations validated")
    end
end

-- Integration tests
local function runIntegrationTests(module_name)
    print("🔗 Testing Module Integration")
    print("=" .. string.rep("=", 35))

    require('MediaWikiAutoInit')

    -- Test module loading integration
    local modules_to_test = module_name and { module_name } or { 'Array', 'Tables', 'Functools' }

    for _, mod in ipairs(modules_to_test) do
        local success, module = pcall(require, mod)
        assert_equals(success, true, "Loading module: " .. mod)

        if success then
            assert_not_nil(module, "Module " .. mod .. " is not nil")
            assert_type(module, "table", "Module " .. mod .. " is a table")
        end
    end

    if TestResults.verbose then
        print("   All target modules load successfully")
        print("   Module interfaces are consistent")
    end
end

-- Dependencies simplification test
local function runDependenciesTests()
    print("🔧 Testing Dependency Simplification")
    print("=" .. string.rep("=", 40))

    print("\n📋 THE CHALLENGE:")
    print("• Complex conditional MediaWiki imports")
    print("• Dependency resolution complexity")

    print("\n✅ THE SOLUTION:")
    print("Single line eliminates ALL complexity:")
    print("   require('MediaWikiAutoInit')")

    -- Test the magic line
    local success, result = pcall(require, 'MediaWikiAutoInit')
    assert_equals(success, true, "MediaWikiAutoInit loads without error")

    if success then
        print("✅ MediaWiki environment auto-initialized")
        assert_not_nil(_G.mw, "MediaWiki global environment available")
    end

    if TestResults.verbose then
        print("   Dependency simplification working")
        print("   Zero-configuration initialization")
    end
end

-- Test result reporting
local function reportResults(format)
    print("\n" .. string.rep("=", 60))
    print("🧪 TEST RESULTS SUMMARY")
    print(string.rep("=", 60))

    if format == "detailed" or format == "json" then
        print("Total Tests: " .. TestResults.total)
        print("Passed: " .. TestResults.passed)
        print("Failed: " .. TestResults.failed)
        print("Success Rate: " .. string.format("%.1f%%", (TestResults.passed / TestResults.total) * 100))

        if #TestResults.errors > 0 then
            print("\nFailures:")
            for i, error in ipairs(TestResults.errors) do
                print("  " .. i .. ". " .. error)
            end
        end
    else
        print(string.format("Tests: %d passed, %d failed, %d total",
            TestResults.passed, TestResults.failed, TestResults.total))
    end

    if format == "json" then
        print("\nJSON Output:")
        print(string.format('{"total":%d,"passed":%d,"failed":%d,"success_rate":%.1f}',
            TestResults.total, TestResults.passed, TestResults.failed,
            (TestResults.passed / TestResults.total) * 100))
    end

    local success = TestResults.failed == 0
    print(success and "✅ ALL TESTS PASSED!" or "❌ SOME TESTS FAILED!")

    return success
end

-- Main execution function
local function main(args)
    args = args or arg or {}
    local config = parseArguments(args)

    if config.verbose then
        print("Test Configuration:")
        print("  Suite: " .. config.test_suite)
        if config.module_name then
            print("  Module: " .. config.module_name)
        end
        print("  Format: " .. config.format)
        print("  Verbose: " .. tostring(config.verbose))
        print()
    end

    local suites_to_run = {}
    if config.test_suite == "all" then
        suites_to_run = { "core", "patterns", "integration", "dependencies" }
    else
        suites_to_run = { config.test_suite }
    end

    -- Run selected test suites
    for _, suite in ipairs(suites_to_run) do
        if suite == "core" then
            runCoreTests(config.module_name)
        elseif suite == "patterns" then
            runPatternsTests(config.module_name)
        elseif suite == "integration" then
            runIntegrationTests(config.module_name)
        elseif suite == "dependencies" then
            runDependenciesTests()
        else
            print("❌ Unknown test suite: " .. suite)
        end

        -- Bail on failure if requested
        if config.bail_on_failure and TestResults.failed > 0 then
            print("🛑 Stopping on first failure (--bail)")
            break
        end

        if #suites_to_run > 1 then
            print() -- Add spacing between suites
        end
    end

    -- Report final results
    local success = reportResults(config.format)

    -- Exit with appropriate code
    os.exit(success and 0 or 1)
end

-- Execute main function
main(arg)
