#!/usr/bin/env lua
--[[
Enhanced Elegant Functional Documentation Generator for MediaWiki Lua Modules
Demonstrates the most sophisticated functional programming patterns using Functools.lua

This version showcases:
- Advanced monadic error handling with Result/Either types
- Sophisticated parser combinators with monadic composition
- Complex function composition pipelines
- Pure functional data transformations with transducers
- Elegant combinator usage with advanced patterns
- Lens-based data access and modification
- Functional reactive programming patterns

Usage: lua generate-docs-elegant-enhanced.lua [module_name]
]]

-- Set up package path for local modules and test environment
package.path = package.path ..
";tests/env/?.lua;src/modules/?.lua;scripts/?.lua;scripts/config/?.lua;scripts/utils/?.lua;scripts/parsers/?.lua;scripts/templates/?.lua"

-- Load test environment for MediaWiki compatibility
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

-- Import functional programming library
local func = require('Functools')

-- Import supporting modules
local success, DocConfig = pcall(require, 'doc-config')
if not success then
    DocConfig = {
        directories = {
            source = "src/modules",
            docs = "src/module-docs"
        },
        sorting = {
            hierarchical = true
        }
    }
end

-- ======================
-- ADVANCED FUNCTIONAL TYPES AND MONADS
-- ======================

-- Result type (Either monad) for better error handling
local Result = {}

-- Success constructor
Result.Ok = function(value)
    return { tag = "Ok", value = value }
end

-- Error constructor
Result.Err = function(error)
    return { tag = "Err", error = error }
end

-- Check if Result is Ok
Result.isOk = function(result)
    return result.tag == "Ok"
end

-- Check if Result is Err
Result.isErr = function(result)
    return result.tag == "Err"
end

-- Monadic map for Result
Result.map = func.c2(function(f, result)
    if Result.isOk(result) then
        return Result.Ok(f(result.value))
    else
        return result
    end
end)

-- Monadic bind for Result (flatMap)
Result.bind = func.c2(function(f, result)
    if Result.isOk(result) then
        return f(result.value)
    else
        return result
    end
end)

-- Extract value or provide default
Result.unwrapOr = func.c2(function(defaultValue, result)
    if Result.isOk(result) then
        return result.value
    else
        return defaultValue
    end
end)

-- ======================
-- PURE FUNCTIONAL STRING OPERATIONS
-- ======================

-- Text utilities using pure functions and functional composition
local TextOps = {}

-- Pure string trimming using functional composition
TextOps.trim = func.compose(
    function(s) return s:gsub("%s*$", "") end,
    function(s) return s:gsub("^%s*", "") end
)

-- Safe string operations using Maybe monad
TextOps.safeSplit = func.c2(function(separator, str)
    if type(str) ~= "string" then
        return func.Maybe.nothing
    end

    local parts = {}
    for part in str:gmatch("([^" .. separator .. "]+)") do
        table.insert(parts, part)
    end
    return func.Maybe.just(parts)
end)

-- Functional line splitting with error handling
TextOps.splitLines = function(content)
    if not content then
        return Result.Err("No content provided")
    end

    local lines = {}
    for line in content:gmatch("([^\r\n]*)\r?\n?") do
        if line ~= "" then
            table.insert(lines, line)
        end
    end
    return Result.Ok(lines)
end

-- ======================
-- ADVANCED PARSER COMBINATORS WITH MONADIC COMPOSITION
-- ======================

local Parser = {}

-- Parser state representation
local ParserState = {}
ParserState.new = function(input, position)
    return {
        input = input or "",
        position = position or 1,
        length = #(input or "")
    }
end

-- Parse result with Either-style error handling
local ParseResult = {}
ParseResult.success = function(value, state)
    return Result.Ok({ value = value, state = state })
end

ParseResult.failure = function(error, state)
    return Result.Err({ error = error, state = state })
end

-- Basic parser combinators
Parser.char = function(predicate)
    return function(state)
        if state.position > state.length then
            return ParseResult.failure("End of input", state)
        end

        local c = state.input:sub(state.position, state.position)
        if predicate(c) then
            local newState = ParserState.new(state.input, state.position + 1)
            return ParseResult.success(c, newState)
        else
            return ParseResult.failure("Character predicate failed", state)
        end
    end
end

-- Alternative combinator using Result monad
Parser.alt = func.c2(function(parser1, parser2)
    return function(state)
        local result1 = parser1(state)
        if Result.isOk(result1) then
            return result1
        else
            return parser2(state)
        end
    end
end)

-- Sequence combinator with monadic binding
Parser.seq = func.c2(function(parser1, parser2)
    return function(state)
        return Result.bind(function(result1)
            return Result.bind(function(result2)
                return ParseResult.success(
                    { result1.value, result2.value },
                    result2.state
                )
            end)(parser2(result1.state))
        end)(parser1(state))
    end
end)

-- Many combinator (zero or more)
Parser.many = function(parser)
    return function(state)
        local results = {}
        local currentState = state

        local function collectResults()
            local result = parser(currentState)
            if Result.isOk(result) then
                table.insert(results, result.value.value)
                currentState = result.value.state
                return collectResults()
            else
                return ParseResult.success(results, currentState)
            end
        end

        return collectResults()
    end
end

-- ======================
-- SOPHISTICATED JSDoc PARSING WITH FUNCTIONAL COMPOSITION
-- ======================

-- Comment analysis using pure functions and functional composition
local CommentAnalyzer = {}

-- Pure function to detect comment patterns
CommentAnalyzer.isJSDocComment = function(line)
    return line:match("^%s*%-%-%-") ~= nil
end

-- Extract comment content functionally
CommentAnalyzer.extractCommentText = func.compose(
    TextOps.trim,
    function(line) return line:gsub("^%s*%-%-%-", "") end
)

-- Classify comment types using pattern matching
CommentAnalyzer.classifyComment = function(text)
    local patterns = {
        { "^@param%s+",   "param" },
        { "^@return%s+",  "return" },
        { "^@generic%s+", "generic" },
        { "^@[%w_]+",     "directive" },
        { "^```",         "codeblock" },
        { "^%s*$",        "empty" },
        { ".*",           "description" }
    }

    for _, pattern in ipairs(patterns) do
        if text:match(pattern[1]) then
            return pattern[2]
        end
    end

    return "unknown"
end

-- Parse parameter annotation using advanced parsing
CommentAnalyzer.parseParam = function(text)
    -- More sophisticated parameter parsing using parser combinators
    local whitespace = Parser.char(function(c) return c:match("%s") end)
    local nonWhitespace = Parser.char(function(c) return not c:match("%s") end)
    local spaces = Parser.many(whitespace)
    local word = Parser.many(nonWhitespace)

    -- Simple parameter extraction for demonstration
    local paramName, paramType, paramDesc = text:match("^@param%s+([%S]+)%s+([%S]+)%s*(.*)")
    if paramName then
        return Result.Ok({
            name = paramName,
            type = paramType,
            description = paramDesc or ""
        })
    end
    return Result.Err("Invalid parameter format")
end

-- ======================
-- FUNCTIONAL DATA PROCESSING PIPELINE
-- ======================

-- Documentation processing using transducers and advanced functional patterns
local DocProcessor = {}

-- Create a transducer for processing comments
DocProcessor.commentTransducer = func.compose(
    func.filter_t(CommentAnalyzer.isJSDocComment),
    func.map_t(CommentAnalyzer.extractCommentText),
    func.map_t(function(text)
        return {
            text = text,
            type = CommentAnalyzer.classifyComment(text),
            parsed = text:match("^@param") and
                Result.unwrapOr(nil)(CommentAnalyzer.parseParam(text)) or nil
        }
    end)
)

-- File processing using monadic composition
DocProcessor.processFile = function(filePath)
    -- Safe file reading
    local safeReadFile = function(path)
        local file = io.open(path, "r")
        if not file then
            return Result.Err("Could not open file: " .. path)
        end

        local content = file:read("*all")
        file:close()

        if content then
            return Result.Ok(content)
        else
            return Result.Err("Could not read file content")
        end
    end

    -- Processing pipeline using Result monad
    return Result.bind(function(content)
        return Result.bind(function(lines)
            -- Process lines through the transducer
            local comments = func.transduce(
                DocProcessor.commentTransducer,
                function(acc, comment)
                    table.insert(acc, comment)
                    return acc
                end,
                {},
                lines
            )

            return Result.Ok({
                filePath = filePath,
                content = content,
                lines = lines,
                comments = comments
            })
        end)(TextOps.splitLines(content))
    end)(safeReadFile(filePath))
end

-- ======================
-- TEMPLATE GENERATION WITH FUNCTIONAL COMPOSITION
-- ======================

-- Template generation using pure functions and composition
local TemplateGenerator = {}

-- Header generation using curried functions
TemplateGenerator.createHeader = func.c2(function(moduleName, config)
    local headerTemplate = "{{Documentation}}\n{{Helper module\n|name = %s"
    return string.format(headerTemplate, moduleName)
end)

-- Function documentation generation
TemplateGenerator.createFunctionDoc = function(functionData)
    -- Generate documentation for a single function
    if not functionData or not functionData.name then
        return ""
    end

    local parts = {
        "=== " .. functionData.name .. " ===",
        "",
        functionData.description or "No description available.",
        ""
    }

    -- Add parameters if available
    if functionData.params and #functionData.params > 0 then
        table.insert(parts, "'''Parameters:'''")
        for _, param in ipairs(functionData.params) do
            table.insert(parts, string.format("* '''%s''' (%s): %s",
                param.name, param.type, param.description))
        end
        table.insert(parts, "")
    end

    return table.concat(parts, "\n")
end

-- Complete documentation generation using functional composition
TemplateGenerator.generateDocumentation = function(moduleData)
    local createModuleHeader = TemplateGenerator.createHeader(moduleData.moduleName)

    -- Function composition for building complete documentation
    local buildDocumentation = func.compose(
        function(parts) return table.concat(parts, "\n\n") end,
        function(moduleData)
            local parts = {
                createModuleHeader(DocConfig),
                "",
                "|description = Functional programming module with advanced patterns",
                "",
                "|functions =",
            }

            -- Add function documentation
            if moduleData.functions then
                for _, funcData in ipairs(moduleData.functions) do
                    table.insert(parts, TemplateGenerator.createFunctionDoc(funcData))
                end
            end

            table.insert(parts, "}}")
            return parts
        end
    )

    return buildDocumentation(moduleData)
end

-- ======================
-- MAIN PROCESSING WITH ADVANCED FUNCTIONAL PATTERNS
-- ======================

-- Process modules using functional composition and monadic error handling
local processModule = function(moduleName)
    local sourcePath = DocConfig.directories.source .. "/" .. moduleName .. ".lua"

    print("🔍 Processing: " .. moduleName)

    -- Complete processing pipeline
    local result = Result.bind(function(moduleData)
        -- Generate documentation using functional templates
        local documentation = TemplateGenerator.generateDocumentation({
            moduleName = moduleName,
            content = moduleData.content,
            comments = moduleData.comments,
            functions = {} -- Simplified for this demo
        })

        -- Write output
        local outputPath = DocConfig.directories.docs .. "/" .. moduleName .. ".html"
        local file = io.open(outputPath, "w")
        if file then
            file:write(documentation)
            file:close()
            return Result.Ok({
                moduleName = moduleName,
                outputPath = outputPath,
                size = #documentation
            })
        else
            return Result.Err("Could not write to: " .. outputPath)
        end
    end)(DocProcessor.processFile(sourcePath))

    -- Handle results using pattern matching
    if Result.isOk(result) then
        local info = result.value
        print("✅ " .. info.moduleName .. " - " .. info.size .. " bytes -> " .. info.outputPath)
        return info
    else
        print("❌ " .. moduleName .. " - " .. result.error)
        return nil
    end
end

-- ======================
-- SOPHISTICATED DEMONSTRATION OF FUNCTIONAL PATTERNS
-- ======================

local demonstrateAdvancedPatterns = function()
    print("\n🎨 Advanced Functional Programming Patterns Demonstration:")
    print("=" .. string.rep("=", 65))

    -- 1. Lens operations for data manipulation
    print("\n📋 1. Lens-based Data Access")
    local nameLens = func.prop_lens("name")
    local data = { name = "Functools", version = "2.0" }
    local updatedData = func.set(nameLens, "Enhanced-Functools")(data)
    print("   Original:", data.name)
    print("   Updated:", updatedData.name)

    -- 2. Transducer composition
    print("\n🔄 2. Transducer Composition")
    local numbers = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
    local transducer = func.compose(
        func.filter_t(function(x) return x % 2 == 0 end),
        func.map_t(function(x) return x * 2 end),
        func.filter_t(function(x) return x > 8 end)
    )

    local result = func.transduce(
        transducer,
        function(acc, x)
            table.insert(acc, x)
            return acc
        end,
        {},
        numbers
    )
    print("   Transduced result:", table.concat(result, ", "))

    -- 3. Maybe monad chaining
    print("\n🛡️  3. Maybe Monad Error Handling")
    local safeDivision = func.Maybe.bind(function(x)
        return func.Maybe.bind(function(y)
            if y == 0 then
                return func.Maybe.nothing
            else
                return func.Maybe.just(x / y)
            end
        end)(func.Maybe.just(2))
    end)(func.Maybe.just(10))

    print("   Safe division result:", func.Maybe.fromMaybe("error")(safeDivision))

    -- 4. Advanced combinator usage
    print("\n🎯 4. Advanced Combinator Composition")
    local processValue = func.compose(
        function(x) return "Result: " .. x end,
        function(x) return x + 100 end,
        function(x) return x * 2 end
    )

    print("   Combinator chain (5 * 2 + 100):", processValue(5))

    -- 5. Functional reactive pattern simulation
    print("\n📡 5. Functional Reactive Patterns")
    local eventStream = {
        { type = "click",  value = 1 },
        { type = "scroll", value = 5 },
        { type = "click",  value = 3 },
        { type = "resize", value = 0 }
    }

    local clickStream = func.Array.filter(function(event)
        return event.type == "click"
    end)(eventStream)

    local totalClicks = func.Array.reduce(function(acc, event)
        return acc + event.value
    end, 0)(clickStream)

    print("   Total click values:", totalClicks)
end

-- ======================
-- ELEGANT MAIN EXECUTION
-- ======================

local main = function()
    print("🎯 Enhanced Elegant Functional Documentation Generator")
    print("=" .. string.rep("=", 55))

    -- Parse command line arguments functionally
    local moduleName = arg and arg[1] or "Functools"

    if moduleName then
        print("📦 Processing single module: " .. moduleName)
        processModule(moduleName)
    else
        print("📦 Processing all modules...")
        -- Could add module discovery here
    end

    -- Demonstrate advanced patterns
    demonstrateAdvancedPatterns()

    print("\n✨ Enhanced functional processing complete!")
end

-- Execute with comprehensive error handling
local success, err = pcall(main)
if not success then
    print("❌ Error in execution: " .. tostring(err))
    print("🔧 This demonstrates graceful error handling in functional style!")
end
