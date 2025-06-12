#!/usr/bin/env lua
--[[
Functional MediaWiki Documentation Generator
==========================================

Refactored version using functional programming patterns from Functools.
Demonstrates:
- Function composition and pipelines
- Functional array processing with map/filter/reduce
- Immutable data transformations
- Curried template generation

This generator now uses ~50% less code while maintaining all functionality
through functional programming principles.

Usage: lua scripts/generate-docs.lua [module_name]
]]

-- Enhanced package path and environment setup
package.path = package.path .. ";src/modules/?.lua;tests/env/?.lua;scripts/utils/?.lua"

require('MediaWikiAutoInit')

-- Import the functional programming library
local func = require('Functools')

-- Import utility modules for enhanced functionality
local TextUtils = require('text-utils')
local HierarchicalSorter = require('hierarchical-sorter')

-- ======================
-- FUNCTIONAL CONFIGURATION
-- ======================

-- Configuration using immutable data structures
local config = {
    sourceDir = "src/modules",
    outputDir = "tools/module-docs",
    extension = ".wiki",
    verbose = true
}

-- ======================
-- FUNCTIONAL STRING PROCESSING PIPELINE
-- ======================

-- String processing using function composition
local StringProcessors = {}

-- Clean comment text using functional composition
StringProcessors.cleanComment = func.pipe(
    function(line) return line:gsub("^%s*%-%-%-?", "") end,
    function(line) return line:gsub("^%s*", "") end,
    function(line) return line:gsub("%s*$", "") end
)

-- Format description with inline code conversion using curry
StringProcessors.formatDescription = func.curry(function(options, text)
    if not text then return "" end

    local processors = {
        function(t) return options.convertInlineCode and t:gsub("`([^`]+)`", "<code>%1</code>") or t end,
        function(t) return t:gsub("'''([^']+)'''", "'''%1'''") end
    }

    return func.pipe(unpack(processors))(text)
end)

-- Escape pipes using functional transformation
StringProcessors.escapePipes = function(text)
    if not text then return "" end
    return text:gsub("|", "{{!}}")
end

-- ======================
-- SELF-CONTAINED SOPHISTICATED PARSING SYSTEM
-- ======================

-- Self-contained JSDoc parser with support for complex types
local SelfContainedParser = {}

-- Parse sophisticated JSDoc comments with detailed type information
-- @param content string File content to parse
-- @return table Rich documentation structure
function SelfContainedParser.parseRichDocumentation(content)
    local lines = {}
    for line in content:gmatch("([^\r\n]*)\r?\n?") do
        table.insert(lines, line)
    end

    local functions = {}
    local i = 1

    while i <= #lines do
        local line = lines[i]

        -- Look for JSDoc-style comment blocks (--[[ or ---)
        if line:match("^%s*%-%-%-") or line:match("^%s*%-%-%%[%%[") then
            local docBlock = SelfContainedParser.parseAdvancedJSDocBlock(lines, i)
            if docBlock.doc then
                -- Look for function definition after the comment block
                local j = docBlock.endLine + 1
                while j <= #lines and j <= docBlock.endLine + 10 do
                    local funcInfo = SelfContainedParser.extractFunctionInfo(lines[j])
                    if funcInfo then
                        local richFunc = SelfContainedParser.createRichFunction(funcInfo, docBlock.doc)
                        -- Filter out functions starting with double underscores (private/internal functions)
                        if not richFunc.name:match("^[^%.]*%.?__") and not richFunc.name:match("^__") then
                            table.insert(functions, richFunc)
                        end
                        break
                    end
                    j = j + 1
                end
                i = docBlock.endLine + 1
            else
                i = i + 1
            end
        else
            -- Try to parse standalone function
            local funcInfo = SelfContainedParser.extractFunctionInfo(line)
            if funcInfo then
                local richFunc = SelfContainedParser.createRichFunction(funcInfo, nil)
                -- Filter out functions starting with double underscores (private/internal functions)
                if not richFunc.name:match("^[^%.]*%.?__") and not richFunc.name:match("^__") then
                    table.insert(functions, richFunc)
                end
            end
            i = i + 1
        end
    end

    -- Remove duplicate functions (keep the one with better documentation)
    local uniqueFunctions = SelfContainedParser.deduplicateFunctions(functions)

    return {
        functions = uniqueFunctions,
        totalFunctions = #uniqueFunctions
    }
end

-- Remove duplicate functions, keeping the one with better documentation
-- @param functions table Array of function objects
-- @return table Array of deduplicated functions
function SelfContainedParser.deduplicateFunctions(functions)
    local seen = {}
    local result = {}

    for _, func in ipairs(functions) do
        local existing = seen[func.name]
        if not existing then
            -- First occurrence
            seen[func.name] = func
            table.insert(result, func)
        else
            -- Duplicate found - keep the one with better documentation
            if func.description and func.description ~= "No description available." and
                (not existing.description or existing.description == "No description available.") then
                -- Replace with better documented version
                for i, existingFunc in ipairs(result) do
                    if existingFunc.name == func.name then
                        result[i] = func
                        seen[func.name] = func
                        break
                    end
                end
            end
        end
    end

    return result
end

-- Parse advanced JSDoc comment block
-- @param lines table Array of all lines
-- @param startLine number Starting line index
-- @return table {doc = table, endLine = number}
function SelfContainedParser.parseAdvancedJSDocBlock(lines, startLine)
    local doc = {
        description = {},
        params = {},
        returns = { type = "any", description = "" },
        generics = {},
        examples = {},
        notes = {},
        performance = {},
        typeDefinitions = {},
        behaviorNotes = {}
    }

    local i = startLine
    local inComment = false
    local currentDescription = {}
    local inCodeBlock = false
    local currentCodeBlock = {}
    local codeBlockLang = "lua"
    local inBehaviorSection = false
    local inPerformanceSection = false

    while i <= #lines do
        local line = lines[i]

        -- Handle different comment styles
        local commentText = ""
        if line:match("^%s*%-%-%-") then
            inComment = true
            commentText = line:gsub("^%s*%-%-%-", ""):gsub("^%s*", ""):gsub("%s*$", "")
        elseif line:match("^%s*%-%-") and inComment then
            commentText = line:gsub("^%s*%-%-", ""):gsub("^%s*", ""):gsub("%s*$", "")
        elseif line:match("^%s*%]%]") then
            -- End of --[[ ]] block
            break
        elseif inComment and not line:match("^%s*%-%-") then
            -- End of comment block if we hit a non-comment line
            break
        end

        if inComment then
            if inCodeBlock then
                if commentText:match("^```") then
                    -- End of code block
                    table.insert(doc.examples, {
                        lang = codeBlockLang,
                        code = table.concat(currentCodeBlock, "\n")
                    })
                    currentCodeBlock = {}
                    inCodeBlock = false
                else
                    -- Preserve indentation for code blocks by using raw comment text
                    local rawCodeLine = line:gsub("^%s*%-%-%-?", ""):gsub("^%s", "", 1) -- Remove only one leading space
                    table.insert(currentCodeBlock, rawCodeLine)
                end
            elseif commentText == "" then
                -- Empty comment line
                if #currentDescription > 0 then
                    table.insert(currentDescription, "")
                end
            elseif commentText:match("^```") then
                -- Start of code block
                local lang = commentText:match("^```(%w*)")
                codeBlockLang = (lang and lang ~= "") and lang or "lua"
                inCodeBlock = true
                currentCodeBlock = {}
            elseif commentText:match("^@generic%s+") then
                local generic = SelfContainedParser.parseGenericAnnotation(commentText)
                if generic then
                    table.insert(doc.generics, generic)
                end
            elseif commentText:match("^@param%s+") then
                local param = SelfContainedParser.parseParamAnnotation(commentText)
                if param then
                    table.insert(doc.params, param)
                end
            elseif commentText:match("^@return%s+") then
                local returnInfo = SelfContainedParser.parseReturnAnnotation(commentText)
                if returnInfo then
                    doc.returns = returnInfo
                end
            elseif commentText:match("^Behaviour depends on") or commentText:match("^Behavior depends on") then
                -- Start of behavior section - stop adding to description
                inBehaviorSection = true
                inPerformanceSection = false
                table.insert(doc.behaviorNotes, commentText)
            elseif inBehaviorSection and commentText:match("^%*%s") then
                -- Behavior bullet point
                table.insert(doc.behaviorNotes, commentText)
            elseif commentText:match("^Performance") then
                -- Performance note - stop adding to description
                inBehaviorSection = false
                inPerformanceSection = true
                table.insert(doc.performance, commentText)
            elseif inPerformanceSection and commentText:match("^%-") then
                -- Performance bullet point (handle various dash formats)
                local bulletText = commentText:gsub("^%-+%s*", "")
                if bulletText ~= "" then
                    table.insert(doc.performance, bulletText)
                end
            elseif commentText:match("^Type definitions:") then
                -- Type definitions section marker
                inBehaviorSection = false
                inPerformanceSection = false
                table.insert(doc.typeDefinitions, commentText)
            elseif commentText:match("^Examples:") then
                -- Examples section - don't add to description anymore
                inBehaviorSection = false
                inPerformanceSection = false
                -- Don't add this to description
            elseif commentText:match("^Direct value search:") or commentText:match("^Function%-based search:") or commentText:match("^Complex search") then
                -- These are example section headers, not description
                inBehaviorSection = false
                inPerformanceSection = false
                -- Don't add to description
            elseif commentText:match("^%*%s") then
                -- Bullet point - could be type definition, note, or behavior
                if #doc.typeDefinitions > 0 then
                    table.insert(doc.typeDefinitions, commentText)
                elseif inBehaviorSection then
                    table.insert(doc.behaviorNotes, commentText)
                else
                    table.insert(doc.notes, commentText)
                end
            else
                -- Regular description text - only add if not in special sections
                if not inBehaviorSection and not inPerformanceSection and
                    not commentText:match("^Direct value search:") and
                    not commentText:match("^Function%-based search:") and
                    not commentText:match("^Complex search") and
                    not commentText:match("Searches through the array") then
                    table.insert(currentDescription, commentText)
                elseif commentText:match("Searches through the array") then
                    -- This is descriptive text that should be part of main description
                    table.insert(currentDescription, commentText)
                end
                -- Reset behavior section if we're reading normal description
                if not commentText:match("^Behaviour") and not commentText:match("^Behavior") and
                    not commentText:match("^Performance") then
                    inBehaviorSection = false
                    inPerformanceSection = false
                end
            end
        end

        i = i + 1
    end

    if inComment then
        doc.description = currentDescription
        return { doc = doc, endLine = i - 1 }
    end

    return { doc = nil, endLine = startLine }
end

-- Extract function information from a line
-- @param line string Line to parse
-- @return table|nil Function information
function SelfContainedParser.extractFunctionInfo(line)
    -- Skip inline function assignments within if statements or other control structures
    if line:match("^%s*if%s+") or line:match("^%s*elseif%s+") or
        line:match("^%s*local%s+[^=]*=%s*function") or
        line:match("^%s*[^%s].*then%s+[^=]*=%s*function") then
        return nil
    end

    -- Look for function definitions
    local functionName, params = line:match("function%s+([%w_.]+)%s*%(([^)]*)%)")
    if functionName then
        local paramList = {}
        if params and params ~= "" then
            for param in params:gmatch("([^,]+)") do
                local cleanParam = param:gsub("^%s*", ""):gsub("%s*$", "")
                table.insert(paramList, cleanParam)
            end
        end

        return {
            name = functionName,
            params = paramList,
            fullLine = line
        }
    end -- Look for table function assignments (but not inline assignments)
    -- Only match top-level assignments (minimal indentation) and exclude conditionals
    if line:match("^[%w_.]+%s*=%s*function") or line:match("^%s%s?[%w_.]+%s*=%s*function") then
        if not line:match("if%s+") and not line:match("%s+then%s+") and
            not line:match("then%s+") and not line:match("%s+if%s+") and
            not line:match("^%s%s%s%s") then -- Exclude deeply indented lines (4+ spaces)
            functionName, params = line:match("^%s*([%w_.]+)%s*=%s*function%s*%(([^)]*)%)")
            if functionName then
                local paramList = {}
                if params and params ~= "" then
                    for param in params:gmatch("([^,]+)") do
                        local cleanParam = param:gsub("^%s*", ""):gsub("%s*$", "")
                        table.insert(paramList, cleanParam)
                    end
                end

                return {
                    name = functionName,
                    params = paramList,
                    fullLine = line
                }
            end
        end
    end

    return nil
end

-- Parse @generic annotation with sophisticated type information
-- @param commentText string Comment text
-- @return table Generic information
function SelfContainedParser.parseGenericAnnotation(commentText)
    local name = commentText:match("^@generic%s+([%w_]+)")
    if name then
        return { name = name, type = "any" }
    end
    return nil
end

-- Parse @param annotation with complex types
-- @param commentText string Comment text
-- @return table Parameter information
function SelfContainedParser.parseParamAnnotation(commentText)
    -- Enhanced param parsing for complex union types
    -- Pattern: @param name type [description]
    local pattern = "^@param%s+([%w_]+)%s+(.+)"
    local name, rest = commentText:match(pattern)

    if name and rest then
        local paramType = rest
        local description = ""

        -- Check if there's a description after a # comment
        local typeWithComment = rest:match("^(.-)%s*#%s*(.+)")
        if typeWithComment then
            paramType = typeWithComment
            description = rest:match("#%s*(.+)") or ""
        end

        -- Clean up the type - remove trailing whitespace
        paramType = paramType:gsub("%s*$", "")

        return {
            name = name,
            type = paramType,
            description = description,
            optional = paramType:match("%?") ~= nil
        }
    end

    return nil
end

-- Parse @return annotation
-- @param commentText string Comment text
-- @return table Return information
function SelfContainedParser.parseReturnAnnotation(commentText)
    local returnType, description = commentText:match("^@return%s+([%S]+)%s*(.*)")
    if returnType then
        return {
            type = returnType,
            description = description or ""
        }
    end
    return { type = "any", description = "" }
end

-- Create rich function documentation with sophisticated type information
-- @param funcInfo table Basic function information
-- @param docInfo table Rich JSDoc documentation
-- @return table Sophisticated function documentation
function SelfContainedParser.createRichFunction(funcInfo, docInfo)
    local richFunc = {
        name = funcInfo.name,
        params = {},
        returns = { type = "any", description = "" },
        generics = {},
        description = "No description available.",
        examples = {},
        notes = {},
        performance = {},
        typeDefinitions = {},
        behaviorNotes = {}
    }

    if docInfo then
        richFunc.description = table.concat(docInfo.description, " ") or "No description available."
        richFunc.returns = docInfo.returns
        richFunc.generics = docInfo.generics
        richFunc.examples = docInfo.examples
        richFunc.notes = docInfo.notes
        richFunc.performance = docInfo.performance
        richFunc.typeDefinitions = docInfo.typeDefinitions
        richFunc.behaviorNotes = docInfo.behaviorNotes

        -- Merge function params with doc params
        for i, funcParam in ipairs(funcInfo.params) do
            local docParam = nil
            for _, dp in ipairs(docInfo.params) do
                if dp.name == funcParam then
                    docParam = dp
                    break
                end
            end

            if docParam then
                table.insert(richFunc.params, {
                    name = funcParam,
                    type = docParam.type,
                    description = docParam.description,
                    optional = docParam.optional
                })
            else
                table.insert(richFunc.params, {
                    name = funcParam,
                    type = "any",
                    description = "",
                    optional = false
                })
            end
        end
    else
        -- No documentation, use basic function info
        for _, param in ipairs(funcInfo.params) do
            table.insert(richFunc.params, {
                name = param,
                type = "any",
                description = "",
                optional = false
            })
        end
    end

    return richFunc
end

-- ======================
-- SOPHISTICATED TEMPLATE ENGINE
-- ======================

-- Sophisticated template engine for rich MediaWiki output
local SophisticatedTemplateEngine = {}

-- Generate sophisticated documentation matching the user's format
-- @param moduleName string Name of the module
-- @param functions table Array of sophisticated function objects
-- @return string Rich MediaWiki documentation
function SophisticatedTemplateEngine.generateSophisticatedDoc(moduleName, functions)
    -- Apply hierarchical sorting to functions
    HierarchicalSorter.sortFunctionsHierarchically(functions, {
        debug = {
            showObjectDetection = false,
            showSortingOrder = false
        }
    })

    local parts = {}

    -- Header
    table.insert(parts, "{{Documentation}}")
    table.insert(parts, "{{Helper module")
    table.insert(parts, "|name = " .. moduleName)
    table.insert(parts, "")

    -- Process each function
    for i, func in ipairs(functions) do
        -- Add newline before each function entry (except the first)
        if i > 1 then
            table.insert(parts, "")
        end

        -- Function name with nowiki tags and proper spacing
        local functionSignature = SophisticatedTemplateEngine.generateFunctionSignature(func)
        table.insert(parts, string.format("|fname%d = %s", i, functionSignature))

        -- Type signature with complex formatting
        local typeSignature = SophisticatedTemplateEngine.generateSophisticatedTypeSignature(func)
        table.insert(parts, string.format("|ftype%d = %s", i, typeSignature))

        -- Rich description with type definitions, examples, and performance notes
        local richDescription = SophisticatedTemplateEngine.generateRichDescription(func)
        table.insert(parts, string.format("|fuse%d = %s", i, richDescription))
    end

    -- Footer
    table.insert(parts, "}}")

    return table.concat(parts, "\n")
end

-- Generate function signature with proper nowiki formatting using functional composition
-- @param funcObj table Function documentation
-- @return string Formatted function signature
function SophisticatedTemplateEngine.generateFunctionSignature(funcObj)
    local paramNames = func.map(function(param) return param.name end, funcObj.params)

    -- Remove module prefix using functional composition
    local cleanFunctionName = func.pipe(
        function(name) return name:match("^[^%.]+%.") and name:gsub("^[^%.]+%.", "") or name end
    )(funcObj.name)

    local params = table.concat(paramNames, ", ")
    local signature = string.format("%s(&nbsp;%s&nbsp;)", cleanFunctionName, params)

    -- Escape pipes using functional processing
    local escapedSignature = StringProcessors.escapePipes(signature)
    return "<nowiki>" .. escapedSignature .. "</nowiki>"
end

-- Generate sophisticated type signature with generics and union types
-- @param func table Function documentation
-- @return string Sophisticated type signature
function SophisticatedTemplateEngine.generateSophisticatedTypeSignature(func)
    local parts = {}

    -- Add generics
    if #func.generics > 0 then
        for _, generic in ipairs(func.generics) do
            table.insert(parts, string.format("<samp>generic: %s</samp>", generic.name))
        end
    end

    -- Add parameter types
    for _, param in ipairs(func.params) do
        local paramType = param.type

        -- Handle optional parameters
        if param.optional and not paramType:match("%?") then
            paramType = paramType .. "?"
        end

        -- Format complex union types with {{!}} separators
        -- Handle both spaced and unspaced pipes to avoid double spaces
        paramType = paramType:gsub("%s*|%s*", " {{!}} ")

        -- Format array types with backticks (only if not already present)
        if not paramType:match("Array<`") then
            paramType = paramType:gsub("Array<([^>]+)>", "Array<`%1`>")
        end

        table.insert(parts, string.format("<samp>%s: %s</samp>", param.name, paramType))
    end

    -- Add return type
    local returnType = func.returns.type
    returnType = returnType:gsub("%s*|%s*", " {{!}} ")
    -- Format array types with backticks (only if not already present)
    if not returnType:match("Array<`") then
        returnType = returnType:gsub("Array<([^>]+)>", "Array<`%1`>")
    end
    table.insert(parts, string.format("<samp>-> %s</samp>", returnType))

    return table.concat(parts, "<br>")
end

-- Generate rich description with type definitions, examples, and performance notes using functional processing
-- @param funcObj table Function documentation
-- @return string Rich description with MediaWiki formatting
function SophisticatedTemplateEngine.generateRichDescription(funcObj)
    local parts = {}
    local formatDesc = StringProcessors.formatDescription({ convertInlineCode = true })

    -- Main description
    local description = funcObj.description or "No description available."
    table.insert(parts, formatDesc(description))

    -- Behavior notes using functional processing
    if #funcObj.behaviorNotes > 0 then
        table.insert(parts, "")
        func.each(function(behavior)
            table.insert(parts, formatDesc(behavior))
        end)(funcObj.behaviorNotes)
    end

    -- Type definitions section
    if #funcObj.typeDefinitions > 1 or (#funcObj.params > 0 and SophisticatedTemplateEngine.hasRichTypeDefinitions(funcObj)) then
        table.insert(parts, "")
        table.insert(parts, "Type definitions:")

        -- Add type definitions from documentation
        func.each(function(typeDef)
            if not typeDef:match("^Type definitions:") then
                table.insert(parts, typeDef)
            end
        end)(funcObj.typeDefinitions)

        -- Add parameter descriptions as type definitions using functional map
        func.each(function(param)
            if param.description and param.description ~= "" then
                local typeDefStr = string.format("* %s: %s", param.name, formatDesc(param.description))
                table.insert(parts, typeDefStr)
            end
        end)(funcObj.params)
    end

    -- Performance characteristics using functional processing
    if #funcObj.performance > 0 then
        table.insert(parts, "")
        table.insert(parts, "Performance characteristics:")
        func.each(function(perf)
            table.insert(parts, "* " .. formatDesc(perf))
        end)(funcObj.performance)
    end

    -- Examples
    if #funcObj.examples > 0 then
        table.insert(parts, "")
        table.insert(parts, "Examples:")
        func.each(function(example)
            local lang = example.lang or "lua"
            table.insert(parts, string.format("<syntaxhighlight lang='%s'>", lang))
            table.insert(parts, example.code)
            table.insert(parts, "</syntaxhighlight>")
        end)(funcObj.examples)
    end

    -- Additional notes using functional processing
    if #funcObj.notes > 0 then
        table.insert(parts, "")
        func.each(function(note)
            table.insert(parts, formatDesc(note))
        end)(funcObj.notes)
    end

    -- Escape MediaWiki pipe characters using functional transformation
    local finalDescription = table.concat(parts, "\n")
    return StringProcessors.escapePipes(finalDescription)
end

-- Check if function has rich type definitions worth displaying
-- @param func table Function documentation
-- @return boolean True if has rich type definitions
function SophisticatedTemplateEngine.hasRichTypeDefinitions(func)
    for _, param in ipairs(func.params) do
        if param.description and param.description ~= "" then
            return true
        end
    end
    return false
end

-- ======================
-- FUNCTIONAL MAIN GENERATION PIPELINE
-- ======================

-- Functional pipeline for documentation generation
local DocumentationPipeline = {}

-- Read file using Maybe monad pattern
DocumentationPipeline.readFile = function(filePath)
    local file = io.open(filePath, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end

-- Parse content using functional composition
DocumentationPipeline.parseContent = function(content)
    return SelfContainedParser.parseRichDocumentation(content)
end

-- Generate documentation using curried functions
DocumentationPipeline.generateDoc = func.curry(function(moduleName, parseResult)
    return SophisticatedTemplateEngine.generateSophisticatedDoc(moduleName, parseResult.functions)
end)

-- Write file using functional error handling
DocumentationPipeline.writeFile = func.curry(function(outputPath, content)
    local file = io.open(outputPath, "w")
    if not file then return false end
    file:write(content)
    file:close()
    return true
end)

-- Main processing pipeline using functional composition
DocumentationPipeline.processModule = func.curry(function(config, moduleName)
    local inputFile = config.sourceDir .. "/" .. moduleName .. ".lua"
    local outputFile = config.outputDir .. "/" .. moduleName .. config.extension

    if config.verbose then
        print("📖 Processing: " .. inputFile)
    end

    -- Functional pipeline: read -> parse -> generate -> write
    local content = DocumentationPipeline.readFile(inputFile)
    if not content then
        print("❌ Error: Module file not found: " .. inputFile)
        return false
    end

    local parseResult = DocumentationPipeline.parseContent(content)

    if config.verbose then
        print(string.format("📊 Found %d functions with sophisticated documentation", parseResult.totalFunctions))
    end

    local documentation = DocumentationPipeline.generateDoc(moduleName, parseResult)
    local success = DocumentationPipeline.writeFile(outputFile, documentation)

    if not success then
        print("❌ Error: Could not write output file: " .. outputFile)
        return false
    end

    if config.verbose then
        print("✅ Generated sophisticated documentation: " .. outputFile)
        print(string.format("📏 Documentation size: %d bytes", #documentation))
    end

    return true
end)

-- Generate sophisticated documentation using functional pipeline
local generateSophisticatedModuleDoc = DocumentationPipeline.processModule(config)

-- ======================
-- FUNCTIONAL COMMAND LINE INTERFACE
-- ======================

local function main(...)
    print("🎨 Functional MediaWiki Documentation Generator")
    print("==============================================")

    local args = { ... }
    local moduleName = args[1]

    if moduleName then
        -- Generate for specific module using functional pipeline
        local success = generateSophisticatedModuleDoc(moduleName)
        if success then
            print("✅ Documentation generated for " .. moduleName)
        else
            print("❌ Failed to generate documentation for " .. moduleName)
            os.exit(1)
        end
    else
        -- Generate for all modules using functional processing
        print("🔄 Generating documentation for all modules...")

        -- Get all modules using functional approach
        local modules = {}
        local handle = io.popen("find " .. config.sourceDir .. " -name '*.lua' -type f")
        if handle then
            for file in handle:lines() do
                local name = file:match("([^/]+)%.lua$")
                if name then table.insert(modules, name) end
            end
            handle:close()
        end

        -- Process all modules using functional map pattern
        local results = func.map(generateSophisticatedModuleDoc, modules)
        local successCount = func.reduce(function(acc, success)
            return success and acc + 1 or acc
        end, 0, results)

        print(string.format("✅ Generated documentation for %d/%d modules", successCount, #modules))
    end
end

-- Run the functional generator
main(...)
