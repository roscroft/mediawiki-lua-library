#!/usr/bin/env lua
--[[
Unit Tests for CodeStandards Module
Tests the core CodeStandards functionality including validation, error handling, and performance monitoring
]]

-- Setup test environment
package.path = package.path .. ';src/modules/?.lua'

-- Auto-initialize MediaWiki environment (eliminates conditional imports)
require('MediaWikiAutoInit')

local standards = require('CodeStandards')

-- Simple test framework
local tests_run = 0
local tests_passed = 0

local function test(name, func)
    tests_run = tests_run + 1
    local success, err = pcall(func)
    if success then
        tests_passed = tests_passed + 1
        print("✅ " .. name)
    else
        print("❌ " .. name .. " - " .. tostring(err))
    end
end

local function assert_equal(actual, expected, msg)
    if actual ~= expected then
        error(msg or string.format("Expected %s, got %s", tostring(expected), tostring(actual)))
    end
end

local function assert_not_nil(value, msg)
    if value == nil then
        error(msg or "Value should not be nil")
    end
end

print("=== CodeStandards Module Unit Tests ===\n")

-- Test validateParameters
test("validateParameters with valid parameters", function()
    local valid, msg = standards.validateParameters('testFunction', {
        { name = 'param1', type = 'string', required = true },
        { name = 'param2', type = 'number', required = false }
    }, { 'hello', 42 })

    assert_equal(valid, true)
    assert_equal(msg, nil)
end)

test("validateParameters with missing required parameter", function()
    local valid, msg = standards.validateParameters('testFunction', {
        { name = 'param1', type = 'string', required = true }
    }, {})

    assert_equal(valid, false)
    assert_not_nil(msg)
end)

test("validateParameters with wrong type", function()
    local valid, msg = standards.validateParameters('testFunction', {
        { name = 'param1', type = 'string', required = true }
    }, { 123 })

    assert_equal(valid, false)
    assert_not_nil(msg)
end)

test("validateParameters with optional nil parameter", function()
    local valid, msg = standards.validateParameters('testFunction', {
        { name = 'param1', type = 'string', required = true },
        { name = 'param2', type = 'number', required = false }
    }, { 'hello', nil })

    assert_equal(valid, true)
    assert_equal(msg, nil)
end)

test("validateParameters with custom validation", function()
    local valid, msg = standards.validateParameters('testFunction', {
        {
            name = 'param1',
            type = 'number',
            required = true,
            validate = function(x) return x > 0 end,
            validateMessage = "must be positive"
        }
    }, { 5 })

    assert_equal(valid, true)
    assert_equal(msg, nil)
end)

test("validateParameters with failing custom validation", function()
    local valid, msg = standards.validateParameters('testFunction', {
        {
            name = 'param1',
            type = 'number',
            required = true,
            validate = function(x) return x > 0 end,
            validateMessage = "must be positive"
        }
    }, { -5 })

    assert_equal(valid, false)
    assert_not_nil(msg)
end)

-- Test createError
test("createError creates proper error object", function()
    local err = standards.createError(standards.ERROR_LEVELS.WARNING,
        'Test error', 'TestModule', { detail = 'test' })

    assert_equal(type(err), 'table')
    assert_equal(err.level, standards.ERROR_LEVELS.WARNING)
    assert_equal(err.message, 'Test error')
    assert_equal(err.source, 'TestModule')
    assert_equal(type(err.details), 'table')
end)

test("createError with different error levels", function()
    local fatal = standards.createError(standards.ERROR_LEVELS.FATAL, 'Fatal error', 'Test')
    local warn = standards.createError(standards.ERROR_LEVELS.WARNING, 'Warning', 'Test')
    local info = standards.createError(standards.ERROR_LEVELS.INFO, 'Info', 'Test')
    local debug = standards.createError(standards.ERROR_LEVELS.DEBUG, 'Debug', 'Test')

    assert_equal(fatal.level, 1)
    assert_equal(warn.level, 2)
    assert_equal(info.level, 3)
    assert_equal(debug.level, 4)
end)

-- Test trackPerformance
test("trackPerformance wraps function correctly", function()
    local original = function(x, y) return x + y end
    local wrapped = standards.trackPerformance('testAdd', original)

    assert_equal(type(wrapped), 'function')
    assert_equal(wrapped(3, 4), 7)
end)

test("trackPerformance handles multiple arguments and return values", function()
    local original = function(a, b, c) return a + b + c, a * b * c, a - b - c end
    local wrapped = standards.trackPerformance('testMultiple', original)

    local sum, product, diff = wrapped(1, 2, 3)
    assert_equal(sum, 6)
    assert_equal(product, 6)
    assert_equal(diff, -4)
end)

test("trackPerformance handles functions with no return value", function()
    local side_effect = false
    local original = function() side_effect = true end
    local wrapped = standards.trackPerformance('testVoid', original)

    wrapped()
    assert_equal(side_effect, true)
end)

-- Test utility functions
test("isEmpty detects empty values", function()
    assert_equal(standards.isEmpty(nil), true)
    assert_equal(standards.isEmpty(''), true)
    assert_equal(standards.isEmpty('   '), true)
    assert_equal(standards.isEmpty({}), true)
    assert_equal(standards.isEmpty('hello'), false)
    assert_equal(standards.isEmpty({ 1 }), false)
end)

test("isEmpty utility function works correctly", function()
    assert_equal(standards.isEmpty(nil), true)
    assert_equal(standards.isEmpty(''), true)
    assert_equal(standards.isEmpty('   '), true)
    assert_equal(standards.isEmpty({}), true)
    assert_equal(standards.isEmpty('hello'), false)
    assert_equal(standards.isEmpty({ 1 }), false)
end)

test("formatError formats messages correctly", function()
    local err = standards.createError(standards.ERROR_LEVELS.WARNING,
        'Test message', 'TestModule', { context = 'test' })
    local formatted = standards.formatError(err)

    assert_not_nil(formatted)
    assert_equal(type(formatted), 'string')
end)

-- Test constants
test("ERROR_LEVELS constants are defined", function()
    assert_equal(standards.ERROR_LEVELS.FATAL, 1)
    assert_equal(standards.ERROR_LEVELS.WARNING, 2)
    assert_equal(standards.ERROR_LEVELS.INFO, 3)
    assert_equal(standards.ERROR_LEVELS.DEBUG, 4)
end)

test("ERROR_LEVEL_NAMES are defined", function()
    assert_equal(standards.ERROR_LEVEL_NAMES[1], "FATAL")
    assert_equal(standards.ERROR_LEVEL_NAMES[2], "WARNING")
    assert_equal(standards.ERROR_LEVEL_NAMES[3], "INFO")
    assert_equal(standards.ERROR_LEVEL_NAMES[4], "DEBUG")
end)

-- Performance test
test("Performance monitoring overhead is minimal", function()
    local function simple_add(a, b) return a + b end
    local wrapped = standards.trackPerformance('perfTest', simple_add)

    local start_time = os.clock()
    for i = 1, 1000 do
        wrapped(i, i + 1)
    end
    local end_time = os.clock()

    local duration = end_time - start_time
    -- Performance monitoring should add minimal overhead (less than 0.1 seconds for 1000 calls)
    if duration > 0.1 then
        error(string.format("Performance monitoring overhead too high: %.3f seconds", duration))
    end
end)

-- Summary
print(string.format("\n=== Test Results ==="))
print(string.format("Tests run: %d", tests_run))
print(string.format("Tests passed: %d", tests_passed))
print(string.format("Tests failed: %d", tests_run - tests_passed))
print(string.format("Success rate: %.1f%%", (tests_passed / tests_run) * 100))

if tests_passed == tests_run then
    print("\n🎉 All CodeStandards module tests passed!")
    return true
else
    print("\n❌ Some CodeStandards module tests failed.")
    return false
end
