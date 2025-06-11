--[[
Text Processing Utilities for Documentation Generation
Provides string manipulation and formatting functions for documentation processing.
]]

local TextUtils = {}

-- Count asterisks and dashes before the first word character
-- @param commentText string Text to analyze
-- @return number Count of prefix symbols
function TextUtils.countPrefixSymbols(commentText)
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

-- Generate a string with exactly N asterisks
-- @param count number Number of asterisks to generate
-- @return string String containing the specified number of asterisks
function TextUtils.generateAsterisks(count)
    return string.rep("*", count)
end

-- Trim all characters before the first word character
-- @param str string String to trim
-- @return string Trimmed string
function TextUtils.trimLeadingNonWordChars(str)
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

-- Escape MediaWiki pipe characters
-- @param str string String to escape
-- @return string String with pipes escaped
function TextUtils.escapePipes(str)
    if type(str) ~= "string" then
        return str
    end
    return str:gsub("|", "{{!}}")
end

-- Split text into lines
-- @param text string Text to split
-- @return table Array of lines
function TextUtils.splitLines(text)
    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    return lines
end

-- Join array of strings with separator
-- @param parts table Array of strings to join
-- @param separator string Separator to use between parts
-- @return string Joined string
function TextUtils.join(parts, separator)
    return table.concat(parts, separator or "")
end

-- Check if string is empty or whitespace only
-- @param str string String to check
-- @return boolean True if string is empty or whitespace only
function TextUtils.isEmpty(str)
    return not str or str:match("^%s*$") ~= nil
end

-- Format a list of items with a custom formatter function
-- @param items table Array of items to format
-- @param formatter function Function to format each item
-- @return table Array of formatted items
function TextUtils.formatList(items, formatter)
    local result = {}
    for _, item in ipairs(items) do
        table.insert(result, formatter(item))
    end
    return result
end

return TextUtils
