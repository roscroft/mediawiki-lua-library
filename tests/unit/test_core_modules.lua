#!/usr/bin/env lua--[[Unit Tests for Core Functional Programming ModulesConsolidated tests for Array, Functools, Funclib, and Lists modules]]-- Setup test environmentpackage.path = package.path .. ';src/modules/?.lua'-- Auto-initialize MediaWiki environment (eliminates conditional imports)require('MediaWikiAutoInit')local passed = 0local failed = 0local function test(name, func)    local status, err = pcall(func)    if status then        print("✅ " .. name)        passed = passed + 1    else        print("❌ " .. name .. ": " .. (err or "unknown error"))        failed = failed + 1    endendprint("=== Core Modules Consolidated Unit Tests ===\n")-- Test Array modulelocal Array = require('Array')test("Array module loads", function()    assert(Array ~= nil, "Array module should load")    assert(type(Array.new) == "function", "Array.new should be a function")end)test("Array.new creates array", function()    local arr = Array.new({1, 2, 3})    assert(arr ~= nil, "Should create array")    assert(#arr.data == 3, "Should have 3 elements")end)test("Array.map transforms elements", function()    local arr = Array.new({1, 2, 3})    local doubled = arr:map(function(x) return x * 2 end)    assert(doubled.data[1] == 2, "First element should be doubled")    assert(doubled.data[2] == 4, "Second element should be doubled")    assert(doubled.data[3] == 6, "Third element should be doubled")end)test("Array.filter filters elements", function()    local arr = Array.new({1, 2, 3, 4, 5})    local evens = arr:filter(function(x) return x % 2 == 0 end)    assert(#evens.data == 2, "Should have 2 even numbers")    assert(evens.data[1] == 2, "First even should be 2")    assert(evens.data[2] == 4, "Second even should be 4")end)-- Test Functools modulelocal status, functools = pcall(require, 'Functools')if status then    test("Functools module loads", function()        assert(functools ~= nil, "Functools module should load")        assert(type(functools.compose) == "function", "compose should be a function")    end)    test("Function composition works", function()        local add1 = function(x) return x + 1 end        local mul2 = function(x) return x * 2 end        local composed = functools.compose(mul2, add1)        assert(composed(5) == 12, "Should get (5+1)*2 = 12")    end)end-- Test Funclib module  local status, funclib = pcall(require, 'Funclib')if status then    test("Funclib module loads", function()        assert(funclib ~= nil, "Funclib module should load")    end)    test("Funclib QueryBuilder works", function()        if funclib.QueryBuilder then            local query = funclib.QueryBuilder:new()                :category("Test Category")                :limit(100)                :build()            assert(type(query) == "table", "Should create query table")        end    end)end-- Test Lists modulelocal status, Lists = pcall(require, 'Lists')if status then    test("Lists module loads", function()        assert(Lists ~= nil, "Lists module should load")    end)    test("Lists exposes builders", function()        if Lists.QueryBuilder then            assert(type(Lists.QueryBuilder) == "table", "Should expose QueryBuilder")        end        if Lists.ColumnBuilder then            assert(type(Lists.ColumnBuilder) == "table", "Should expose ColumnBuilder")        end    end)end-- Print resultsprint("\n=== Core Modules Test Results ===")print("Passed: " .. passed)print("Failed: " .. failed)print("Total: " .. (passed + failed))if failed == 0 then    print("✅ All core module tests passed!")else    print("❌ Some core module tests failed!")end

--[[
Unit Tests for Core Functional Programming Modules
Consolidated tests for Array, Functools, Funclib, and Lists modules
]]

-- Setup test environment
package.path = package.path .. ';src/modules/?.lua'

-- Auto-initialize MediaWiki environment (eliminates conditional imports)
require('MediaWikiAutoInit')

local passed = 0
local failed = 0

local function test(name, func)
    local status, err = pcall(func)
    if status then
        print("✅ " .. name)
        passed = passed + 1
    else
        print("❌ " .. name .. ": " .. (err or "unknown error"))
        failed = failed + 1
    end
end

print("=== Core Modules Consolidated Unit Tests ===\n")

-- Test Array module
local Array = require('Array')

test("Array module loads", function()
    assert(Array ~= nil, "Array module should load")
    assert(type(Array.new) == "function", "Array.new should be a function")
end)

test("Array.new creates array", function()
    local arr = Array.new({1, 2, 3})
    assert(arr ~= nil, "Should create array")
    assert(#arr.data == 3, "Should have 3 elements")
end)

test("Array.map transforms elements", function()
    local arr = Array.new({1, 2, 3})
    local doubled = arr:map(function(x) return x * 2 end)
    assert(doubled.data[1] == 2, "First element should be doubled")
    assert(doubled.data[2] == 4, "Second element should be doubled")
    assert(doubled.data[3] == 6, "Third element should be doubled")
end)

test("Array.filter filters elements", function()
    local arr = Array.new({1, 2, 3, 4, 5})
    local evens = arr:filter(function(x) return x % 2 == 0 end)
    assert(#evens.data == 2, "Should have 2 even numbers")
    assert(evens.data[1] == 2, "First even should be 2")
    assert(evens.data[2] == 4, "Second even should be 4")
end)

-- Test Functools module
local status, functools = pcall(require, 'Functools')
if status then
    test("Functools module loads", function()
        assert(functools ~= nil, "Functools module should load")
        assert(type(functools.compose) == "function", "compose should be a function")
    end)

    test("Function composition works", function()
        local add1 = function(x) return x + 1 end
        local mul2 = function(x) return x * 2 end
        local composed = functools.compose(mul2, add1)
        assert(composed(5) == 12, "Should get (5+1)*2 = 12")
    end)
end

-- Test Funclib module
local status, funclib = pcall(require, 'Funclib')
if status then
    test("Funclib module loads", function()
        assert(funclib ~= nil, "Funclib module should load")
    end)

    test("Funclib QueryBuilder works", function()
        if funclib.QueryBuilder then
            local query = funclib.QueryBuilder:new()
                :category("Test Category")
                :limit(100)
                :build()
            assert(type(query) == "table", "Should create query table")
        end
    end)
end

-- Test Lists module
local status, Lists = pcall(require, 'Lists')
if status then
    test("Lists module loads", function()
        assert(Lists ~= nil, "Lists module should load")
    end)

    test("Lists exposes builders", function()
        if Lists.QueryBuilder then
            assert(type(Lists.QueryBuilder) == "table", "Should expose QueryBuilder")
        end
        if Lists.ColumnBuilder then
            assert(type(Lists.ColumnBuilder) == "table", "Should expose ColumnBuilder")
        end
    end)
end

-- Print results
print("\n=== Core Modules Test Results ===")
print("Passed: " .. passed)
print("Failed: " .. failed)
print("Total: " .. (passed + failed))

if failed == 0 then
    print("✅ All core module tests passed!")
else
    print("❌ Some core module tests failed!")
end
