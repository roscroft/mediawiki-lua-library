#!/usr/bin/env lua
--[[
Unit Tests for Funclib Module
Tests domain-specific table/column/query builders and formatters
]]

-- Setup test environment
package.path = package.path .. ';src/modules/?.lua'
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

local Funclib = require('Funclib')

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

print("=== Funclib Module Unit Tests ===\n")

-- Test QueryBuilder
test("QueryBuilder creates basic query", function()
    local query = Funclib.QueryBuilder:new()
        :category("Test Category")
        :property("Test Property", "alias")
        :limit(100)
        :build()

    assert_type(query, "table")
    assert_not_nil(query["Test Property"])
end)

test("QueryBuilder handles multiple properties", function()
    local query = Funclib.QueryBuilder:new()
        :category("Category")
        :property("Prop1", "alias1")
        :property("Prop2", "alias2")
        :build()

    assert_not_nil(query["Prop1"])
    assert_not_nil(query["Prop2"])
end)

-- Test ColumnBuilder
test("ColumnBuilder creates basic column", function()
    local column = Funclib.ColumnBuilder:new("test_field")
        :header("Test Header")
        :align("center")
        :build()

    assert_equal(column.field, "test_field")
    assert_equal(column.header, "Test Header")
    assert_equal(column.align, "center")
end)

test("ColumnBuilder handles tooltips", function()
    local column = Funclib.ColumnBuilder:new("field")
        :header("Header")
        :tooltip("Test tooltip")
        :build()

    assert_equal(column.tooltip, "Test tooltip")
end)

-- Test column presets
test("COLUMN_PRESETS contains expected presets", function()
    assert_not_nil(Funclib.COLUMN_PRESETS.LEVEL)
    assert_not_nil(Funclib.COLUMN_PRESETS.NAME)
    assert_not_nil(Funclib.COLUMN_PRESETS.MEMBERS)
end)

test("make_preset_column creates column from preset", function()
    local column = Funclib.make_preset_column("LEVEL", { align = "right" })
    assert_not_nil(column)
    assert_type(column, "table")
end)

-- Test convenience functions
test("col function creates column", function()
    local column = Funclib.col("field", "Header")
    assert_equal(column.field, "field")
    assert_equal(column.header, "Header")
end)

test("preset function works", function()
    local column = Funclib.preset("LEVEL")
    assert_not_nil(column)
end)

-- Test JSON decoding
test("decode function handles valid JSON", function()
    local json_str = '{"name": "test", "value": 42}'
    local decoded = Funclib.decode(json_str)
    -- Test case; never nil
    ---@diagnostic disable-next-line: need-check-nil
    assert_equal(decoded.name, "test")
    -- Test case; never nil
    ---@diagnostic disable-next-line: need-check-nil
    assert_equal(decoded.value, 42)
end)

test("decode function handles invalid JSON", function()
    local result = Funclib.decode("invalid json")
    assert_equal(result, nil)
end)

-- Test table building utilities
test("add_cells function works", function()
    -- This would require mocking mw.html, so we test that it's a function
    assert_type(Funclib.add_cells, "function")
end)

test("simple_table function exists", function()
    assert_type(Funclib.simple_table, "function")
end)

-- Summary
print(string.format("\n=== Test Results ==="))
print(string.format("Tests run: %d", tests_run))
print(string.format("Tests passed: %d", tests_passed))
print(string.format("Tests failed: %d", tests_run - tests_passed))
print(string.format("Success rate: %.1f%%", (tests_passed / tests_run) * 100))

if tests_passed == tests_run then
    print("\n🎉 All Funclib module tests passed!")
    return true
else
    print("\n❌ Some Funclib module tests failed.")
    return false
end
