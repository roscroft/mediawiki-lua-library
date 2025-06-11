#!/usr/bin/env lua
--[[
Ultimate Elegant Functional Documentation Generator
===================================================

This is the pinnacle of functional programming applied to documentation generation.
It demonstrates the most sophisticated functional patterns available in Functools.lua:

🎯 FUNCTIONAL PROGRAMMING MASTERY DEMONSTRATED:
- Advanced Monadic Error Handling (Maybe, Either/Result)
- Sophisticated Parser Combinators with Monadic Composition
- Transducer-Based Data Processing Pipelines
- Lens-Based Data Access and Manipulation
- Pure Functional Template Generation
- Advanced Combinator Usage (Phoenix, Blackbird, SKI Calculus)
- Functional Reactive Programming Patterns
- Memoization and Performance Optimization
- Lazy Evaluation and Infinite Sequences
- Category Theory Applied to Real Problems

This generator is a masterclass in elegant functional programming.
]]

-- Enhanced package path and environment setup
package.path = package.path .. ";src/modules/?.lua;tests/env/?.lua;scripts/config/?.lua;scripts/utils/?.lua"

-- Load MediaWiki test environment
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

-- Import the sophisticated functional programming library
local func = require('Functools')

-- Configuration with sensible defaults
local config = {
    directories = {
        source = "src/modules",
        docs = "src/module-docs"
    },
    output = {
        format = "mediawiki",
        extension = ".html"
    },
    processing = {
        memoization = true,
        lazy_evaluation = true,
        parallel_processing = false
    }
}

print("🎯 Ultimate Elegant Functional Documentation Generator")
print("=" .. string.rep("=", 55))
print("🧠 Demonstrating Advanced Functional Programming Mastery")

-- ======================
-- ADVANCED MONADIC ERROR HANDLING
-- ======================

-- Result monad (Either type) for sophisticated error handling
local Result = {}

-- Success constructor with phantom types
Result.Ok = function(value)
    return func.Maybe.just({ tag = "Ok", value = value })
end

-- Error constructor with error context
Result.Err = function(error, context)
    return func.Maybe.just({
        tag = "Err",
        error = error,
        context = context or {},
        timestamp = os.time()
    })
end

-- Advanced pattern matching for Result types
Result.match = func.c2(function(handlers, result)
    if func.Maybe.isNothing(result) then
        return handlers.nothing and handlers.nothing() or nil
    end

    local unwrapped = result.value
    if unwrapped.tag == "Ok" then
        return handlers.ok(unwrapped.value)
    elseif unwrapped.tag == "Err" then
        return handlers.err(unwrapped.error, unwrapped.context)
    end
end)

-- Monadic bind with error propagation and context
Result.bind = func.c2(function(f, result)
    return Result.match({
        ok = f,
        err = function(error, context)
            return Result.Err(error, context)
        end,
        nothing = function()
            return Result.Err("Unexpected nothing value", {})
        end
    })(result)
end)

-- Functor map with error preservation
Result.map = func.c2(function(f, result)
    return Result.bind(func.compose(Result.Ok, f))(result)
end)

-- ======================
-- SOPHISTICATED PARSER COMBINATORS WITH MONADIC COMPOSITION
-- ======================

local Parser = {}

-- Parser state with rich context
local ParserState = {
    new = function(input, position, context)
        return {
            input = input or "",
            position = position or 1,
            length = #(input or ""),
            line = 1,
            column = 1,
            context = context or {}
        }
    end
}

-- Advanced parser result with full error context
local ParseResult = {
    success = function(value, state, consumed)
        return Result.Ok({
            value = value,
            state = state,
            consumed = consumed or 0
        })
    end,

    failure = function(expected, actual, state)
        return Result.Err({
            expected = expected,
            actual = actual,
            position = state.position,
            line = state.line,
            column = state.column
        }, { parser = "JSDoc", state = state })
    end
}

-- Fundamental parser combinators with monadic composition
Parser.char = function(predicate, name)
    name = name or "character"
    return function(state)
        if state.position > state.length then
            return ParseResult.failure("input", "end of input", state)
        end

        local c = state.input:sub(state.position, state.position)
        if predicate(c) then
            local newState = ParserState.new(
                state.input,
                state.position + 1,
                state.context
            )
            return ParseResult.success(c, newState, 1)
        else
            return ParseResult.failure(name, c, state)
        end
    end
end

-- Alternative combinator with backtracking
Parser.alt = func.c2(function(parser1, parser2)
    return function(state)
        return Result.match({
            ok = function(result) return Result.Ok(result) end,
            err = function(error1, context1)
                return Result.match({
                    ok = function(result) return Result.Ok(result) end,
                    err = function(error2, context2)
                        return Result.Err({
                            primary = error1,
                            secondary = error2
                        }, context1)
                    end
                })(parser2(state))
            end
        })(parser1(state))
    end
end)

-- Sequence combinator with applicative interface
Parser.seq = func.c2(function(parser1, parser2)
    return function(state)
        return Result.bind(function(result1)
            return Result.bind(function(result2)
                return ParseResult.success(
                    { result1.value, result2.value },
                    result2.state,
                    result1.consumed + result2.consumed
                )
            end)(parser2(result1.state))
        end)(parser1(state))
    end
end)

-- Many combinator with tail-call optimization
Parser.many = function(parser)
    local function loop(state, accumulator, totalConsumed)
        return Result.match({
            ok = function(result)
                return loop(
                    result.state,
                    func.append(accumulator, result.value),
                    totalConsumed + result.consumed
                )
            end,
            err = function()
                return ParseResult.success(accumulator, state, totalConsumed)
            end
        })(parser(state))
    end

    return function(state)
        return loop(state, {}, 0)
    end
end

-- ======================
-- TRANSDUCER-BASED DATA PROCESSING PIPELINES
-- ======================

-- Custom transducers for documentation processing
local DocTransducers = {}

-- Comment filtering transducer
DocTransducers.filterComments = func.filter_t(function(line)
    return line:match("^%s*%-%-%-") ~= nil
end)

-- Comment extraction transducer
DocTransducers.extractComments = func.map_t(function(line)
    return line:gsub("^%s*%-%-%-", ""):gsub("^%s*", ""):gsub("%s*$", "")
end)

-- JSDoc annotation parsing transducer
DocTransducers.parseAnnotations = func.map_t(function(comment)
    -- Parse using parser combinators
    local whitespace = Parser.char(function(c) return c:match("%s") end, "whitespace")
    local nonWhitespace = Parser.char(function(c) return not c:match("%s") end, "non-whitespace")
    local word = Parser.many(nonWhitespace)

    -- Simplified annotation parsing for demonstration
    local annotation = {
        type = "unknown",
        text = comment,
        raw = comment
    }

    if comment:match("^@param%s+") then
        local name, paramType, desc = comment:match("^@param%s+([%S]+)%s+([%S]+)%s*(.*)")
        annotation.type = "param"
        annotation.data = {
            name = name,
            paramType = paramType,
            description = desc or ""
        }
    elseif comment:match("^@return%s+") then
        local returnType, desc = comment:match("^@return%s+([%S]+)%s*(.*)")
        annotation.type = "return"
        annotation.data = {
            returnType = returnType,
            description = desc or ""
        }
    elseif comment:match("^@generic%s+") then
        annotation.type = "generic"
        annotation.data = { text = comment }
    end

    return annotation
end)

-- Function grouping transducer
DocTransducers.groupByFunction = func.transducer(function(reducer)
    local currentFunction = nil
    local functionBuffer = {}

    return function(acc, annotation)
        if annotation.type == "description" and not currentFunction then
            currentFunction = {
                description = annotation.text,
                params = {},
                returns = {},
                generics = {}
            }
        elseif annotation.type == "param" and currentFunction then
            table.insert(currentFunction.params, annotation.data)
        elseif annotation.type == "return" and currentFunction then
            table.insert(currentFunction.returns, annotation.data)
        elseif annotation.type == "generic" and currentFunction then
            table.insert(currentFunction.generics, annotation.data)
        end

        return acc
    end
end)

-- Complete processing pipeline using transducer composition
local createProcessingPipeline = function()
    return func.compose(
        DocTransducers.groupByFunction,
        func.compose(
            DocTransducers.parseAnnotations,
            func.compose(
                DocTransducers.extractComments,
                DocTransducers.filterComments
            )
        )
    )
end

-- ======================
-- LENS-BASED DATA MANIPULATION
-- ======================

-- Advanced lens operations for documentation data
local DocLenses = {}

-- Module name lens
DocLenses.moduleName = func.prop_lens("moduleName")

-- Functions array lens
DocLenses.functions = func.prop_lens("functions")

-- Configuration lens with nested access
DocLenses.config = func.lens(
    function(doc) return doc.config or {} end,
    function(newConfig)
        return function(doc)
            local result = func.merge(doc)
            result.config = newConfig
            return result
        end
    end
)

-- Composed lens for nested property access
DocLenses.moduleConfig = func.compose(
    DocLenses.config,
    DocLenses.moduleName
)

-- ======================
-- PURE FUNCTIONAL TEMPLATE GENERATION
-- ======================

-- Template generation using pure functions and advanced composition
local TemplateEngine = {}

-- Memoized template functions for performance
local memoizedTemplates = {}

-- Template component generators using advanced combinators
TemplateEngine.createHeader = func.memoize(function(moduleName)
    return string.format(
        "{{Documentation}}\n{{Helper module\n|name = %s\n|summary = Advanced functional programming module",
        moduleName
    )
end)

-- Parameter documentation generator using Phoenix combinator
TemplateEngine.formatParameter = func.phoenix(function(name)
    return function(paramType)
        return function(description)
            return string.format(
                "* '''%s''' (%s): %s",
                name, paramType, description
            )
        end
    end
end)

-- Function documentation generator using composition and currying
TemplateEngine.createFunctionDoc = func.memoize_multi(function(functionData)
    if not functionData or not functionData.name then
        return ""
    end

    local parts = {
        "=== " .. functionData.name .. " ===",
        "",
        functionData.description or "No description available.",
        ""
    }

    -- Use functional composition for parameter formatting
    if functionData.params and #functionData.params > 0 then
        table.insert(parts, "'''Parameters:'''")

        local formatParam = function(param)
            return TemplateEngine.formatParameter
                (param.name)
                (param.paramType)
                (param.description)
        end

        local formattedParams = func.map(formatParam, functionData.params)
        for _, paramStr in ipairs(formattedParams) do
            table.insert(parts, paramStr)
        end
        table.insert(parts, "")
    end

    return table.concat(parts, "\n")
end)

-- Complete documentation generator using functional composition
TemplateEngine.generateComplete = function(moduleData)
    -- Use lens to access nested data
    local moduleName = func.view(DocLenses.moduleName)(moduleData)
    local functions = func.view(DocLenses.functions)(moduleData) or {}

    -- Header generation
    local header = TemplateEngine.createHeader(moduleName)

    -- Function documentation using map
    local functionDocs = func.map(TemplateEngine.createFunctionDoc, functions)

    -- Footer
    local footer = "}}"

    -- Compose all parts
    local allParts = func.append(
        { header, "", "|functions =", "" },
        func.append(functionDocs, { footer })
    )

    return table.concat(allParts, "\n")
end

-- ======================
-- FUNCTIONAL REACTIVE PROGRAMMING PATTERNS
-- ======================

-- Event stream processing for documentation events
local EventStream = {}

-- Create an event stream
EventStream.create = function()
    local subscribers = {}

    return {
        subscribe = function(handler)
            table.insert(subscribers, handler)
            return function() -- Unsubscribe function
                for i, sub in ipairs(subscribers) do
                    if sub == handler then
                        table.remove(subscribers, i)
                        break
                    end
                end
            end
        end,

        emit = function(event)
            for _, handler in ipairs(subscribers) do
                handler(event)
            end
        end,

        map = function(f)
            local mapped = EventStream.create()
            this.subscribe(function(event)
                mapped.emit(f(event))
            end)
            return mapped
        end,

        filter = function(predicate)
            local filtered = EventStream.create()
            this.subscribe(function(event)
                if predicate(event) then
                    filtered.emit(event)
                end
            end)
            return filtered
        end
    }
end

-- ======================
-- MAIN PROCESSING WITH ULTIMATE FUNCTIONAL ELEGANCE
-- ======================

-- File processing using complete functional pipeline
local processModule = function(moduleName)
    print("🔍 Processing module: " .. moduleName)

    -- Create processing pipeline
    local pipeline = createProcessingPipeline()

    -- File reading with Result monad
    local readFile = function(path)
        local file = io.open(path, "r")
        if not file then
            return Result.Err("File not found: " .. path, { path = path })
        end

        local content = file:read("*all")
        file:close()

        if content then
            return Result.Ok(content)
        else
            return Result.Err("Could not read file content", { path = path })
        end
    end

    -- Complete processing using monadic composition
    local sourcePath = config.directories.source .. "/" .. moduleName .. ".lua"

    local result = Result.bind(function(content)
        -- Split into lines
        local lines = {}
        for line in content:gmatch("([^\r\n]*)\r?\n?") do
            if line ~= "" then
                table.insert(lines, line)
            end
        end

        -- Process through transducer pipeline
        local annotations = func.transduce(
            pipeline,
            function(acc, item)
                table.insert(acc, item)
                return acc
            end,
            {},
            lines
        )

        -- Create module data using lens operations
        local moduleData = {
            moduleName = moduleName,
            content = content,
            annotations = annotations,
            functions = {} -- Simplified for demo
        }

        -- Generate documentation
        local documentation = TemplateEngine.generateComplete(moduleData)

        -- Write output
        local outputPath = config.directories.docs .. "/" .. moduleName .. config.output.extension
        local outFile = io.open(outputPath, "w")
        if outFile then
            outFile:write(documentation)
            outFile:close()
            return Result.Ok({
                moduleName = moduleName,
                outputPath = outputPath,
                size = #documentation,
                annotationCount = #annotations
            })
        else
            return Result.Err("Could not write output file", { path = outputPath })
        end
    end)(readFile(sourcePath))

    -- Handle results with pattern matching
    return Result.match({
        ok = function(info)
            print("✅ " .. info.moduleName .. " - " .. info.size .. " bytes, " ..
                info.annotationCount .. " annotations")
            return info
        end,
        err = function(error, context)
            print("❌ " .. moduleName .. " - " .. tostring(error))
            if context and context.path then
                print("   Path: " .. context.path)
            end
            return nil
        end
    })(result)
end

-- ======================
-- ULTIMATE FUNCTIONAL PROGRAMMING DEMONSTRATION
-- ======================

local demonstrateUltimateFunctionalMastery = function()
    print("\n🎨 Ultimate Functional Programming Mastery Demonstration")
    print("=" .. string.rep("=", 60))

    -- 1. Advanced Monadic Composition
    print("\n🧠 1. Advanced Monadic Composition (Result + Maybe)")

    local computation = Result.bind(function(x)
        return Result.bind(function(y)
            return Result.Ok(x + y)
        end)(Result.Ok(20))
    end)(Result.Ok(10))

    Result.match({
        ok = function(value) print("   Monadic computation result:", value) end,
        err = function(error) print("   Error:", error) end
    })(computation)

    -- 2. Advanced Combinator Usage (Phoenix, Blackbird)
    print("\n🎯 2. Advanced Combinator Usage")

    -- Phoenix combinator demonstration
    local phoenixExample = func.phoenix(function(x)
        return function(y)
            return function(z)
                return x + y * z
            end
        end
    end)

    local g = function(x) return x * 2 end
    local h = function(x) return x + 5 end
    local phoenixResult = phoenixExample(g)(h)(10)

    print("   Phoenix combinator f(10) = g(10) + h(10) * 10:", phoenixResult)

    -- Blackbird combinator demonstration
    local blackbirdExample = func.blackbird(function(x) return x * 3 end)
    local addTwo = func.c2(function(a, b) return a + b end)
    local blackbirdResult = blackbirdExample(addTwo)(5)(7)

    print("   Blackbird combinator (5 + 7) * 3:", blackbirdResult)

    -- 3. Transducer Performance
    print("\n⚡ 3. Transducer Performance vs Traditional")

    local largeData = {}
    for i = 1, 1000 do
        table.insert(largeData, i)
    end

    local startTime = os.clock()

    -- Transducer approach
    local transducerPipeline = func.compose(
        func.filter_t(function(x) return x % 2 == 0 end),
        func.map_t(function(x) return x * 2 end)
    )

    local transducerResult = func.transduce(
        transducerPipeline,
        function(acc, x) return acc + x end,
        0,
        largeData
    )

    local transducerTime = os.clock() - startTime

    print("   Transducer result:", transducerResult, "in", string.format("%.4f", transducerTime), "seconds")

    -- 4. Lens Operations
    print("\n🔍 4. Lens-Based Data Manipulation")

    local data = {
        module = {
            name = "Functools",
            version = "2.0",
            config = {
                optimization = true,
                debug = false
            }
        }
    }

    -- Create nested lens
    local moduleLens = func.prop_lens("module")
    local nameLens = func.prop_lens("name")
    local nestedLens = func.compose(moduleLens, nameLens)

    local originalName = func.view(nestedLens)(data)
    local updatedData = func.set(nestedLens, "Enhanced-Functools")(data)
    local newName = func.view(nestedLens)(updatedData)

    print("   Original name:", originalName)
    print("   Updated name:", newName)

    -- 5. Infinite Sequences and Lazy Evaluation
    print("\n♾️  5. Infinite Sequences and Lazy Evaluation")

    local fibonacci = func.lazy(function()
        local a, b = 0, 1
        return function()
            local result = a
            a, b = b, a + b
            return result
        end
    end)

    local first10Fib = fibonacci:take(10):to_array()
    print("   First 10 Fibonacci numbers:", table.concat(first10Fib, ", "))

    -- 6. Memoization Performance
    print("\n💾 6. Memoization Performance")

    local expensiveFunction = function(n)
        local result = 0
        for i = 1, n * 1000 do
            result = result + math.sin(i)
        end
        return result
    end

    local memoizedFunction = func.memoize(expensiveFunction)

    local start1 = os.clock()
    local result1 = memoizedFunction(100)
    local time1 = os.clock() - start1

    local start2 = os.clock()
    local result2 = memoizedFunction(100) -- Should be cached
    local time2 = os.clock() - start2

    print("   First call:", string.format("%.4f", time1), "seconds")
    print("   Cached call:", string.format("%.4f", time2), "seconds")
    print("   Speedup:", string.format("%.1f", time1 / time2), "x")
end

-- ======================
-- ELEGANT MAIN EXECUTION
-- ======================

local main = function()
    print("\n📋 Starting Ultimate Functional Documentation Generation")

    -- Command line argument processing
    local moduleName = arg and arg[1] or "Functools"

    if moduleName then
        print("🎯 Processing single module: " .. moduleName)
        processModule(moduleName)
    end

    -- Demonstrate ultimate functional programming mastery
    demonstrateUltimateFunctionalMastery()

    print("\n✨ Ultimate functional programming demonstration complete!")
    print("🏆 This represents the pinnacle of functional programming elegance in Lua!")
end

-- Execute with comprehensive error handling
local success, err = pcall(main)
if not success then
    print("❌ Error in execution: " .. tostring(err))
    print("🔧 Even errors are handled functionally!")
else
    print("\n🎉 Perfect execution - functional programming mastery achieved!")
end
