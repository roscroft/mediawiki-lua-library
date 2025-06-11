#!/usr/bin/env lua
--[[
Final Elegant Functional Documentation Generator
Combines the best of both worlds: working system + functional programming elegance

This implementation demonstrates:
- Sophisticated functional programming patterns
- Real module processing that actually works
- Integration with existing architecture
- Performance and elegance combined
]]

-- Setup environment properly
package.path = package.path .. ";src/modules/?.lua;tests/env/?.lua"

-- Load MediaWiki environment
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

-- Load functional programming library
local func = require('Functools')

-- Configuration
local config = {
    directories = {
        source = "src/modules",
        docs = "src/module-docs"
    }
}

print("🎯 Final Elegant Functional Documentation Generator")
print("=" .. string.rep("=", 52))

-- ======================
-- ELEGANT FUNCTIONAL UTILITIES
-- ======================

-- Safe file operations using functional composition
local FileOps = {}

FileOps.readFile = function(path)
    local file = io.open(path, "r")
    if not file then
        return func.Maybe.nothing
    end

    local content = file:read("*all")
    file:close()

    return content and func.Maybe.just(content) or func.Maybe.nothing
end

FileOps.writeFile = func.c2(function(path, content)
    local file = io.open(path, "w")
    if not file then
        return func.Maybe.nothing
    end

    file:write(content)
    file:close()
    return func.Maybe.just({ path = path, size = #content })
end)

-- Text processing using pure functions
local TextOps = {}

TextOps.trim = func.compose(
    function(s) return s:gsub("%s*$", "") end,
    function(s) return s:gsub("^%s*", "") end
)

TextOps.splitLines = function(content)
    local lines = {}
    for line in content:gmatch("([^\r\n]*)\r?\n?") do
        if line ~= "" then
            table.insert(lines, line)
        end
    end
    return lines
end

TextOps.isComment = function(line)
    return line:match("^%s*%-%-%-") ~= nil
end

TextOps.cleanComment = func.compose(
    TextOps.trim,
    function(line) return line:gsub("^%s*%-%-%-", "") end
)

-- ======================
-- FUNCTIONAL DOCUMENTATION GENERATION
-- ======================

local DocGen = {}

-- Extract module information using functional patterns
DocGen.extractModuleInfo = function(content)
    local lines = TextOps.splitLines(content)

    -- Filter comments using functional approach
    local comments = func.filter(TextOps.isComment, lines)
    local cleanedComments = func.map(TextOps.cleanComment, comments)

    -- Extract module name and description
    local moduleName = "Unknown"
    local description = "No description available"

    -- Look for module declaration
    local moduleMatch = content:match("@module%s+([%w_%.]+)")
    if moduleMatch then
        moduleName = moduleMatch
    end

    -- Look for description in comments
    for _, comment in ipairs(cleanedComments) do
        if not comment:match("^@") and comment ~= "" and #comment > 10 then
            description = comment
            break
        end
    end

    -- Extract function count
    local functionCount = 0
    for _ in content:gmatch("function%s+[%w_.]+%s*%(") do
        functionCount = functionCount + 1
    end

    return {
        moduleName = moduleName,
        description = description,
        commentCount = #comments,
        functionCount = functionCount,
        size = #content
    }
end

-- Generate MediaWiki template using functional composition
DocGen.createTemplate = function(moduleInfo)
    -- Template parts generator using currying
    local createSection = func.c2(function(title, content)
        return title .. " = " .. content
    end)

    -- Compose template parts
    local parts = {
        "{{Documentation}}",
        "{{Helper module",
        createSection("|name", moduleInfo.moduleName),
        createSection("|summary", moduleInfo.description),
        createSection("|functions", moduleInfo.functionCount .. " functions documented"),
        createSection("|comments", moduleInfo.commentCount .. " comment blocks processed"),
        "|example =",
        "<syntaxhighlight lang='lua'>",
        "local " .. moduleInfo.moduleName:lower() .. " = require('Module:" .. moduleInfo.moduleName .. "')",
        "-- Use the " .. moduleInfo.moduleName .. " module",
        "</syntaxhighlight>",
        "}}"
    }

    return table.concat(parts, "\n")
end

-- ======================
-- MAIN PROCESSING WITH MONADIC COMPOSITION
-- ======================

local processModule = function(moduleName)
    print("🔍 Processing module: " .. moduleName)

    local sourcePath = config.directories.source .. "/" .. moduleName .. ".lua"
    local outputPath = config.directories.docs .. "/" .. moduleName .. ".html"

    -- Processing pipeline using Maybe monad
    local result = func.Maybe.bind(function(content)
        -- Extract module information
        local moduleInfo = DocGen.extractModuleInfo(content)
        moduleInfo.moduleName = moduleName -- Ensure correct name

        -- Generate documentation template
        local template = DocGen.createTemplate(moduleInfo)

        -- Write output file
        return func.Maybe.bind(function(writeResult)
            return func.Maybe.just({
                moduleName = moduleName,
                outputPath = writeResult.path,
                size = writeResult.size,
                moduleInfo = moduleInfo
            })
        end)(FileOps.writeFile(outputPath, template))
    end)(FileOps.readFile(sourcePath))

    -- Handle result using pattern matching
    if func.Maybe.isJust(result) then
        local info = result.value
        print("✅ " .. info.moduleName .. " - " .. info.size .. " bytes")
        print("   📄 Output: " .. info.outputPath)
        print("   📊 " .. info.moduleInfo.functionCount .. " functions, " ..
            info.moduleInfo.commentCount .. " comments")
        return info
    else
        print("❌ " .. moduleName .. " - Failed to process")
        print("   📁 Source: " .. sourcePath)
        return nil
    end
end

-- ======================
-- FUNCTIONAL PROGRAMMING DEMONSTRATION
-- ======================

local demonstrateElegantPatterns = function()
    print("\n🎨 Elegant Functional Programming Patterns:")
    print("=" .. string.rep("=", 45))

    -- 1. Pure function composition
    print("\n🔗 1. Pure Function Composition")
    local processText = func.compose(
        function(s) return "📝 " .. s end,
        func.compose(
            string.upper,
            TextOps.trim
        )
    )
    print("   " .. processText("  documentation  "))

    -- 2. Functional data transformation
    print("\n📊 2. Functional Data Transformation")
    local modules = { "Array", "Functools", "Funclib", "Lists" }
    local addPrefix = func.c2(function(prefix, name)
        return prefix .. name
    end)

    local moduleList = func.map(addPrefix("Module:"), modules)
    print("   Modules: " .. table.concat(moduleList, ", "))

    -- 3. Monadic error handling
    print("\n🛡️  3. Monadic Error Handling")
    local safeDivide = function(x, y)
        if y == 0 then
            return func.Maybe.nothing
        else
            return func.Maybe.just(x / y)
        end
    end

    local computation = func.Maybe.bind(function(x)
        return func.Maybe.map(function(y) return x + y end)(safeDivide(20, 4))
    end)(safeDivide(10, 2))

    local result = func.Maybe.fromMaybe("error")(computation)
    print("   Monadic computation: " .. result)

    -- 4. Advanced combinators in action
    print("\n🎯 4. Advanced Combinators")
    local formatResult = func.c2(function(operation, value)
        return operation .. " result: " .. value
    end)

    local logResult = formatResult("Processing")
    print("   " .. logResult("Success"))

    print("\n✨ Functional elegance demonstrated!")
end

-- ======================
-- PERFORMANCE COMPARISON
-- ======================

local performanceTest = function()
    print("\n⚡ Performance: Functional vs Imperative")
    print("=" .. string.rep("=", 42))

    local testData = {}
    for i = 1, 1000 do
        table.insert(testData, i)
    end

    -- Functional approach
    local startTime = os.clock()
    local functionalResult = func.reduce(function(acc, x)
        return acc + (x % 2 == 0 and x * 2 or 0)
    end, 0, testData)
    local functionalTime = os.clock() - startTime

    -- Imperative approach
    startTime = os.clock()
    local imperativeResult = 0
    for _, x in ipairs(testData) do
        if x % 2 == 0 then
            imperativeResult = imperativeResult + x * 2
        end
    end
    local imperativeTime = os.clock() - startTime

    print("   Functional: " .. functionalResult .. " in " .. string.format("%.4f", functionalTime) .. "s")
    print("   Imperative: " .. imperativeResult .. " in " .. string.format("%.4f", imperativeTime) .. "s")
    print("   Results match: " .. tostring(functionalResult == imperativeResult))
end

-- ======================
-- MAIN EXECUTION
-- ======================

local main = function()
    print("\n📋 Starting Elegant Functional Processing")

    -- Get module name from command line
    local moduleName = arg and arg[1] or "Functools"

    -- Process the module
    local result = processModule(moduleName)

    if result then
        -- Demonstrate functional patterns
        demonstrateElegantPatterns()

        -- Performance comparison
        performanceTest()

        print("\n🏆 Elegant functional documentation generation complete!")
        print("🎉 Perfect balance of elegance and utility achieved!")
    else
        print("\n⚠️  Module processing failed, but functional patterns still work!")
        demonstrateElegantPatterns()
    end
end

-- Execute with comprehensive error handling
local success, err = pcall(main)
if not success then
    print("❌ Error: " .. tostring(err))
    print("🔧 Demonstrating functional error recovery:")
    demonstrateElegantPatterns()
else
    print("\n✨ Perfect functional execution!")
end
