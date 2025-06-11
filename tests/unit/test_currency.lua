#!/usr/bin/env lua
--[[
Unit Tests for Currency Module
Tests currency formatting and coin display functionality
]]

-- Setup test environment
package.path = package.path .. ';src/modules/?.lua'
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

local Currency = require('Currency')

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

local function assert_contains(str, pattern, msg)
    if not string.find(str, pattern, 1, true) then
        error(msg or string.format("String '%s' should contain '%s'", str, pattern))
    end
end

print("=== Currency Module Unit Tests ===\n")

-- Test basic coin formatting
test("_coins formats positive numbers", function()
    local result = Currency._coins(1000)
    assert_contains(result, "1,000")
    assert_contains(result, "coins")
end)

test("_coins formats zero", function()
    local result = Currency._coins(0)
    assert_contains(result, "0")
end)

test("_coins handles negative numbers", function()
    local result = Currency._coins(-500)
    assert_contains(result, "500")
end)

test("_coins handles large numbers", function()
    local result = Currency._coins(1000000)
    assert_contains(result, "1,000,000")
end)

-- Test different coin denominations if they exist
test("Module has _coins function", function()
    assert_equal(type(Currency._coins), "function")
end)

-- Summary
print(string.format("\n=== Test Results ==="))
print(string.format("Tests run: %d", tests_run))
print(string.format("Tests passed: %d", tests_passed))
print(string.format("Tests failed: %d", tests_run - tests_passed))
print(string.format("Success rate: %.1f%%", (tests_passed / tests_run) * 100))

if tests_passed == tests_run then
    print("\n🎉 All Currency module tests passed!")
    return true
else
    print("\n❌ Some Currency module tests failed.")
    return false
end
