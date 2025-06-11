#!/usr/bin/env lua
--[[
Simple Functional Programming Patterns Test
Tests core functional patterns without complex dependencies
]]

-- Setup environment
package.path = package.path .. ";src/modules/?.lua;tests/env/?.lua"

-- Load test environment
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

print("🎯 Testing Core Functional Programming Patterns")
print("=" .. string.rep("=", 50))

-- Test Functools loading
local success, func = pcall(require, 'Functools')

if success then
    print("✅ Functools loaded successfully")

    -- Test 1: Basic combinators
    print("\n🔧 1. Basic Combinators")

    -- Identity combinator
    local id_result = func.id(42)
    print("   Identity: func.id(42) =", id_result)

    -- Constant combinator
    local const5 = func.const(5)
    local const_result = const5(99)
    print("   Constant: func.const(5)(99) =", const_result)

    -- Test 2: Function composition
    print("\n🔗 2. Function Composition")

    local double = function(x) return x * 2 end
    local add3 = function(x) return x + 3 end
    local composed = func.compose(add3, double)
    local comp_result = composed(5)
    print("   Composed (5*2)+3 =", comp_result)

    -- Test 3: Currying
    print("\n🍛 3. Currying")

    local add = func.c2(function(x, y) return x + y end)
    local add10 = add(10)
    local curry_result = add10(5)
    print("   Curried add(10)(5) =", curry_result)

    -- Test 4: Maybe monad
    print("\n🛡️  4. Maybe Monad")

    local safeDivide = function(x, y)
        if y == 0 then
            return func.Maybe.nothing
        else
            return func.Maybe.just(x / y)
        end
    end

    local good_result = func.Maybe.fromMaybe("error")(safeDivide(10, 2))
    local bad_result = func.Maybe.fromMaybe("error")(safeDivide(10, 0))

    print("   Safe divide 10/2 =", good_result)
    print("   Safe divide 10/0 =", bad_result)

    -- Test 5: Advanced combinators
    print("\n🎯 5. Advanced Combinators")

    -- Thrush combinator
    local thrush_result = func.thrush(5)(double)
    print("   Thrush 5 |> double =", thrush_result)

    -- Flip combinator
    local subtract = func.c2(function(x, y) return x - y end)
    local flipped = func.flip(subtract)
    local flip_result = flipped(3)(10) -- Should be 10 - 3 = 7
    print("   Flipped subtract 10-3 =", flip_result)

    print("\n✨ All functional pattern tests completed!")
else
    print("❌ Failed to load Functools:", func)
end

print("\n🏆 Functional programming patterns demonstration complete!")
