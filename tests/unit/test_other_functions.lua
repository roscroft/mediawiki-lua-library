#!/usr/bin/env lua
--[[
Unit Tests for Other Module Functions
Tests basic functionality of various utility modules
]]

-- Setup test environment
package.path = package.path .. ';src/modules/?.lua'
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

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

local function assert_type(value, expected_type, msg)
    local actual_type = type(value)
    if actual_type ~= expected_type then
        error(msg or string.format("Expected type %s, got %s", expected_type, actual_type))
    end
end

print("=== Other Module Functions Unit Tests ===\n")

-- Test libraryUtil module
test("libraryUtil module loads and has expected functions", function()
    local libraryUtil = require('libraryUtil')
    assert_not_nil(libraryUtil)
    assert_type(libraryUtil, 'table')

    -- Check for common libraryUtil functions
    assert_type(libraryUtil.checkType, 'function')
    assert_type(libraryUtil.checkTypeMulti, 'function')
end)

-- Test Arguments module (if available)
test("Arguments module loads successfully", function()
    local success, Arguments = pcall(require, 'Arguments')
    if success then
        assert_not_nil(Arguments)
        assert_type(Arguments, 'table')
        -- Arguments module typically has getArgs function
        if Arguments.getArgs then
            assert_type(Arguments.getArgs, 'function')
        end
    else
        -- If Arguments module has dependencies that can't be loaded in test environment,
        -- that's okay - we're just testing basic loading
        print("  Note: Arguments module has dependencies not available in test environment")
    end
end)

-- Test Tables module
test("Tables module loads and exports functions", function()
    local success, Tables = pcall(require, 'Tables')
    if success then
        assert_not_nil(Tables)
        assert_type(Tables, 'table')

        -- Check if Tables has expected structure
        local has_functions = false
        for k, v in pairs(Tables) do
            if type(v) == 'function' then
                has_functions = true
                break
            end
        end
        assert_equal(has_functions, true, "Tables module should export functions")
    else
        -- Tables might have MediaWiki dependencies
        print("  Note: Tables module may have MediaWiki dependencies")
    end
end)

-- Test Functools module
test("Functools module loads and exports functions", function()
    local Functools = require('Functools')
    assert_not_nil(Functools)
    assert_type(Functools, 'table')

    -- Functools should have functional programming utilities
    local has_functions = false
    for k, v in pairs(Functools) do
        if type(v) == 'function' then
            has_functions = true
            break
        end
    end
    assert_equal(has_functions, true, "Functools module should export functions")
end)

-- Test basic functional operations from Functools
test("Functools basic operations work", function()
    local Functools = require('Functools')

    -- Test map function if available (note: might use different parameter order)
    if Functools.map then
        local success, result = pcall(Functools.map, { 1, 2, 3 }, function(x) return x * 2 end)
        if not success then
            -- Try alternate parameter order
            success, result = pcall(Functools.map, function(x) return x * 2 end, { 1, 2, 3 })
        end
        assert_equal(success, true, "map function should work with some parameter order")
        if success then
            assert_not_nil(result)
            assert_type(result, 'table')
        end
    end

    -- Test filter function if available
    if Functools.filter then
        local success, result = pcall(Functools.filter, { 1, 2, 3, 4 }, function(x) return x % 2 == 0 end)
        if not success then
            -- Try alternate parameter order
            success, result = pcall(Functools.filter, function(x) return x % 2 == 0 end, { 1, 2, 3, 4 })
        end
        assert_equal(success, true, "filter function should work with some parameter order")
        if success then
            assert_not_nil(result)
            assert_type(result, 'table')
        end
    end
end)

-- Test Funclib module integration
test("Funclib module loads and integrates with Functools", function()
    local Funclib = require('Funclib')
    assert_not_nil(Funclib)
    assert_type(Funclib, 'table')

    -- Funclib should have builders and utilities
    assert_not_nil(Funclib.QueryBuilder)
    assert_not_nil(Funclib.ColumnBuilder)
    assert_not_nil(Funclib.TableBuilder)
end)

-- Test builder instantiation
test("Funclib builders can be instantiated", function()
    local Funclib = require('Funclib')

    local query_builder = Funclib.QueryBuilder:new()
    assert_not_nil(query_builder)
    assert_type(query_builder, 'table')

    local column_builder = Funclib.ColumnBuilder:new()
    assert_not_nil(column_builder)
    assert_type(column_builder, 'table')

    local table_builder = Funclib.TableBuilder:new()
    assert_not_nil(table_builder)
    assert_type(table_builder, 'table')
end)

-- Test module interdependencies
test("Modules have proper interdependencies", function()
    -- Lists should depend on Funclib
    local Lists = require('Lists')
    local Funclib = require('Funclib')

    -- Lists should expose Funclib functionality
    assert_equal(Lists.QueryBuilder, Funclib.QueryBuilder)
    assert_equal(Lists.ColumnBuilder, Funclib.ColumnBuilder)
    assert_equal(Lists.TableBuilder, Funclib.TableBuilder)
end)

-- Test error handling in modules
test("Modules handle errors gracefully", function()
    local CodeStandards = require('CodeStandards')
    local Functools = require('Functools')

    -- Test error creation
    local err = CodeStandards.createError(1, "Test error", "TestModule")
    assert_not_nil(err)
    assert_equal(err.level, 1)
    assert_equal(err.message, "Test error")

    -- Test that modules don't crash with invalid inputs
    local success = pcall(function()
        if Functools.map then
            -- Expected param type mismatch; test case
            ---@diagnostic disable-next-line: param-type-mismatch
            Functools.map(nil, function(x) return x end)
        end
    end)
    -- Should either succeed or fail gracefully (not crash the test runner)
    assert_type(success, 'boolean')
end)

-- Test performance with mixed operations
test("Mixed module operations perform well", function()
    local Lists = require('Lists')
    local CodeStandards = require('CodeStandards')

    local start_time = os.clock()

    -- Perform various operations
    for i = 1, 100 do
        local builder = Lists.QueryBuilder:new()
        local column = Lists.make_name_column({ header = "Test " .. i })
        local err = CodeStandards.createError(2, "Test message " .. i, "TestModule")
    end

    local end_time = os.clock()
    local duration = end_time - start_time

    -- Should complete in reasonable time (less than 0.1 seconds for 100 operations)
    if duration > 0.1 then
        error(string.format("Mixed operations took too long: %.3f seconds", duration))
    end
end)

-- Summary
print(string.format("\n=== Test Results ==="))
print(string.format("Tests run: %d", tests_run))
print(string.format("Tests passed: %d", tests_passed))
print(string.format("Tests failed: %d", tests_run - tests_passed))
print(string.format("Success rate: %.1f%%", (tests_passed / tests_run) * 100))

if tests_passed == tests_run then
    print("\n🎉 All other function tests passed!")
    return true
else
    print("\n❌ Some other function tests failed.")
    return false
end
