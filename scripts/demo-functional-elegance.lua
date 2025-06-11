#!/usr/bin/env lua
--[[
Elegant Functional Programming Demonstration
Shows how to apply sophisticated functional patterns to documentation generation

This script demonstrates:
- Monadic error handling
- Function composition pipelines
- Curried operations
- Pure functional transformations
- Advanced combinator usage
]]

-- Add the src/modules path for Functools access
package.path = package.path .. ";src/modules/?.lua;tests/env/?.lua"

-- Load test environment for MediaWiki compatibility
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

-- Load functional programming library
local func = require('Functools')

print("🎯 Elegant Functional Programming Patterns for Documentation")
print("=" .. string.rep("=", 60))

-- ======================
-- MONADIC ERROR HANDLING PATTERNS
-- ======================

print("\n📦 1. Monadic Error Handling with Maybe/Result Types")

-- Safe division using Maybe monad
local safeDivide = function(x, y)
    if y == 0 then
        return func.Maybe.nothing
    else
        return func.Maybe.just(x / y)
    end
end

-- Chain safe operations using monadic bind
local result = func.Maybe.bind(function(x)
    return func.Maybe.just(x * 2) -- Double the result
end)(safeDivide(10, 2))

print("   Safe division result:", func.Maybe.fromMaybe("undefined")(result))

-- Demonstrate failure case
local failureResult = func.Maybe.bind(function(x)
    return func.Maybe.just(x * 2)
end)(safeDivide(10, 0))

print("   Division by zero result:", func.Maybe.fromMaybe("undefined")(failureResult))

-- ======================
-- FUNCTION COMPOSITION PIPELINES
-- ======================

print("\n🔧 2. Function Composition Pipelines")

-- Create a text processing pipeline
local processDocText = func.compose(
    function(s) return "Documentation: " .. s end,
    func.compose(
        function(s) return s:gsub("%s+", "_") end,
        func.compose(
            function(s) return s:upper() end,
            function(s) return s:gsub("^%s*(.-)%s*$", "%1") end -- trim
        )
    )
)

local sampleText = "  hello world  "
print("   Original:", '"' .. sampleText .. '"')
print("   Processed:", processDocText(sampleText))

-- ======================
-- CURRIED OPERATIONS
-- ======================

print("\n🎛️  3. Curried Operations for Reusable Functions")

-- Create a curried function for adding prefixes
local addPrefix = func.c2(function(prefix, text)
    return prefix .. text
end)

-- Create specialized functions using partial application
local addFuncPrefix = addPrefix("func.")
local addArrayPrefix = addPrefix("Array.")

local functions = { "map", "filter", "reduce" }
print("   Original functions:", table.concat(functions, ", "))

-- Apply prefixes using functional mapping
local funcPrefixed = func.Array.map(addFuncPrefix)(functions)
local arrayPrefixed = func.Array.map(addArrayPrefix)(functions)

print("   With func prefix:", table.concat(funcPrefixed, ", "))
print("   With Array prefix:", table.concat(arrayPrefixed, ", "))

-- ======================
-- ADVANCED COMBINATORS
-- ======================

print("\n🎨 4. Advanced Combinators for Elegant Code")

-- Demonstrate thrush combinator for data flow
local processValue = function(x)
    return func.thrush(x)(func.compose(
        function(n) return n + 10 end,
        function(n) return n * 2 end
    ))
end

print("   Thrush combinator (5 * 2 + 10):", processValue(5))

-- Demonstrate flip combinator for argument reordering
local subtract = function(x, y) return x - y end
local flippedSubtract = func.flip(func.c2(subtract))

print("   Normal subtract (10 - 3):", func.c2(subtract)(10)(3))
print("   Flipped subtract (10 - 3):", flippedSubtract(3)(10))

-- ======================
-- FUNCTIONAL DATA TRANSFORMATIONS
-- ======================

print("\n📊 5. Functional Data Transformations")

-- Sample documentation data
local docFunctions = {
    { name = "Array.map",    complexity = 2, category = "transform" },
    { name = "Array.filter", complexity = 1, category = "select" },
    { name = "Array.reduce", complexity = 3, category = "aggregate" },
    { name = "func.compose", complexity = 2, category = "combinator" },
    { name = "func.curry",   complexity = 1, category = "combinator" }
}

-- Functional filtering and mapping
local highComplexity = func.Array.filter(function(f)
    return f.complexity >= 2
end)(docFunctions)

print("   High complexity functions:", #highComplexity)

-- Functional grouping by category
local groupByCategory = function(functions)
    local groups = {}
    for _, f in ipairs(functions) do
        if not groups[f.category] then
            groups[f.category] = {}
        end
        table.insert(groups[f.category], f.name)
    end
    return groups
end

local grouped = groupByCategory(docFunctions)
for category, funcs in pairs(grouped) do
    print("   " .. category .. ":", table.concat(funcs, ", "))
end

-- ======================
-- PARSER COMBINATOR DEMONSTRATION
-- ======================

print("\n🔍 6. Parser Combinator Patterns")

-- Simple parser for JSDoc annotations
local parseAnnotation = function(text)
    -- Use Maybe monad for safe parsing
    local tryParse = function(pattern, extractor)
        local match = text:match(pattern)
        if match then
            return func.Maybe.just(extractor(match))
        else
            return func.Maybe.nothing
        end
    end

    -- Try parsing @param annotation
    local paramResult = tryParse("^@param%s+(%S+)", function(match)
        return { type = "param", name = match }
    end)

    if func.Maybe.isJust(paramResult) then
        return paramResult
    end

    -- Try parsing @return annotation
    local returnResult = tryParse("^@return%s+(%S+)", function(match)
        return { type = "return", returnType = match }
    end)

    return func.Maybe.fromMaybe({ type = "unknown", text = text })(returnResult)
end

-- Test parser with sample annotations
local annotations = { "@param x number", "@return string", "Some description" }
print("   Parsing results:")
for _, annotation in ipairs(annotations) do
    local result = parseAnnotation(annotation)
    local parsed = func.Maybe.fromMaybe({ type = "unknown" })(
        func.Maybe.just(result)
    )
    print("      '" .. annotation .. "' -> " .. parsed.type)
end

-- ======================
-- ELEGANT PIPELINE COMPOSITION
-- ======================

print("\n🚀 7. Elegant Documentation Pipeline")

-- Create a functional documentation pipeline
local createDocPipeline = function()
    -- Stage 1: Extract function names
    local extractNames = func.Array.map(function(f) return f.name end)

    -- Stage 2: Add documentation prefix
    local addDocPrefix = func.Array.map(addPrefix("doc_"))

    -- Stage 3: Format as list items
    local formatAsListItems = func.Array.map(function(name)
        return "* " .. name
    end)

    -- Stage 4: Join into documentation
    local joinAsDoc = function(items)
        return "== Functions ==\n" .. table.concat(items, "\n")
    end

    -- Compose the entire pipeline
    return func.compose(
        joinAsDoc,
        func.compose(
            formatAsListItems,
            func.compose(
                addDocPrefix,
                extractNames
            )
        )
    )
end

-- Apply the pipeline to sample data
local docPipeline = createDocPipeline()
local documentation = docPipeline(docFunctions)

print("   Generated documentation:")
print(documentation)

-- ======================
-- SUMMARY
-- ======================

print("\n✨ Summary: Elegant Functional Programming Benefits")
print("   ✓ Type Safety: Maybe/Result monads prevent null pointer errors")
print("   ✓ Composability: Functions combine elegantly using composition")
print("   ✓ Reusability: Curried functions create specialized utilities")
print("   ✓ Clarity: Functional pipelines express intent clearly")
print("   ✓ Immutability: Pure functions avoid side effects")
print("   ✓ Testability: Pure functions are easy to test in isolation")

print("\n🎉 Functional programming makes code more elegant, maintainable, and robust!")
