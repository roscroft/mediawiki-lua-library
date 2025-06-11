#!/usr/bin/env lua
-- Simple test to verify functional programming works
package.path = package.path .. ";tests/env/?.lua;src/modules/?.lua"

-- Load test environment
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

print("🎯 Testing Functional Programming Patterns")
print("=" .. string.rep("=", 45))

-- Test basic Functools loading
local success, func = pcall(require, 'Functools')
if success then
    print("✅ Functools module loaded successfully")

    -- Test basic operations
    print("\n🔧 Testing Basic Operations:")

    -- Test currying
    local add = func.c2(function(x, y) return x + y end)
    local add5 = add(5)
    print("   Currying: 5 + 3 =", add5(3))

    -- Test composition
    local double = function(x) return x * 2 end
    local increment = function(x) return x + 1 end
    local composed = func.compose(increment, double)
    print("   Composition: (5 * 2) + 1 =", composed(5))

    -- Test Maybe monad
    local safeDivide = function(x, y)
        if y == 0 then
            return func.Maybe.nothing
        else
            return func.Maybe.just(x / y)
        end
    end

    local result = func.Maybe.bind(function(x)
        return func.Maybe.just(x * 2)
    end)(safeDivide(10, 2))

    print("   Maybe monad: 10/2*2 =", func.Maybe.fromMaybe("error")(result))

    -- Test array operations
    if func.Array then
        local numbers = { 1, 2, 3, 4, 5 }
        local doubled = func.Array.map(double)(numbers)
        print("   Array map: doubled =", table.concat(doubled, ", "))

        local evens = func.Array.filter(function(x) return x % 2 == 0 end)(numbers)
        print("   Array filter: evens =", table.concat(evens, ", "))
    end

    print("\n✨ All tests completed successfully!")
else
    print("❌ Failed to load Functools:", func)
end
