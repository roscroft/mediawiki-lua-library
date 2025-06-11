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

-- Parse complex return types with nested parentheses support
-- Handles complex function types like: fun(g: fun(a: A): B): fun(h: fun(a: A): C): fun(a: A): D
local function parseComplexReturnType(commentText)
    -- Extract the part after @return
    local afterReturn = commentText:match("^@return%s+(.*)$")
    if not afterReturn then
        return nil, nil
    end

    -- For complex nested function types, we need to be very careful about parsing
    -- Look for actual descriptive words at the end, not type keywords
    local typeEnd = #afterReturn
    local words = {}

    -- Split into words and identify the boundary between type and description
    for word in afterReturn:gmatch("%S+") do
        table.insert(words, word)
    end

    -- Work backwards from the end to find where the description starts
    local descStartIndex = nil
    for i = #words, 1, -1 do
        local word = words[i]

        -- Check if this word looks like a description word (not a type)
        -- Common description starters
        if word:match("^[A-Z][a-z]+") and not word:match("^(Maybe|Result|Array|Function|Table|String|Number|Boolean|Any|Nil)") then
            -- This looks like the start of a description
            descStartIndex = i
        elseif word:match("^(that|which|to|for|with|by|using|when|if|returns|applies|creates|performs|computes|calculates|generates|transforms)$") then
            -- Common description words
            descStartIndex = i
            break
        end
    end

    local returnType, returnDesc

    if descStartIndex then
        -- Reconstruct the type from words 1 to descStartIndex-1
        local typeWords = {}
        for i = 1, descStartIndex - 1 do
            table.insert(typeWords, words[i])
        end
        returnType = table.concat(typeWords, " ")

        -- Reconstruct the description from descStartIndex onwards
        local descWords = {}
        for i = descStartIndex, #words do
            table.insert(descWords, words[i])
        end
        returnDesc = table.concat(descWords, " ")
    else
        -- No clear description found, treat the whole thing as type
        returnType = afterReturn
        returnDesc = ""
    end

    -- Clean up whitespace
    returnType = returnType:gsub("^%s*(.-)%s*$", "%1")
    returnDesc = returnDesc:gsub("^%s*(.-)%s*$", "%1")

    return returnType, returnDesc
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
                local returnType, returnDesc = parseComplexReturnType(commentText)
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

-- Helper function to detect main object names from function names
local function detectObjectNames(functions)
    local objectCounts = {}
    local totalFunctions = 0

    for _, func in ipairs(functions) do
        totalFunctions = totalFunctions + 1
        local fullName = func.name

        -- Extract potential object names (before first dot)
        local objectName = fullName:match("^([^%.]+)%.")
        if objectName then
            objectCounts[objectName] = (objectCounts[objectName] or 0) + 1
        end
    end

    -- Find the primary object name (most frequently used, minimum 30% of functions)
    local primaryObject = nil
    local maxCount = 0
    local threshold = math.floor(totalFunctions * 0.3)

    for objName, count in pairs(objectCounts) do
        if count > maxCount and count >= threshold then
            maxCount = count
            primaryObject = objName
        end
    end

    return primaryObject, objectCounts
end

-- Helper function to parse hierarchical function name structure
local function parseHierarchicalName(functionName, primaryObject)
    -- Remove module prefix if present (e.g., "Module.func.ops.add" -> "func.ops.add")
    local cleanName = functionName:gsub("^[^%.]*%.", "", 1)

    -- Split by dots to get hierarchy levels
    local parts = {}
    for part in cleanName:gmatch("[^%.]+") do
        table.insert(parts, part)
    end

    if #parts == 0 then
        return {
            depth = 0,
            objectPath = "",
            subPath = "",
            functionName = functionName,
            sortKey = "0000_" .. functionName
        }
    end

    local funcName = parts[#parts] -- Last part is the function name
    local objectPath = ""
    local subPath = ""

    if #parts > 1 then
        -- Build object path (all parts except the last)
        local pathParts = {}
        for i = 1, #parts - 1 do
            table.insert(pathParts, parts[i])
        end
        objectPath = table.concat(pathParts, ".")

        -- Extract subpath (everything after primary object)
        if primaryObject and objectPath:find("^" .. primaryObject .. "%.") then
            subPath = objectPath:sub(#primaryObject + 2) -- +2 to skip the dot
        elseif primaryObject and objectPath == primaryObject then
            subPath = ""
        else
            subPath = objectPath
        end
    end

    local depth = #parts - 1

    -- Create sort key: depth (descending) + object path (ascending) + function name (ascending)
    -- Format: 9999-depth_objectpath_functionname
    local depthKey = string.format("%04d", 9999 - depth)
    local sortKey = depthKey .. "_" .. objectPath .. "_" .. funcName

    return {
        depth = depth,
        objectPath = objectPath,
        subPath = subPath,
        functionName = funcName,
        sortKey = sortKey
    }
end

-- Advanced hierarchical sorting function
local function sortFunctionsHierarchically(functions)
    -- Detect primary object names
    local primaryObject, objectCounts = detectObjectNames(functions)

    print(string.format("  Detected primary object: %s", primaryObject or "none"))
    if primaryObject then
        print(string.format("  Object usage counts: %s=%d", primaryObject, objectCounts[primaryObject]))
        for obj, count in pairs(objectCounts) do
            if obj ~= primaryObject then
                print(string.format("    %s=%d", obj, count))
            end
        end
    end

    -- Parse hierarchical structure for each function
    for _, func in ipairs(functions) do
        func.hierarchy = parseHierarchicalName(func.name, primaryObject)
    end

    -- Sort by hierarchical criteria
    table.sort(functions, function(a, b)
        local aHier, bHier = a.hierarchy, b.hierarchy

        -- Primary sort: by depth (descending - deeper hierarchies first)
        if aHier.depth ~= bHier.depth then
            return aHier.depth > bHier.depth
        end

        -- Secondary sort: by object path (ascending - alphabetical)
        if aHier.objectPath ~= bHier.objectPath then
            return aHier.objectPath < bHier.objectPath
        end

        -- Tertiary sort: by function name (ascending - alphabetical)
        return aHier.functionName < bHier.functionName
    end)

    -- Debug output
    print("  Function sorting order:")
    for i, func in ipairs(functions) do
        local h = func.hierarchy
        print(string.format("    %d. %s (depth=%d, path='%s', func='%s')",
            i, func.name, h.depth, h.objectPath, h.functionName))
        if i > 10 then
            print(string.format("    ... and %d more functions", #functions - 10))
            break
        end
    end
end

-- Generate HTML documentation for a module
local function generateModuleDoc(moduleName, content)
    local functions, count = parseFunctionDocs(content)
    if count == 0 then
        print("  Warning: No functions found with documentation in " .. moduleName)
        return nil
    end

    -- Sort functions using sophisticated hierarchical sorting
    sortFunctionsHierarchically(functions)

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
