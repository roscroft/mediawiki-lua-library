--[[
Type Annotation Parser for Documentation Generation
Handles parsing of complex JSDoc type annotations including nested function types.
]]

local TypeParser = {}

-- Parse complex return types with nested parentheses support
-- Handles complex function types like: fun(g: fun(a: A): B): fun(h: fun(a: A): C): fun(a: A): D
-- @param commentText string The @return annotation text
-- @return string|nil, string|nil Return type and description
function TypeParser.parseComplexReturnType(commentText)
    -- Extract the part after @return
    local afterReturn = commentText:match("^@return%s+(.*)$")
    if not afterReturn then
        return nil, nil
    end

    -- For complex nested function types, we need to be very careful about parsing
    -- Look for actual descriptive words at the end, not type keywords
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

-- Parse @param annotation
-- @param commentText string The @param annotation text
-- @return table|nil Parameter information {name, type, description}
function TypeParser.parseParameter(commentText)
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

-- Parse @generic annotation
-- @param commentText string The @generic annotation text
-- @return table|nil Generic information {name, type}
function TypeParser.parseGeneric(commentText)
    local genericName, genericType = commentText:match("^@generic%s+([%w_]+)%s*:%s*(.+)$")
    if genericName then
        return {
            name = genericName,
            type = genericType:match("^%s*(.-)%s*$")
        }
    end
    return nil
end

-- Check if a comment line is a JSDoc directive
-- @param commentText string The comment text to check
-- @return boolean True if this is a JSDoc directive
function TypeParser.isJSDocDirective(commentText)
    return commentText:match("^@[%w_]+") ~= nil
end

-- Check if a comment line is a code block marker
-- @param commentText string The comment text to check
-- @return boolean True if this is a code block marker
function TypeParser.isCodeBlock(commentText)
    return commentText:match("^```") ~= nil
end

return TypeParser
