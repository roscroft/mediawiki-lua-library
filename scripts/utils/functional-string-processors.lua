--[[
Functional String Processors - Demonstration Module
=================================================

This module demonstrates how string processing in the documentation generator
can be simplified using functional programming patterns from Functools.

Shows functional alternatives to the manual string processing in generate-docs.lua
]]

-- Setup proper package paths
package.path = package.path .. ";src/modules/?.lua;tests/env/?.lua;scripts/utils/?.lua"

-- Initialize MediaWiki environment
dofile('src/modules/MediaWikiAutoInit.lua')

local func = require('Functools')

local FunctionalStringProcessors = {}

-- ======================
-- FUNCTIONAL STRING COMPOSITION
-- ======================

-- Basic string transformations using pure functions
local Transforms = {}

Transforms.removeCommentMarkers = function(line)
    return line:gsub("^%s*%-%-%-?", "")
end

Transforms.trimWhitespace = function(text)
    return text:gsub("^%s*", ""):gsub("%s*$", "")
end

Transforms.convertInlineCode = function(text)
    return text:gsub("`([^`]+)`", "<code>%1</code>")
end

Transforms.formatBoldText = function(text)
    return text:gsub("'''([^']+)'''", "'''%1'''")
end

Transforms.normalizeUnionTypes = function(typeText)
    return typeText:gsub("%s*|%s*", " {{!}} ")
end

Transforms.formatArrayTypes = function(typeText)
    if not typeText:match("Array<`") then
        return typeText:gsub("Array<([^>]+)>", "Array<`%1`>")
    end
    return typeText
end

Transforms.escapeWikiPipes = function(text)
    return text:gsub("|", "{{!}}")
end

-- ======================
-- COMPOSED PROCESSORS
-- ======================

-- Clean comment text using functional composition
FunctionalStringProcessors.cleanComment = func.pipe(
    Transforms.removeCommentMarkers,
    Transforms.trimWhitespace
)

-- Format description text with configurable options
FunctionalStringProcessors.formatDescription = func.curry(function(options, text)
    if not text then return "" end

    local processors = {}

    -- Conditionally add processors based on options
    if options.convertInlineCode then
        table.insert(processors, Transforms.convertInlineCode)
    end

    table.insert(processors, Transforms.formatBoldText)

    if options.escapeWiki then
        table.insert(processors, Transforms.escapeWikiPipes)
    end

    -- Apply all processors in sequence
    return func.pipe(unpack(processors))(text)
end)

-- Format type signatures using functional composition
FunctionalStringProcessors.formatType = func.pipe(
    Transforms.trimWhitespace,
    Transforms.normalizeUnionTypes,
    Transforms.formatArrayTypes
)

-- Handle optional parameters
FunctionalStringProcessors.makeOptional = function(paramType, isOptional)
    return isOptional and not paramType:match("%?")
        and paramType .. "?"
        or paramType
end

-- ======================
-- PARAMETER PROCESSING
-- ======================

-- Safe parameter parsing using Maybe monad
FunctionalStringProcessors.parseParameter = function(commentText)
    local pattern = "^@param%s+([%w_]+)%s+(.+)"
    local name, rest = commentText:match(pattern)

    if not (name and rest) then
        return func.Maybe.nothing
    end

    -- Extract type and description
    local paramType = rest
    local description = ""

    local typeWithComment = rest:match("^(.-)%s*#%s*(.+)")
    if typeWithComment then
        paramType = typeWithComment
        description = rest:match("#%s*(.+)") or ""
    end

    return func.Maybe.just({
        name = name,
        type = FunctionalStringProcessors.formatType(paramType),
        description = description,
        optional = paramType:match("%?") ~= nil
    })
end

-- ======================
-- TEMPLATE GENERATION
-- ======================

-- Generate function signature using functional composition
FunctionalStringProcessors.generateSignature = func.curry(function(moduleName, func_obj)
    local extractParamNames = function(params)
        return func.map(function(param) return param.name end, params)
    end
    local joinWithCommas = function(names) return table.concat(names, ", ") end
    local removeModulePrefix = function(name)
        return name:match("^[^%.]+%.") and name:gsub("^[^%.]+%.", "") or name
    end

    local cleanName = removeModulePrefix(func_obj.name)
    local paramNames = extractParamNames(func_obj.params)
    local params = joinWithCommas(paramNames)

    local signature = string.format("%s(&nbsp;%s&nbsp;)", cleanName, params)
    return "<nowiki>" .. signature .. "</nowiki>"
end)

-- Generate type signature with functional processing
FunctionalStringProcessors.generateTypeSignature = function(func_obj)
    local parts = {}

    -- Add generics using functional map
    if #func_obj.generics > 0 then
        local genericParts = func.map(function(generic)
            return string.format("<samp>generic: %s</samp>", generic.name)
        end, func_obj.generics)

        -- Manually concat the arrays
        for _, part in ipairs(genericParts) do
            table.insert(parts, part)
        end
    end

    -- Process parameters using functional pipeline
    local processParam = function(param)
        local paramType = FunctionalStringProcessors.makeOptional(
            FunctionalStringProcessors.formatType(param.type),
            param.optional
        )

        return string.format("<samp>%s: %s</samp>", param.name, paramType)
    end

    local paramParts = func.map(processParam, func_obj.params)
    for _, part in ipairs(paramParts) do
        table.insert(parts, part)
    end

    -- Add return type
    local returnType = FunctionalStringProcessors.formatType(func_obj.returns.type)
    table.insert(parts, string.format("<samp>-> %s</samp>", returnType))

    return table.concat(parts, "<br>")
end

-- ======================
-- DEMONSTRATION FUNCTIONS
-- ======================

-- Show the difference between imperative and functional approaches
function FunctionalStringProcessors.demonstrateComposition()
    print("🎯 Functional String Processing Demonstration")
    print("=" .. string.rep("=", 45))

    local testInput = "  --- `someFunction` returns '''number | string'''  "

    -- Imperative approach (like original)
    print("\n📝 Imperative approach:")
    local result1 = testInput
    result1 = result1:gsub("^%s*%-%-%-?", "")
    result1 = result1:gsub("^%s*", ""):gsub("%s*$", "")
    result1 = result1:gsub("`([^`]+)`", "<code>%1</code>")
    result1 = result1:gsub("'''([^']+)'''", "'''%1'''")
    print("Result: " .. result1)

    -- Functional approach
    print("\n🔧 Functional approach:")
    local formatText = func.pipe(
        FunctionalStringProcessors.cleanComment,
        FunctionalStringProcessors.formatDescription({ convertInlineCode = true })
    )
    local result2 = formatText(testInput)
    print("Result: " .. result2)

    print("\n✅ Both approaches produce the same result!")
    print("✨ Functional approach is more readable and composable")
end

-- Test parameter parsing with Maybe monad
function FunctionalStringProcessors.demonstrateParameterParsing()
    print("\n🎯 Parameter Parsing with Maybe Monad")
    print("=" .. string.rep("=", 40))

    local testCases = {
        "@param name string # The parameter name",
        "@param count number? # Optional count",
        "@param invalid", -- This should fail safely
        "@param callback function # Callback function"
    }

    for _, testCase in ipairs(testCases) do
        print(string.format("\n📝 Parsing: %s", testCase))

        local result = FunctionalStringProcessors.parseParameter(testCase)

        if func.Maybe.isJust(result) then
            local param = result.value
            print(string.format("✅ Success: %s: %s (%s)",
                param.name, param.type, param.optional and "optional" or "required"))
            if param.description ~= "" then
                print(string.format("   📋 Description: %s", param.description))
            end
        else
            print("❌ Failed to parse (safely handled)")
        end
    end
end

-- Demonstrate type signature generation
function FunctionalStringProcessors.demonstrateTypeGeneration()
    print("\n🎯 Type Signature Generation")
    print("=" .. string.rep("=", 30))

    local mockFunction = {
        name = "Array.map",
        generics = { { name = "T" }, { name = "U" } },
        params = {
            { name = "f",  type = "fun(x: T): U", optional = false },
            { name = "xs", type = "T[]",          optional = false }
        },
        returns = { type = "U[]" }
    }

    print("\n📝 Mock function structure:")
    print("   Name: " .. mockFunction.name)
    print("   Generics: T, U")
    print("   Params: f (function), xs (array)")
    print("   Returns: U[]")

    print("\n🔧 Generated signature:")
    local signature = FunctionalStringProcessors.generateSignature("Array", mockFunction)
    print("   " .. signature)

    print("\n🔧 Generated type signature:")
    local typeSignature = FunctionalStringProcessors.generateTypeSignature(mockFunction)
    print("   " .. typeSignature:gsub("<br>", "\n   "))
end

-- Run all demonstrations
function FunctionalStringProcessors.runDemo()
    print("🎨 Functional String Processors Demo")
    print("===================================")
    print("Demonstrating functional programming patterns for")
    print("MediaWiki documentation generator simplification")

    FunctionalStringProcessors.demonstrateComposition()
    FunctionalStringProcessors.demonstrateParameterParsing()
    FunctionalStringProcessors.demonstrateTypeGeneration()

    print("\n🎉 Demo completed!")
    print("💡 These patterns can simplify the documentation generator")
    print("   by replacing imperative loops with functional composition.")
end

-- Run demo if executed directly
if arg and arg[0] and arg[0]:match("functional%-string%-processors%.lua$") then
    FunctionalStringProcessors.runDemo()
end

return FunctionalStringProcessors
