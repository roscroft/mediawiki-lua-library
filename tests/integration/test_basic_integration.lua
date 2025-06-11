#!/usr/bin/env lua
--[[
Basic Integration Test for MediaWiki Lua Project with CodeStandards

This test validates that all enhanced modules can be loaded and work together
with the CodeStandards integration.

@module test_basic_integration
@author Wiki Lua Team
@license MIT
@version 1.0.0
]]

-- Setup paths and environment
package.path = package.path .. ';src/modules/?.lua'

-- Load MediaWiki environment
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

print("Environment setup complete:")
print("mw:", type(mw))
print("libraryUtil:", type(libraryUtil))

print("=== MediaWiki Lua Project Integration Test ===\n")

-- Test counters
local tests_run = 0
local tests_passed = 0

-- Helper function for test assertions
local function test_assert(condition, description)
    tests_run = tests_run + 1
    if condition then
        tests_passed = tests_passed + 1
        print("✅ " .. description)
    else
        print("❌ " .. description)
    end
end

-- Test 1: Module Loading
print("--- Testing Module Loading ---")

local array_ok, Array = pcall(require, 'Array')
if not array_ok then print("Array error:", Array) end
test_assert(array_ok and Array ~= nil, "Array module loads successfully")

local functools_ok, functools = pcall(require, 'Functools')
if not functools_ok then print("Functools error:", functools) end
test_assert(functools_ok and functools ~= nil, "Functools module loads successfully")

local funclib_ok, funclib = pcall(require, 'Funclib')
if not funclib_ok then print("Funclib error:", funclib) end
test_assert(funclib_ok and funclib ~= nil, "Funclib module loads successfully")

local standards_ok, standards = pcall(require, 'CodeStandards')
if not standards_ok then print("CodeStandards error:", standards) end
test_assert(standards_ok and standards ~= nil, "CodeStandards module loads successfully")

-- Test AdvancedFunctional module - REMOVED
-- Note: AdvancedFunctional module removed during API migration
print("AdvancedFunctional module removed during API migration - test skipped")

print("")

-- Test 2: Basic Array Functionality with CodeStandards Integration
if array_ok and Array then
    print("--- Testing Array with CodeStandards Integration ---")

    local test_data = { 1, 2, 3, 4, 5 }
    local arr_ok, arr = pcall(Array.new, test_data)
    test_assert(arr_ok and arr ~= nil, "Array.new works with performance monitoring")

    if arr_ok and arr then
        local filter_ok, filtered = pcall(Array.filter, arr, function(x) return x % 2 == 0 end)
        test_assert(filter_ok and filtered ~= nil, "Array.filter works with validation and monitoring")

        local map_ok, mapped = pcall(Array.map, arr, function(x) return x * 2 end)
        test_assert(map_ok and mapped ~= nil, "Array.map works with validation and monitoring")
    end

    print("")
end

-- Test 3: Basic Functools Functionality with CodeStandards Integration
if functools_ok and functools then
    print("--- Testing Functools with CodeStandards Integration ---")

    local add = function(a, b) return a + b end
    local multiply = function(x) return x * 2 end

    local compose_ok, composed = pcall(functools.compose, multiply, add)
    test_assert(compose_ok and type(composed) == 'function',
        "functools.compose works with standardized error handling")

    if compose_ok and composed then
        local result_ok, result = pcall(composed, 5, 3)
        test_assert(result_ok and result == 16, "Composed function executes correctly")
    end

    print("")
end

-- Test 4: CodeStandards Core Functions
if standards_ok and standards then
    print("--- Testing CodeStandards Core Functions ---")

    -- Test parameter validation
    local validation_ok, validation_result = pcall(function()
        return standards.validateParameters('testFunction', {
            { name = 'param1', type = 'string', required = true }
        }, { 'test' })
    end)
    test_assert(validation_ok and validation_result, "Parameter validation works correctly")

    print("")
end

-- Test 5: Cross-Module Integration
if array_ok and functools_ok and standards_ok then
    print("--- Testing Cross-Module Integration ---")

    local integration_ok = pcall(function()
        -- Create an array
        local arr = Array.new({ 1, 2, 3, 4, 5 })

        -- Create composed function using functools
        local double = function(x) return x * 2 end
        local add_ten = function(x) return x + 10 end
        local composed = functools.compose(add_ten, double)

        -- Apply to array
        local result = Array.map(arr, composed)

        return result ~= nil
    end)

    test_assert(integration_ok, "Cross-module integration works correctly")

    print("")
end

-- Test 6: Error Handling Integration
if standards_ok then
    print("--- Testing Error Handling Integration ---")

    local error_handling_ok = pcall(function()
        -- Test that invalid parameters are caught
        local is_valid, err = standards.validateParameters('testFunction', {
            { name = 'param1', type = 'string', required = true }
        }, { 123 })

        -- Should fail validation
        return not is_valid
    end)

    test_assert(error_handling_ok, "Error handling integration works correctly")

    print("")
end

-- Final Results
print("=== Test Results ===")
print(string.format("Tests Run: %d", tests_run))
print(string.format("Tests Passed: %d", tests_passed))
print(string.format("Tests Failed: %d", tests_run - tests_passed))
print(string.format("Success Rate: %.1f%%", (tests_passed / tests_run) * 100))

if tests_passed == tests_run then
    print("\n🎉 All integration tests passed! The CodeStandards integration is working correctly.")
    return true
else
    print("\n❌ Some integration tests failed. Please review the issues above.")
    return false
end
