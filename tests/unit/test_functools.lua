#!/usr/bin/env lua
--[[
Unit Tests for Functools Module
Tests functional programming utilities, currying, combinators, and Maybe monad
]]

-- Setup test environment
package.path = package.path .. ';src/modules/?.lua'
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

local Functools = require('Functools')

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

print("=== Functools Module Unit Tests ===\n")

-- Test curry function
test("curry arity 2 - uncurried form", function()
    local add = Functools.curry(function(x, y) return x + y end, 2)
    assert_equal(add(3, 4), 7)
end)

test("curry arity 2 - curried form", function()
    local add = Functools.curry(function(x, y) return x + y end, 2)
    local add5 = add(5)
    assert_equal(add5(3), 8)
end)

test("curry arity 3 - partial application", function()
    local add3 = Functools.curry(function(x, y, z) return x + y + z end, 3)
    local partial = add3(1, 2)
    assert_equal(partial(3), 6)
end)

-- Test prop function
test("prop function - direct access", function()
    local person = { name = "John", age = 30 }
    assert_equal(Functools.prop("name", person), "John")
end)

test("prop function - curried access", function()
    local getName = Functools.prop("name")
    local person = { name = "Alice", age = 25 }
    assert_equal(getName(person), "Alice")
end)

test("prop function - nil object", function()
    local getName = Functools.prop("name")
    assert_equal(getName(nil), nil)
end)

-- Test Maybe monad
test("Maybe.just creates value", function()
    local maybe = Functools.Maybe.just(42)
    assert_equal(Functools.Maybe.isJust(maybe), true)
    assert_equal(maybe.value, 42)
end)

test("Maybe.nothing is nothing", function()
    local maybe = Functools.Maybe.nothing
    assert_equal(Functools.Maybe.isNothing(maybe), true)
end)

test("Maybe.map on Just value", function()
    local maybe = Functools.Maybe.just(5)
    local mapped = Functools.Maybe.map(function(x) return x * 2 end, maybe)
    assert_equal(mapped.value, 10)
end)

test("Maybe.map on Nothing value", function()
    local mapped = Functools.Maybe.map(function(x) return x * 2 end, Functools.Maybe.nothing)
    assert_equal(Functools.Maybe.isNothing(mapped), true)
end)

-- Test combinators
test("id combinator", function()
    assert_equal(Functools.combinators.id(42), 42)
end)

test("const combinator", function()
    local constFn = Functools.combinators.const(42)
    assert_equal(constFn("anything"), 42)
end)

test("flip combinator", function()
    local subtract = function(x, y) return x - y end
    local flipped = Functools.curry(Functools.combinators.flip(subtract))
    assert_equal(subtract(10, 3), 7)
    assert_equal(flipped(3, 10), 7)
end)

-- Test compose and pipe
test("compose function", function()
    local double = function(x) return x * 2 end
    local increment = function(x) return x + 1 end
    local composed = Functools.compose(increment, double)
    assert_equal(composed(5), 11) -- double(5) = 10, increment(10) = 11
end)

test("pipe function", function()
    local double = function(x) return x * 2 end
    local increment = function(x) return x + 1 end
    local piped = Functools.pipe(double, increment)
    assert_equal(piped(5), 11) -- double(5) = 10, increment(10) = 11
end)

-- Test array operations
test("map function", function()
    local arr = { 1, 2, 3 }
    local doubled = Functools.map(function(x) return x * 2 end, arr)
    assert_table_equal(doubled, { 2, 4, 6 })
end)

test("filter function", function()
    local arr = { 1, 2, 3, 4, 5, 6 }
    local evens = Functools.filter(function(x) return x % 2 == 0 end, arr)
    assert_table_equal(evens, { 2, 4, 6 })
end)

test("reduce function", function()
    local arr = { 1, 2, 3, 4 }
    local sum = Functools.reduce(function(acc, x) return acc + x end, 0, arr)
    assert_equal(sum, 10)
end)

-- Performance test
test("curry performance with large number of calls", function()
    local add = Functools.curry(function(x, y) return x + y end, 2)
    local start_time = os.clock()

    for i = 1, 1000 do
        local result = add(i, i)
        if result ~= i * 2 then
            error("Incorrect result in performance test")
        end
    end

    local duration = os.clock() - start_time
    if duration > 0.1 then -- Should complete in less than 100ms
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
    print("\n🎉 All Functools module tests passed!")
    return true
else
    print("\n❌ Some Functools module tests failed.")
    return false
end
