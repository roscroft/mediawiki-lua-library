--[[
Comment Parser for Documentation Generation
Handles parsing of JSDoc comment blocks with state machine logic.
]]

local TypeParser = require('parsers.type-parser')
local TextUtils = require('utils.text-utils')

local CommentParser = {}
CommentParser.__index = CommentParser

-- Comment parser states
CommentParser.State = {
    OUTSIDE = "outside",
    IN_COMMENT = "in_comment",
    IN_EXAMPLE = "in_example"
}

-- Create a new comment parser instance
-- @return table New parser instance
function CommentParser.new()
    local self = {
        state = CommentParser.State.OUTSIDE,
        currentDoc = nil,
        inExampleBlock = false
    }
    setmetatable(self, CommentParser)
    return self
end

-- Initialize a new documentation block
-- @return table New documentation structure
function CommentParser:initializeDoc()
    return {
        description = {},
        params = {},
        returns = {},
        generics = {},
        notes = {}
    }
end

-- Process a single line of text
-- @param line string Line to process
-- @return boolean True if line was processed as part of a comment block
function CommentParser:processLine(line)
    -- Check if this is a comment line
    if line:match("^%s*%-%-%-") then
        local commentText = line:gsub("^%s*%-%-%-", ""):gsub("^(.-)%s*$", "%1")

        if self.state == CommentParser.State.OUTSIDE then
            self.state = CommentParser.State.IN_COMMENT
            self.currentDoc = self:initializeDoc()
        end

        if not self.currentDoc then
            error("Internal parser error: currentDoc not initialized within comment block.")
        end

        return self:processCommentText(commentText)
    elseif self.state == CommentParser.State.IN_COMMENT then
        -- We were in a comment block but hit a non-comment line
        -- This might be the function definition
        return false
    end

    return false
end

-- Process the text content of a comment line
-- @param commentText string The comment text (without --- prefix)
-- @return boolean True if comment was processed
function CommentParser:processCommentText(commentText)
    -- Ignore whitespace-only lines
    if TextUtils.isEmpty(commentText) then
        return true
    end

    -- Handle JSDoc directives
    if commentText:match("^@generic%s+") then
        local generic = TypeParser.parseGeneric(commentText)
        if generic then
            table.insert(self.currentDoc.generics, generic)
        end
    elseif commentText:match("^@param%s+") then
        local param = TypeParser.parseParameter(commentText)
        if param then
            table.insert(self.currentDoc.params, param)
        end
    elseif commentText:match("^@return%s+") then
        local returnType, returnDesc = TypeParser.parseComplexReturnType(commentText)
        if returnType then
            self.currentDoc.returns.type = returnType
            self.currentDoc.returns.description = returnDesc or ""
        end
    elseif TypeParser.isJSDocDirective(commentText) then
        -- Skip other @ directives
        return true
    elseif TypeParser.isCodeBlock(commentText) then
        return self:handleCodeBlock()
    else
        return self:handleDescriptionOrNote(commentText)
    end

    return true
end

-- Handle code block markers (```)
-- @return boolean Always true
function CommentParser:handleCodeBlock()
    if not self.inExampleBlock then
        self.inExampleBlock = true
        table.insert(self.currentDoc.notes, "<syntaxhighlight lang='lua'>")
    else
        self.inExampleBlock = false
        table.insert(self.currentDoc.notes, "</syntaxhighlight>")
    end
    return true
end

-- Handle description text or notes
-- @param commentText string The comment text to process
-- @return boolean Always true
function CommentParser:handleDescriptionOrNote(commentText)
    -- Handle the first line as description (if it's not already something else)
    if #self.currentDoc.description == 0 then
        table.insert(self.currentDoc.description, commentText)
    else
        -- Handle notes - anything that isn't a directive is a note
        if self.inExampleBlock then
            table.insert(self.currentDoc.notes, commentText)
        else
            local asterisks = TextUtils.generateAsterisks(TextUtils.countPrefixSymbols(commentText) + 1)
            local formattedNote = asterisks .. " " .. TextUtils.trimLeadingNonWordChars(commentText)
            table.insert(self.currentDoc.notes, formattedNote)
        end
    end
    return true
end

-- Check if there's a complete documentation block ready
-- @return boolean True if documentation is complete and ready
function CommentParser:hasCompleteDoc()
    return self.state == CommentParser.State.IN_COMMENT and self.currentDoc ~= nil
end

-- Get the current documentation block and reset state
-- @return table|nil The current documentation or nil
function CommentParser:getCurrentDoc()
    local doc = self.currentDoc
    self:reset()
    return doc
end

-- Reset the parser state
function CommentParser:reset()
    self.state = CommentParser.State.OUTSIDE
    self.currentDoc = nil
    self.inExampleBlock = false
end

-- Abandon current comment block (when it doesn't lead to a function)
function CommentParser:abandonCurrentDoc()
    self:reset()
end

return CommentParser
