#!/usr/bin/env lua
--[[
 Unit Tests for Lists Module
]]

-- Setup test environment
package.path = package.path .. ';src/modules/?.lua'
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

local Lists = require('Lists')

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

print("=== Enhanced Lists Module Unit Tests ===\n")

-- Test builder exposure
test("Lists exposes QueryBuilder", function()
    assert_not_nil(Lists.QueryBuilder)
    assert_equal(type(Lists.QueryBuilder), "table")
end)

test("Lists exposes ColumnBuilder", function()
    assert_not_nil(Lists.ColumnBuilder)
    assert_equal(type(Lists.ColumnBuilder), "table")
end)

test("Lists exposes TableBuilder", function()
    assert_not_nil(Lists.TableBuilder)
    assert_equal(type(Lists.TableBuilder), "table")
end)

-- Test convenience functions
test("make_level_column function works", function()
    local column = Lists.make_level_column({ align = "center" })
    assert_not_nil(column)
end)

test("make_members_column function works", function()
    local column = Lists.make_members_column()
    assert_not_nil(column)
end)

test("make_name_column function works", function()
    local column = Lists.make_name_column()
    assert_not_nil(column)
end)

test("col shortcut works", function()
    local column = Lists.col("Header", { ["align"] = "left" })
    assert_equal(column.header, "Header")
    assert_equal(column.align, "left")
end)

test("preset shortcut works", function()
    local column = Lists.preset("LEVEL")
    assert_not_nil(column)
end)

test("decode shortcut works", function()
    local result = Lists.decode('{"test": true}')
    -- Test case; no check nil needed
    ---@diagnostic disable-next-line: need-check-nil
    assert_equal(result.test, true)
end)

-- Test level/members/name column shortcuts
test("level_col shortcut works", function()
    local column = Lists.level_col()
    assert_not_nil(column)
end)

test("members_col shortcut works", function()
    local column = Lists.members_col()
    assert_not_nil(column)
end)

test("name_col shortcut works", function()
    local column = Lists.name_col()
    assert_not_nil(column)
end)

-- Test table utilities
test("add_cells function exposed", function()
    assert_equal(type(Lists.add_cells), "function")
end)

test("add_rows function exposed", function()
    assert_equal(type(Lists.add_rows), "function")
end)

test("simple_table function exposed", function()
    assert_equal(type(Lists.simple_table), "function")
end)

-- Summary
print(string.format("\n=== Test Results ==="))
print(string.format("Tests run: %d", tests_run))
print(string.format("Tests passed: %d", tests_passed))
print(string.format("Tests failed: %d", tests_run - tests_passed))
print(string.format("Success rate: %.1f%%", (tests_passed / tests_run) * 100))

if tests_passed == tests_run then
    print("\n🎉 All enhanced Lists module tests passed!")
    return true
else
    print("\n❌ Some enhanced Lists module tests failed.")
    return false
end
