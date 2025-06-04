--[[
Simplified Comprehensive Integration Tests for Enhanced Wiki Lua Project
(AdvancedFunctional module removed during API migration)

This test suite validates the integration and interaction between the remaining modules
in the enhanced Wiki Lua project after the forcible API migration.

Test Coverage:
- Cross-module integration
- Basic functional programming workflows  
- Error handling standardization
- Real-world usage scenarios with remaining modules

@module test_integration_simplified
@author Wiki Lua Team
@license MIT
@version 1.0.0
]]

-- Setup proper paths for module loading
package.path = package.path .. ';src/modules/?.lua'

-- Load environment setup
dofile('tests/env/wiki-lua-env.lua')

-- Module imports with proper paths
local Array = require('src/modules/Array')
local functools = require('src/modules/Functools')
local funclib = require('src/modules/Funclib')
local standards = require('src/modules/CodeStandards')
-- Note: AdvancedFunctional module has been removed as part of API migration

-- Test framework
local test = {}
local passed = 0
local failed = 0

local function assert_equal(actual, expected, message)
    if actual == expected then
        passed = passed + 1
        print("✓ PASS: " .. (message or "values equal"))
    else
        failed = failed + 1
        print("✗ FAIL: " .. (message or "values not equal"))
        print(string.format("  Expected: %s", tostring(expected)))
        print(string.format("  Actual: %s", tostring(actual)))
    end
end

local function assert_true(condition, message)
    if condition then
        passed = passed + 1
        print("✓ PASS: " .. (message or "condition true"))
    else
        failed = failed + 1
        print("✗ FAIL: " .. (message or "condition false"))
    end
end

-- Start tests
print("=== COMPREHENSIVE INTEGRATION TESTS ===")
print("Testing integration between Array, Functools, Funclib, and CodeStandards")
print("Note: AdvancedFunctional module removed during API migration")

-- ======================
-- Array + Functools Integration
-- ======================
print("\n--- Array + Functools Integration ---")

local arr = Array.new({1, 2, 3, 4, 5})
local double = function(x) return x * 2 end
local is_even = function(x) return x % 2 == 0 end

-- Test array operations with functional composition
local doubled_arr = arr:map(double)
assert_equal(doubled_arr:get(1), 2, "Array map with function")
assert_equal(doubled_arr:get(3), 6, "Array map preserves order")

local even_arr = arr:filter(is_even)
assert_equal(even_arr:get(1), 2, "Array filter works correctly")
assert_equal(even_arr:get(2), 4, "Array filter preserves filtered items")

-- ======================
-- CodeStandards Integration
-- ======================
print("\n--- CodeStandards Integration ---")

-- Test error handling
local test_error = standards.createError(standards.ERROR_LEVELS.WARNING, "Test warning", "test_module")
assert_equal(test_error.level, 2, "Error object created with correct level")
assert_equal(test_error.message, "Test warning", "Error object has correct message")

-- Test validation
local valid, error_msg = standards.validateParameters("test_func", {
    {name = "param1", type = "number", required = true},
    {name = "param2", type = "string", required = false}
}, {42, "hello"})
assert_true(valid, "Parameter validation passes for valid inputs")

local invalid, invalid_msg = standards.validateParameters("test_func", {
    {name = "param1", type = "number", required = true}
}, {})
assert_true(not invalid, "Parameter validation fails for missing required param")

-- ======================
-- Funclib Integration  
-- ======================
print("\n--- Funclib Integration ---")

-- Test some funclib functions
local test_str = "  hello world  "
local trimmed = funclib.trim(test_str)
assert_equal(trimmed, "hello world", "Funclib trim function works")

-- Test funclib with arrays
local test_table = {a = 1, b = 2, c = 3}
local keys = funclib.keys(test_table)
assert_true(#keys == 3, "Funclib keys function returns correct count")

-- ======================
-- Combined Workflow Test
-- ======================
print("\n--- Combined Workflow Test ---")

-- Create a simple data processing workflow
local process_data = function(data)
    local arr = Array.new(data)
    local doubled = arr:map(function(x) return x * 2 end)
    local filtered = doubled:filter(function(x) return x > 5 end)
    return filtered:totable()
end

local test_data = {1, 2, 3, 4, 5}
local result = process_data(test_data)
-- Should be: {1*2, 2*2, 3*2, 4*2, 5*2} = {2, 4, 6, 8, 10}, then filter > 5 = {6, 8, 10}
assert_equal(#result, 3, "Combined workflow produces expected count")
assert_equal(result[1], 6, "Combined workflow produces expected first value")

-- ======================
-- Function Composition Test
-- ======================
print("\n--- Function Composition Test ---")

-- Test functools composition
local add_one = function(x) return x + 1 end
local multiply_two = function(x) return x * 2 end
local composed = functools.compose(multiply_two, add_one)
assert_equal(composed(5), 12, "Function composition works correctly") -- (5+1)*2 = 12

-- ======================
-- Test Results
-- ======================
print("\n=== TEST RESULTS ===")
print(string.format("Passed: %d", passed))
print(string.format("Failed: %d", failed))
print(string.format("Total: %d", passed + failed))

if failed == 0 then
    print("✓ ALL TESTS PASSED!")
    print("✅ Cross-module integration verified")
    print("✅ Basic functional programming workflows operational")  
    print("✅ Error handling standardized")
    print("Note: AdvancedFunctional tests removed due to module deletion")
    return true
else
    print("✗ SOME TESTS FAILED!")
    return false
end
