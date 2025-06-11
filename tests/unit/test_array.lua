#!/usr/bin/env lua
--[[
Unit Tests for Array Module
Tests the standalone Array module functionality
]]

-- Setup test environment
package.path = package.path .. ';src/modules/?.lua'
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

local Array = require('Array')

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

local function assert_table_equal(actual, expected, msg)
    if type(actual) ~= "table" or type(expected) ~= "table" then
        error(msg or "Both values must be tables")
    end
    if #actual ~= #expected then
        error(msg or string.format("Table lengths differ: expected %d, got %d", #expected, #actual))
    end
    for i = 1, #expected do
        if actual[i] ~= expected[i] then
            error(msg or string.format("Table differs at index %d: expected %s, got %s",
                i, tostring(expected[i]), tostring(actual[i])))
        end
    end
end

print("=== Array Module Unit Tests ===\n")

-- Test Array.new
test("Array.new creates array from table", function()
    local arr = Array.new({ 1, 2, 3 })
    assert_table_equal(arr, { 1, 2, 3 })
end)

test("Array.new handles empty table", function()
    local arr = Array.new({})
    assert_table_equal(arr, {})
end)

test("Array.new with nil creates empty array", function()
    local arr = Array.new()
    assert_table_equal(arr, {})
end)

-- Test Array.filter
test("Array.filter with even numbers", function()
    local arr = Array.new({ 1, 2, 3, 4, 5, 6 })
    local filtered = Array.filter(arr, function(x) return x % 2 == 0 end)
    assert_table_equal(filtered, { 2, 4, 6 })
end)

test("Array.filter with no matches", function()
    local arr = Array.new({ 1, 3, 5 })
    local filtered = Array.filter(arr, function(x) return x % 2 == 0 end)
    assert_table_equal(filtered, {})
end)

test("Array.filter with all matches", function()
    local arr = Array.new({ 2, 4, 6 })
    local filtered = Array.filter(arr, function(x) return x % 2 == 0 end)
    assert_table_equal(filtered, { 2, 4, 6 })
end)

-- Test Array.map
test("Array.map doubles values", function()
    local arr = Array.new({ 1, 2, 3 })
    local mapped = Array.map(arr, function(x) return x * 2 end)
    assert_table_equal(mapped, { 2, 4, 6 })
end)

test("Array.map to strings", function()
    local arr = Array.new({ 1, 2, 3 })
    local mapped = Array.map(arr, function(x) return "item" .. tostring(x) end)
    assert_table_equal(mapped, { "item1", "item2", "item3" })
end)

test("Array.map empty array", function()
    local arr = Array.new({})
    local mapped = Array.map(arr, function(x) return x * 2 end)
    assert_table_equal(mapped, {})
end)

-- Test error conditions
test("Array.filter handles invalid predicate gracefully", function()
    local arr = Array.new({ 1, 2, 3 })
    local success = pcall(function()
        -- Expected parameter type mismatch
        ---@diagnostic disable-next-line: param-type-mismatch
        Array.filter(arr, "not a function")
    end)
    assert_equal(success, false, "Should fail with invalid predicate")
end)

test("Array.map handles invalid transformer gracefully", function()
    local arr = Array.new({ 1, 2, 3 })
    local success = pcall(function()
        -- Expected param type mismatch for test
        ---@diagnostic disable-next-line: param-type-mismatch
        Array.map(arr, "not a function")
    end)
    assert_equal(success, false, "Should fail with invalid transformer")
end)

-- Performance test (basic)
test("Array operations performance", function()
    local large_arr = {}
    for i = 1, 1000 do
        large_arr[i] = i
    end

    local start_time = os.clock()
    local arr = Array.new(large_arr)
    local filtered = Array.filter(arr, function(x) return x % 2 == 0 end)
    local mapped = Array.map(filtered, function(x) return x * 2 end)
    local end_time = os.clock()

    local duration = end_time - start_time
    assert_equal(#mapped, 500, "Should have 500 even numbers doubled")
    -- Performance should be reasonable (less than 1 second for 1000 items)
    if duration > 1.0 then
        error(string.format("Performance too slow: %.3f seconds", duration))
    end
end)

-- Summary
print(string.format("\n=== Test Results ==="))
print(string.format("Tests run: %d", tests_run))
print(string.format("Tests passed: %d", tests_passed))
print(string.format("Tests failed: %d", tests_run - tests_passed))
print(string.format("Success rate: %.1f%%", (tests_passed / tests_run) * 100))

if tests_passed == tests_run then
    print("\n🎉 All Array module tests passed!")
    return true
else
    print("\n❌ Some Array module tests failed.")
    return false
end
