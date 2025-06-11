--[[
Elegant Functional Documentation Generator for MediaWiki Lua Modules
Demonstrates sophisticated functional programming patterns using Functools.lua

This version showcases:
- Monadic error handling with Maybe/Result types
- Function composition and currying
- Pure functional data transformations
- Pipeline-oriented architecture
- Elegant combinator usage

Usage: lua generate-docs-elegant.lua [module_name]
]]

-- Set up package path for local modules and test environment
local script_dir = debug.getinfo(1, "S").source:match("@(.*)/[^/]*$")
if script_dir then
    package.path = package.path .. ";" .. script_dir .. "/?.lua;" .. script_dir .. "/?/init.lua"
else
    package.path = package.path .. ";./?.lua;./?/init.lua"
end

-- Load test environment for MediaWiki compatibility
package.path = package.path .. ";tests/env/?.lua;src/modules/?.lua"
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

-- Import functional programming library
local func = require('Functools')

-- Import configuration and utilities
local DocConfig = require('config.doc-config')
local FileUtils = require('utils.file-utils')
local TextUtils = require('utils.text-utils')

-- ======================
-- FUNCTIONAL CORE TYPES AND OPERATIONS
-- ======================

-- Documentation processing result type
local DocResult = {}

-- Create a successful documentation result
-- @param value any The successful result value
-- @return table Result wrapper
DocResult.success = function(value)
    return { success = true, value = value, errors = {} }
end

-- Create a failed documentation result
-- @param error string Error message
-- @return table Result wrapper
DocResult.failure = function(error)
    return { success = false, value = nil, errors = { error } }
end

-- Monadic map for DocResult
-- @param f function Function to apply to successful result
-- @return function Function that operates on DocResult
DocResult.map = func.c2(function(f, result)
    if result.success then
        return DocResult.success(f(result.value))
    else
        return result
    end
end)

-- Monadic bind for DocResult (flatMap)
-- @param f function Function that returns a DocResult
-- @return function Function that operates on DocResult
DocResult.bind = func.c2(function(f, result)
    if result.success then
        return f(result.value)
    else
        return result
    end
end)

-- ======================
-- PURE FUNCTIONAL PARSING OPERATIONS
-- ======================

-- Pure function to check if a line is a comment
-- @param line string Line to check
-- @return boolean True if line is a comment
local isCommentLine = function(line)
    return line:match("^%s*%-%-%-") ~= nil
end

-- Pure function to extract comment text
-- @param line string Comment line
-- @return string Extracted comment text
local extractCommentText = function(line)
    return line:gsub("^%s*%-%-%-", ""):gsub("^(.-)%s*$", "%1")
end

-- Pure function to classify comment type
-- @param commentText string Comment text to classify
-- @return string Comment type classification
local classifyComment = function(commentText)
    if commentText:match("^@param%s+") then
        return "param"
    elseif commentText:match("^@return%s+") then
        return "return"
    elseif commentText:match("^@generic%s+") then
        return "generic"
    elseif commentText:match("^@[%w_]+") then
        return "directive"
    elseif commentText:match("^```") then
        return "codeblock"
    elseif TextUtils.isEmpty(commentText) then
        return "empty"
    else
        return "description"
    end
end

-- Pure function to parse parameter annotation
-- @param commentText string Parameter annotation text
-- @return table|nil Parameter info or nil
local parseParameterAnnotation = function(commentText)
    local paramName, paramType, paramDesc = commentText:match("^@param%s+([%S]+)%s+([%S]+)%s*(.*)")
    if paramName then
        return {
            name = paramName,
            type = paramType,
            description = paramDesc or ""
        }
    end
    return nil
end

-- Pure function to parse generic annotation
-- @param commentText string Generic annotation text
-- @return table|nil Generic info or nil
local parseGenericAnnotation = function(commentText)
    local genericName, genericType = commentText:match("^@generic%s+([%w_]+)%s*:%s*(.+)$")
    if genericName then
        return {
            name = genericName,
            type = genericType:match("^%s*(.-)%s*$")
        }
    end
    return nil
end

-- ======================
-- FUNCTIONAL COMPOSITION PIPELINES
-- ======================

-- Create a documentation processing pipeline using function composition
-- @param config table Configuration object
-- @return function Composed documentation processing pipeline
local createDocumentationPipeline = function(config)
    -- Stage 1: Read and validate input
    local readModuleContent = func.c2(function(config, moduleName)
        local sourcePath = config.directories.source .. "/" .. moduleName .. ".lua"
        local content = FileUtils.readFile(sourcePath)
        if content then
            return DocResult.success({ moduleName = moduleName, content = content })
        else
            return DocResult.failure("Could not read file: " .. sourcePath)
        end
    end)

    -- Stage 2: Parse lines into processable chunks
    local parseIntoLines = DocResult.map(function(moduleData)
        return {
            moduleName = moduleData.moduleName,
            content = moduleData.content,
            lines = TextUtils.splitLines(moduleData.content)
        }
    end)

    -- Stage 3: Process comment blocks functionally
    local processCommentBlocks = DocResult.map(function(moduleData)
        local lines = moduleData.lines
        local functions = {}
        local currentDoc = nil
        local inComment = false

        -- Functional line processing using map and filter
        local commentLines = func.Array.filter(isCommentLine)(lines)
        local processedComments = func.Array.map(function(line)
            return {
                original = line,
                text = extractCommentText(line),
                type = func.compose(classifyComment, extractCommentText)(line)
            }
        end)(commentLines)

        -- Group comment blocks by function
        -- This would need more sophisticated parsing in real implementation
        -- For now, simplified to demonstrate functional style

        return {
            moduleName = moduleData.moduleName,
            content = moduleData.content,
            lines = lines,
            commentBlocks = processedComments,
            functions = {} -- Simplified for demo
        }
    end)

    -- Stage 4: Apply hierarchical sorting functionally
    local applySorting = DocResult.map(function(moduleData)
        -- Functional sorting using pure functions
        local sortByName = function(a, b) return a.name < b.name end
        local sortByDepth = function(a, b) return (a.depth or 0) > (b.depth or 0) end

        local sortingFunction = config.sorting.hierarchical and sortByDepth or sortByName
        local sortedFunctions = func.Array.sort(sortingFunction)(moduleData.functions)

        return {
            moduleName = moduleData.moduleName,
            functions = sortedFunctions,
            commentBlocks = moduleData.commentBlocks
        }
    end)

    -- Stage 5: Generate documentation using template composition
    local generateDocumentation = DocResult.map(function(moduleData)
        -- Template generation using functional composition
        local createHeader = func.const("{{Documentation}}\n{{Helper module\n|name = " .. moduleData.moduleName)
        local createFooter = func.const("}}")
        local createExample = func.const(
        "|example =\n<syntaxhighlight lang='lua'>\n    -- Example usage\n</syntaxhighlight>")

        -- Compose template parts functionally
        local templateParts = {
            createHeader(),
            "", -- Empty line
            createExample(),
            createFooter()
        }

        return {
            moduleName = moduleData.moduleName,
            documentation = TextUtils.join(templateParts, "\n")
        }
    end)

    -- Stage 6: Write output using monadic error handling
    local writeDocumentation = DocResult.bind(function(docData)
        local outputPath = config.directories.docs .. "/" .. docData.moduleName .. ".html"
        local success, err = pcall(FileUtils.writeFile, outputPath, docData.documentation)

        if success then
            return DocResult.success({
                moduleName = docData.moduleName,
                outputPath = outputPath,
                size = #docData.documentation
            })
        else
            return DocResult.failure("Failed to write documentation: " .. tostring(err))
        end
    end)

    -- Compose the entire pipeline using function composition
    return func.compose(
        writeDocumentation,
        func.compose(
            generateDocumentation,
            func.compose(
                applySorting,
                func.compose(
                    processCommentBlocks,
                    parseIntoLines
                )
            )
        )
    )(readModuleContent(config))
end

-- ======================
-- ELEGANT FUNCTIONAL INTERFACE
-- ======================

-- Higher-order function for processing multiple modules
-- @param config table Configuration
-- @param moduleNames table Array of module names
-- @return table Array of results
local processModules = func.c2(function(config, moduleNames)
    local pipeline = createDocumentationPipeline(config)

    -- Use functional array operations for parallel-style processing
    return func.Array.map(function(moduleName)
        local result = pipeline(moduleName)
        if result.success then
            print("✅ " .. moduleName .. " - " .. result.value.size .. " bytes")
            return result.value
        else
            print("❌ " .. moduleName .. " - " .. table.concat(result.errors, ", "))
            return nil
        end
    end)(moduleNames)
end)

-- Pure function to discover all available modules
-- @param config table Configuration
-- @return table Array of module names
local discoverModules = function(config)
    local files = FileUtils.getModuleFiles(config.directories.source)
    return func.Array.map(function(filename)
        return FileUtils.getModuleName(filename)
    end)(func.Array.filter(function(filename)
        return filename ~= nil
    end)(files))
end

-- ======================
-- FUNCTIONAL MAIN EXECUTION
-- ======================

-- Elegant main function using functional composition and currying
local main = function()
    local config = DocConfig

    -- Parse command line arguments functionally
    local getModuleName = function(args)
        return args[1] -- First argument is module name
    end

    local moduleName = getModuleName(arg or {})

    -- Create processing function using partial application
    local processWithConfig = processModules(config)

    if moduleName then
        -- Process single module
        print("🎯 Processing module: " .. moduleName)
        processWithConfig({ moduleName })
    else
        -- Process all modules using functional discovery
        print("🎯 Processing all modules...")
        local modules = discoverModules(config)
        print("📦 Found " .. #modules .. " modules")
        processWithConfig(modules)
    end

    print("✨ Elegant functional processing complete!")
end

-- ======================
-- DEMONSTRATION OF ADVANCED FUNCTIONAL PATTERNS
-- ======================

-- Demonstrate advanced functional programming concepts
local demonstrateAdvancedPatterns = function()
    print("\n🎨 Advanced Functional Programming Patterns:")

    -- 1. Monadic composition with Maybe
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

    print("   Maybe monad result:", func.Maybe.fromMaybe(0)(result))

    -- 2. Function composition chains
    local processText = func.compose(
        function(s) return string.upper(s) end,
        func.compose(
            function(s) return string.gsub(s, "%s+", "_") end,
            function(s) return string.gsub(s, "^%s*(.-)%s*$", "%1") end
        )
    )

    print("   Composed text processing:", processText("  hello world  "))

    -- 3. Curried array operations
    local addPrefix = func.c2(function(prefix, str)
        return prefix .. str
    end)

    local addDoc = addPrefix("doc_")
    local documentNames = func.Array.map(addDoc)({ "array", "functools", "lists" })
    print("   Curried mapping result:", table.concat(documentNames, ", "))

    -- 4. Combinator demonstration
    local double = function(x) return x * 2 end
    local increment = function(x) return x + 1 end

    -- Using thrush combinator for data flow
    local result = func.thrush(5)(func.compose(increment, double))
    print("   Thrush combinator result:", result)
end

-- Execute main with demonstration
if not pcall(main) then
    print("❌ Error in main execution")
else
    demonstrateAdvancedPatterns()
end
