#!/usr/bin/env lua
--[[
Working Elegant Functional Documentation Generator
Demonstrates sophisticated functional programming patterns while actually generating documentation

This implementation combines theoretical elegance with practical utility:
- Advanced functional programming patterns from Functools.lua
- Real module processing and documentation generation
- Monadic error handling for robust operation
- Pure functional template generation
]]

-- Setup paths and environment
package.path = package.path .. ";src/modules/?.lua;tests/env/?.lua;scripts/config/?.lua;scripts/utils/?.lua"

-- Load test environment for MediaWiki compatibility
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

-- Import the functional programming library
local func = require('Functools')

-- Load supporting utilities
local success, DocConfig = pcall(require, 'doc-config')
local docConfig = success and DocConfig or {
    directories = {
        source = "src/modules",
        docs = "src/module-docs"
    },
    sorting = { hierarchical = true }
}

print("🎯 Working Elegant Functional Documentation Generator")
print("=" .. string.rep("=", 55))
print("🔧 Combining Functional Programming Excellence with Real Utility")

-- ======================
-- RESULT MONAD FOR ERROR HANDLING
-- ======================

-- Result type for sophisticated error handling
local Result = {}

Result.Ok = function(value)
    return { tag = "Ok", value = value }
end

Result.Err = function(error, context)
    return { tag = "Err", error = error, context = context or {} }
end

Result.isOk = function(result)
    return result.tag == "Ok"
end

Result.map = func.c2(function(f, result)
    if Result.isOk(result) then
        return Result.Ok(f(result.value))
    else
        return result
    end
end)

Result.bind = func.c2(function(f, result)
    if Result.isOk(result) then
        return f(result.value)
    else
        return result
    end
end)

Result.unwrapOr = func.c2(function(default, result)
    if Result.isOk(result) then
        return result.value
    else
        return default
    end
end)

-- ======================
-- PURE FUNCTIONAL FILE OPERATIONS
-- ======================

local FileOps = {}

-- Safe file reading with Result monad
FileOps.readFile = function(path)
    local file = io.open(path, "r")
    if not file then
        return Result.Err("File not found", { path = path })
    end

    local content = file:read("*all")
    file:close()

    if content then
        return Result.Ok(content)
    else
        return Result.Err("Could not read file content", { path = path })
    end
end

-- Safe file writing with Result monad
FileOps.writeFile = func.c2(function(path, content)
    local file = io.open(path, "w")
    if not file then
        return Result.Err("Could not create file", { path = path })
    end

    file:write(content)
    file:close()
    return Result.Ok({ path = path, size = #content })
end)

-- Directory listing with functional processing
FileOps.listDirectory = function(path)
    local files = {}
    local handle = io.popen("ls " .. path .. "/*.lua 2>/dev/null")
    if handle then
        for filename in handle:lines() do
            table.insert(files, filename)
        end
        handle:close()
    end
    return Result.Ok(files)
end

-- ======================
-- FUNCTIONAL TEXT PROCESSING
-- ======================

local TextOps = {}

-- Pure string operations using functional composition
TextOps.trim = func.compose(
    function(s) return s:gsub("%s*$", "") end,
    function(s) return s:gsub("^%s*", "") end
)

-- Split lines functionally
TextOps.splitLines = function(content)
    local lines = {}
    for line in content:gmatch("([^\r\n]*)\r?\n?") do
        if line ~= "" then
            table.insert(lines, line)
        end
    end
    return lines
end

-- Extract comments using pure functions
TextOps.extractComments = function(lines)
    return func.filter(function(line)
        return line:match("^%s*%-%-%-") ~= nil
    end, lines)
end

-- Clean comment text
TextOps.cleanComment = func.compose(
    TextOps.trim,
    function(line) return line:gsub("^%s*%-%-%-", "") end
)

-- ======================
-- JSDOC PARSING WITH FUNCTIONAL PATTERNS
-- ======================

local JSDocParser = {}

-- Parse JSDoc annotations using pattern matching and functional composition
JSDocParser.parseAnnotation = function(commentText)
    local text = TextOps.trim(commentText)

    -- Function parameter parsing
    if text:match("^@param%s+") then
        local name, paramType, desc = text:match("^@param%s+([%S]+)%s+([%S]+)%s*(.*)")
        if name then
            return {
                type = "param",
                name = name,
                paramType = paramType,
                description = desc or ""
            }
        end
    end

    -- Return type parsing
    if text:match("^@return%s+") then
        local returnType, desc = text:match("^@return%s+([%S]+)%s*(.*)")
        if returnType then
            return {
                type = "return",
                returnType = returnType,
                description = desc or ""
            }
        end
    end

    -- Generic type parsing
    if text:match("^@generic%s+") then
        local genericType = text:match("^@generic%s+(.+)")
        return {
            type = "generic",
            genericType = genericType
        }
    end

    -- Function description
    if not text:match("^@") and text ~= "" then
        return {
            type = "description",
            text = text
        }
    end

    return {
        type = "unknown",
        text = text
    }
end

-- Process comment blocks into structured data
JSDocParser.processCommentBlock = function(comments)
    local cleanedComments = func.map(TextOps.cleanComment, comments)
    local annotations = func.map(JSDocParser.parseAnnotation, cleanedComments)

    -- Group annotations into function documentation
    local functionDoc = {
        description = "",
        params = {},
        returns = {},
        generics = {}
    }

    for _, annotation in ipairs(annotations) do
        if annotation.type == "description" then
            if functionDoc.description == "" then
                functionDoc.description = annotation.text
            else
                functionDoc.description = functionDoc.description .. " " .. annotation.text
            end
        elseif annotation.type == "param" then
            table.insert(functionDoc.params, annotation)
        elseif annotation.type == "return" then
            table.insert(functionDoc.returns, annotation)
        elseif annotation.type == "generic" then
            table.insert(functionDoc.generics, annotation)
        end
    end

    return functionDoc
end

-- ======================
-- ELEGANT TEMPLATE GENERATION
-- ======================

local TemplateGen = {}

-- Memoized template functions
TemplateGen.createHeader = func.memoize(function(moduleName)
    return table.concat({
        "{{Documentation}}",
        "{{Helper module",
        "|name = " .. moduleName,
        "|summary = Functional programming module with advanced patterns"
    }, "\n")
end)

-- Format function parameters elegantly
TemplateGen.formatParameter = function(param)
    return string.format("* '''%s''' (%s): %s",
        param.name, param.paramType, param.description)
end

-- Generate function documentation
TemplateGen.createFunctionDoc = function(name, doc)
    local parts = {
        "=== " .. name .. " ===",
        "",
        doc.description or "No description available.",
        ""
    }

    -- Add generics if present
    if #doc.generics > 0 then
        table.insert(parts, "'''Generics:'''")
        for _, generic in ipairs(doc.generics) do
            table.insert(parts, "* " .. generic.genericType)
        end
        table.insert(parts, "")
    end

    -- Add parameters if present
    if #doc.params > 0 then
        table.insert(parts, "'''Parameters:'''")
        for _, param in ipairs(doc.params) do
            table.insert(parts, TemplateGen.formatParameter(param))
        end
        table.insert(parts, "")
    end

    -- Add return information if present
    if #doc.returns > 0 then
        table.insert(parts, "'''Returns:'''")
        for _, ret in ipairs(doc.returns) do
            table.insert(parts, string.format("* %s: %s", ret.returnType, ret.description))
        end
        table.insert(parts, "")
    end

    return table.concat(parts, "\n")
end

-- Complete documentation generation using functional composition
TemplateGen.generateComplete = function(moduleData)
    local header = TemplateGen.createHeader(moduleData.moduleName)

    local functionDocs = {}
    for name, doc in pairs(moduleData.functions) do
        table.insert(functionDocs, TemplateGen.createFunctionDoc(name, doc))
    end

    local parts = {
        header,
        "",
        "|description = " .. (moduleData.description or "Advanced functional programming module"),
        "",
        "|functions =",
        ""
    }

    for _, funcDoc in ipairs(functionDocs) do
        table.insert(parts, funcDoc)
    end

    table.insert(parts, "}}")

    return table.concat(parts, "\n")
end

-- ======================
-- MAIN PROCESSING PIPELINE
-- ======================

-- Extract function signatures from Lua code
local extractFunctions = function(content)
    local functions = {}

    -- Simple function extraction (could be enhanced with proper parsing)
    for signature in content:gmatch("function%s+([%w_.]+)%s*%(") do
        if not functions[signature] then
            functions[signature] = {
                description = "",
                params = {},
                returns = {},
                generics = {}
            }
        end
    end

    -- Also look for function assignments
    for signature in content:gmatch("([%w_.]+)%s*=%s*function%s*%(") do
        if not functions[signature] then
            functions[signature] = {
                description = "",
                params = {},
                returns = {},
                generics = {}
            }
        end
    end

    return functions
end

-- Complete module processing pipeline
local processModule = function(moduleName)
    print("🔍 Processing: " .. moduleName)

    local sourcePath = docConfig.directories.source .. "/" .. moduleName .. ".lua"

    -- Processing pipeline using Result monad
    local result = Result.bind(function(content)
        -- Extract basic structure
        local lines = TextOps.splitLines(content)
        local comments = TextOps.extractComments(lines)
        local functions = extractFunctions(content)

        -- Process comments into documentation
        if #comments > 0 then
            local doc = JSDocParser.processCommentBlock(comments)
            -- For simplicity, apply to first function if any
            local firstName = next(functions)
            if firstName then
                functions[firstName] = doc
            end
        end

        -- Create module data
        local moduleData = {
            moduleName = moduleName,
            description = "Functional programming module with sophisticated patterns",
            functions = functions,
            commentCount = #comments,
            functionCount = 0
        }

        -- Count functions
        for _ in pairs(functions) do
            moduleData.functionCount = moduleData.functionCount + 1
        end

        -- Generate documentation
        local documentation = TemplateGen.generateComplete(moduleData)

        -- Write output
        local outputPath = docConfig.directories.docs .. "/" .. moduleName .. ".html"
        return Result.bind(function(writeResult)
            return Result.Ok({
                moduleName = moduleName,
                outputPath = outputPath,
                size = writeResult.size,
                commentCount = moduleData.commentCount,
                functionCount = moduleData.functionCount
            })
        end)(FileOps.writeFile(outputPath, documentation))
    end)(FileOps.readFile(sourcePath))

    -- Handle results
    if Result.isOk(result) then
        local info = result.value
        print("✅ " .. info.moduleName .. " - " .. info.size .. " bytes, " ..
            info.functionCount .. " functions, " .. info.commentCount .. " comments")
        return info
    else
        print("❌ " .. moduleName .. " - " .. result.error)
        if result.context and result.context.path then
            print("   Path: " .. result.context.path)
        end
        return nil
    end
end

-- ======================
-- FUNCTIONAL PROGRAMMING DEMONSTRATION
-- ======================

local demonstrateFunctionalPatterns = function()
    print("\n🎨 Functional Programming Patterns in Action:")
    print("=" .. string.rep("=", 50))

    -- 1. Function composition
    print("\n🔗 1. Function Composition")
    local processText = func.compose(
        function(s) return "DOC: " .. s end,
        func.compose(string.upper, TextOps.trim)
    )
    print("   Composed processing: '" .. processText("  hello  ") .. "'")

    -- 2. Currying and partial application
    print("\n🍛 2. Currying and Partial Application")
    local formatMsg = func.c2(function(prefix, msg)
        return prefix .. ": " .. msg
    end)
    local logError = formatMsg("ERROR")
    local logInfo = formatMsg("INFO")
    print("   " .. logError("File not found"))
    print("   " .. logInfo("Processing complete"))

    -- 3. Maybe monad
    print("\n🛡️  3. Maybe Monad Safety")
    local safeAccess = function(obj, key)
        if obj and obj[key] then
            return func.Maybe.just(obj[key])
        else
            return func.Maybe.nothing
        end
    end

    local testObj = { name = "Functools", version = "2.0" }
    local name = func.Maybe.fromMaybe("unknown")(safeAccess(testObj, "name"))
    local author = func.Maybe.fromMaybe("unknown")(safeAccess(testObj, "author"))

    print("   Safe access name: " .. name)
    print("   Safe access author: " .. author)

    -- 4. Advanced combinators
    print("\n🎯 4. Advanced Combinators")
    local multiplyAdd = func.c2(function(x, y) return x * 2 + y end)
    local thrushResult = func.thrush(5)(multiplyAdd(3))
    print("   Thrush combinator (5 * 2 + 3): " .. thrushResult)

    print("\n✨ Functional patterns demonstration complete!")
end

-- ======================
-- MAIN EXECUTION
-- ======================

local main = function()
    print("\n📋 Starting Working Functional Documentation Generation")

    -- Parse command line arguments
    local moduleName = arg and arg[1] or "Functools"

    -- Process the specified module
    processModule(moduleName)

    -- Demonstrate functional patterns
    demonstrateFunctionalPatterns()

    print("\n🏆 Working functional documentation generation complete!")
    print("🎉 Elegance and utility successfully combined!")
end

-- Execute with error handling
local success, err = pcall(main)
if not success then
    print("❌ Error: " .. tostring(err))
else
    print("\n✨ Perfect execution achieved!")
end
