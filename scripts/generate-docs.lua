--[[
Documentation Generator for MediaWiki Lua Modules
Extracts function documentation from Lua modules and generates HTML documentation
similar to Array.html.

Usage: lua generate-docs.lua [module_name]
If module_name is not provided, generates documentation for all modules.
]]

local lfs = require('lfs') -- LuaFileSystem for file operations

-- Configuration
local SOURCE_DIR = "../src/modules"
local DOCS_DIR = "../src/module-docs"

-- Helper function to read a file's contents
local function readFile(filename)
    local file = io.open(filename, "r")
    if not file then
        return nil
    end
    local content = file:read("*all")
    file:close()
    return content
end

-- Helper function to write to a file
local function writeFile(filename, content)
    local file = io.open(filename, "w")
    if not file then
        error("Could not open file for writing: " .. filename)
    end
    file:write(content)
    file:close()
end

-- Helper function to ensure a directory exists
local function ensureDirectory(path)
    local success = lfs.mkdir(path)
    return success
end

-- Helper function to count asterisks and dashes before the first word character
local function countPrefixSymbols(commentText)
    local count = 0

    -- Examine each character until we find a word character
    for i = 1, #commentText do
        local char = commentText:sub(i, i)

        -- Count asterisks and dashes
        if char == "*" or char == "-" then
            count = count + 1
            -- Skip spaces without incrementing count
        elseif char:match("%s") then
            -- continue past spaces
            -- Stop counting when we hit any word character or other symbols
        else
            break
        end
    end

    return count
end

-- Helper function to generate a string with exactly N asterisks
local function generateAsterisks(count)
    return string.rep("*", count)
end

-- Helper function to trim all characters before the first word character
local function trimLeadingNonWordChars(str)
    if not str or type(str) ~= "string" then
        return str
    end

    -- Find the position of the first character that is not whitespace, dash, or asterisk
    local firstWordPos = str:find("[^%s%-%*]")

    -- If no word character is found, return empty string
    if not firstWordPos then
        return ""
    end

    -- Return the substring starting from the first word character
    return str:sub(firstWordPos)
end

-- Parse function documentation from Lua comments
-- Returns a table of functions with their documentation
local function parseFunctionDocs(content)
    local functions = {}
    local currentFunction = nil
    local functionCount = 0
    local inCommentBlock = false
    local inExampleBlock = false

    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    for i = 1, #lines do
        local line = lines[i]

        if line:match("^%s*%-%-%-") then
            local commentText = line:gsub("^%s*%-%-%-", ""):gsub("^(.-)%s*$", "%1")

            if not inCommentBlock then
                inCommentBlock = true
                currentFunction = {
                    description = {},
                    params = {},
                    returns = {},
                    generics = {}, -- Initialize generics map
                    notes = {}     -- Initialize notes collection
                }
            end

            if not currentFunction then
                error("Internal parser error: currentFunction not initialized within comment block.")
            end

            -- Ignore whitespace-only lines
            if commentText:match("^%s*$") then
                -- Skip empty lines
                -- Check for @generic, @param, @return
            elseif commentText:match("^@generic%s+") then
                local genericName, genericType = commentText:match("^@generic%s+([%w_]+)%s*:%s*(.+)$")
                if genericName then
                    table.insert(currentFunction.generics, {
                        name = genericName,
                        type = genericType:match("^%s*(.-)%s*$")
                    })
                end
            elseif commentText:match("^@param%s+") then
                local paramName, paramType, paramDesc = commentText:match("^@param%s+([%S]+)%s+([%S]+)%s*(.*)")
                if paramName then
                    table.insert(currentFunction.params, {
                        name = paramName,
                        type = paramType,
                        description = paramDesc or ""
                    })
                end
            elseif commentText:match("^@return%s+") then
                local returnType, returnDesc = commentText:match("^@return%s+([%S]+)%s*(.*)")
                if returnType then
                    currentFunction.returns.type = returnType
                    currentFunction.returns.description = returnDesc or ""
                end
                -- Ignore other @ directives
            elseif commentText:match("^@[%w_]+") then
                -- Skip other @ directives
                -- Handle the first line as description (if it's not already something else)
            elseif #currentFunction.description == 0 then
                table.insert(currentFunction.description, commentText)
                -- Handle notes - anything that isn't a directive is a note
            elseif commentText:match("^```") then
                if not inExampleBlock then
                    inExampleBlock = true
                    table.insert(currentFunction.notes, "<syntaxhighlight lang='lua'>")
                else
                    inExampleBlock = false
                    table.insert(currentFunction.notes, "</syntaxhighlight>")
                end
            else
                if inExampleBlock then
                    table.insert(currentFunction.notes, commentText)
                else
                    local asterisks = generateAsterisks(countPrefixSymbols(commentText) + 1)
                    local formattedNote = asterisks .. " " .. trimLeadingNonWordChars(commentText)
                    table.insert(currentFunction.notes, formattedNote)
                end
            end
        elseif inCommentBlock then
            local funcName, funcParams
            local isNonLocalFunction = false

            -- Try Pattern 1: function Foo(...) or function Module.Foo(...)
            -- This pattern matches functions not explicitly marked 'local'.
            local p1_funcName, p1_funcParams = line:match("^%s*function%s+([%w_%.:]+)%s*%((.-)%)")
            if p1_funcName then
                -- Extract the simple function name (after the last dot if present)
                local simpleName = p1_funcName:match("%.([^%.]+)$") or p1_funcName
                -- Skip functions whose simple name starts with double underscore
                if not simpleName:match("^__") then
                    funcName = p1_funcName
                    funcParams = p1_funcParams
                    isNonLocalFunction = true
                end
            end

            if not isNonLocalFunction then
                -- Try Pattern 3: Foo = function(...) or Module.Foo = function(...)
                -- Check if this assignment is to a non-local variable.
                local p3_funcName, p3_funcParams = line:match("^%s*([%w_%.:]+)%s*=%s*function%s*%((.-)%)")
                if p3_funcName then
                    -- Extract the simple name (after the last dot if present)
                    local simpleName = p3_funcName:match("%.([^%.]+)$") or p3_funcName
                    local escaped_p3_funcName = p3_funcName:gsub("([%(%)%.%%%+%-%*%?%[%^%$%]])", "%%%1")
                    if not line:match("^%s*local%s+" .. escaped_p3_funcName) and not simpleName:match("^__") then
                        funcName = p3_funcName
                        funcParams = p3_funcParams
                        isNonLocalFunction = true
                    end
                end
            end

            if isNonLocalFunction then
                inCommentBlock = false -- Successfully associated comment with a non-local function
                functionCount = functionCount + 1
                currentFunction.name = funcName:gsub("^%s*(.-)%s*$", "%1")
                currentFunction.params_str = funcParams or ""
                local simpleName = currentFunction.name:match("%.([^%.]+)$") or currentFunction.name
                currentFunction.simple_name = simpleName
                functions[functionCount] = currentFunction
                currentFunction = nil -- Ready for next potential comment block
            else
                -- This line is not a non-local function we want to document, or not a function line at all.
                -- If it's not a blank line or a line that could be part of multi-line comment continuation (heuristically),
                -- abandon the current comment block.
                if not (line:match("^%s*$") or i < #lines - 3) then
                    inCommentBlock = false
                    currentFunction = nil
                end
            end
        end
    end
    return functions, functionCount
end

-- Helper function to escape MediaWiki pipe characters
local function escapePipes(str)
    if type(str) ~= "string" then return str end
    return str:gsub("|", "{{!}}")
end

-- Format function documentation into MediaWiki template format
local function formatFunctionDoc(func, index, moduleName)
    local result = {}

    -- Extract the function name without the module prefix
    local displayName = func.name
    if displayName:find("^" .. moduleName .. "%.") then
        displayName = displayName:sub(#moduleName + 2) -- +2 accounts for the dot after module name
    end

    local fname = displayName .. "(&nbsp;" .. func.params_str .. "&nbsp;)"
    table.insert(result, string.format("|fname%d = <nowiki>%s</nowiki>", index, escapePipes(fname)))

    local ftypeParts = {}
    if func.generics then
        for _, generic in ipairs(func.generics) do
            table.insert(ftypeParts,
                string.format("<samp>%s: %s</samp>", escapePipes(generic.name), escapePipes(generic.type)))
        end
    end
    if func.params then
        for _, param in ipairs(func.params) do
            table.insert(ftypeParts,
                string.format("<samp>%s: %s</samp>", escapePipes(param.name), escapePipes(param.type)))
        end
    end

    local rType = (func.returns and func.returns.type) or "any"
    table.insert(ftypeParts, string.format("<samp>-> %s</samp>", escapePipes(rType)))

    local ftype = table.concat(ftypeParts, "<br>")
    table.insert(result, string.format("|ftype%d = %s", index, ftype))

    local descriptionText
    if func.description and #func.description > 0 then
        descriptionText = table.concat(func.description, "\n") -- Concatenate with newlines
    else
        descriptionText = ""
    end

    if not descriptionText or descriptionText == "" then
        descriptionText = "No description available."
    else
        -- 1. Convert single backtick inline code
        descriptionText = descriptionText:gsub("`([^`]+)`", "<code>%1</code>")

        -- 2. Existing: Add newline before single asterisks for MediaWiki list formatting
        descriptionText = descriptionText:gsub("%*", "\n*")
    end

    table.insert(result, string.format("|fuse%d = %s", index, descriptionText))

    -- Add function notes if available
    if func.notes and #func.notes > 0 then
        -- Add a newline
        table.insert(result, "")
        for _, note in ipairs(func.notes) do
            -- Convert single backtick inline code in notes
            note = note:gsub("`([^`]+)`", "<code>%1</code>")
            if not note:find("<math>") then
                note = escapePipes(note)
            end
            table.insert(result, note)
        end
    end

    return table.concat(result, "\n")
end

-- Generate HTML documentation for a module
local function generateModuleDoc(moduleName, content)
    local functions, count = parseFunctionDocs(content)
    if count == 0 then
        print("  Warning: No functions found with documentation in " .. moduleName)
        return nil
    end

    -- Sort functions alphabetically by simple_name
    table.sort(functions, function(a, b)
        return a.simple_name < b.simple_name
    end)

    local docContent = {}
    table.insert(docContent, "{{Documentation}}")
    table.insert(docContent, "{{Helper module")
    table.insert(docContent, "|name = " .. moduleName)
    table.insert(docContent, "")

    -- Add each function's documentation with the new sorted order
    for i = 1, count do
        local func = functions[i]
        if func then
            table.insert(docContent, formatFunctionDoc(func, i, moduleName))
            table.insert(docContent, "")
        end
    end

    table.insert(docContent, "|example =")
    table.insert(docContent, "<syntaxhighlight lang='lua'>")
    table.insert(docContent, "    -- Example usage of " .. moduleName .. " will be added manually")
    table.insert(docContent, "</syntaxhighlight>")
    table.insert(docContent, "}}")

    return table.concat(docContent, "\n")
end

-- Main function to process a single module
local function processModule(filename)
    local moduleName = filename:match("(.+)%.lua$")
    if not moduleName then return end

    print("Processing module: " .. moduleName)

    local sourcePath = SOURCE_DIR .. "/" .. filename
    local content = readFile(sourcePath)
    if not content then
        print("  Error: Could not read file: " .. sourcePath)
        return
    end

    local docContent = generateModuleDoc(moduleName, content)
    if not docContent then return end

    local docPath = DOCS_DIR .. "/" .. moduleName .. ".html"
    print("  Writing documentation to: " .. docPath)
    writeFile(docPath, docContent)
end

-- Main function to process all modules
local function processAllModules()
    print("Generating documentation for all modules...")
    ensureDirectory(DOCS_DIR)

    for file in lfs.dir(SOURCE_DIR) do
        if file:match("%.lua$") then
            processModule(file)
        end
    end

    print("Documentation generation complete!")
end

-- Process a specific module or all modules
local function main()
    local moduleName = nil

    for i = 1, #arg do
        if not moduleName then -- First non-flag argument is module name
            moduleName = arg[i]
        end
    end

    if moduleName then
        local filename = moduleName .. ".lua"
        processModule(filename)
    else
        processAllModules()
    end
end

main()
