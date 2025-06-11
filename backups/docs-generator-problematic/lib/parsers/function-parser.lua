--[[
Function Definition Parser for Documentation Generation
Handles parsing and matching of various Lua function definition patterns.
]]

local FunctionParser = {}

-- Function definition patterns
FunctionParser.Patterns = {
    -- Pattern 1: function Foo(...) or function Module.Foo(...)
    FUNCTION_DECLARATION = "^%s*function%s+([%w_%.:]+)%s*%((.-)%)",
    -- Pattern 2: Foo = function(...) or Module.Foo = function(...)
    FUNCTION_ASSIGNMENT = "^%s*([%w_%.:]+)%s*=%s*function%s*%((.-)%)",
    -- Local function detection
    LOCAL_PREFIX = "^%s*local%s+"
}

-- Extract function information from a line of code
-- @param line string Line of Lua code to analyze
-- @return table|nil Function info {name, params, isPublic} or nil if no function found
function FunctionParser.extractFunctionInfo(line)
    local funcName, funcParams
    local isPublic = false

    -- Try Pattern 1: function Foo(...) or function Module.Foo(...)
    local p1_funcName, p1_funcParams = line:match(FunctionParser.Patterns.FUNCTION_DECLARATION)
    if p1_funcName then
        -- Extract the simple function name (after the last dot if present)
        local simpleName = p1_funcName:match("%.([^%.]+)$") or p1_funcName
        -- Skip functions whose simple name starts with double underscore
        if not simpleName:match("^__") then
            funcName = p1_funcName
            funcParams = p1_funcParams
            isPublic = true
        end
    end

    if not isPublic then
        -- Try Pattern 2: Foo = function(...) or Module.Foo = function(...)
        local p2_funcName, p2_funcParams = line:match(FunctionParser.Patterns.FUNCTION_ASSIGNMENT)
        if p2_funcName then
            -- Extract the simple name (after the last dot if present)
            local simpleName = p2_funcName:match("%.([^%.]+)$") or p2_funcName
            local escaped_p2_funcName = p2_funcName:gsub("([%(%)%.%%%+%-%*%?%[%^%$%]])", "%%%1")
            if not line:match(FunctionParser.Patterns.LOCAL_PREFIX .. escaped_p2_funcName) and not simpleName:match("^__") then
                funcName = p2_funcName
                funcParams = p2_funcParams
                isPublic = true
            end
        end
    end

    if isPublic then
        return {
            name = funcName:gsub("^%s*(.-)%s*$", "%1"),
            params = funcParams or "",
            isPublic = true
        }
    end

    return nil
end

-- Check if a function should be documented (is public and not internal)
-- @param functionName string Name of the function
-- @param line string The line where function is defined
-- @return boolean True if function should be documented
function FunctionParser.isPublicFunction(functionName, line)
    if not functionName then
        return false
    end

    -- Extract simple name for checking
    local simpleName = functionName:match("%.([^%.]+)$") or functionName

    -- Skip functions that start with double underscore (internal functions)
    if simpleName:match("^__") then
        return false
    end

    -- Skip local functions
    local escaped_functionName = functionName:gsub("([%(%)%.%%%+%-%*%?%[%^%$%]])", "%%%1")
    if line:match(FunctionParser.Patterns.LOCAL_PREFIX .. escaped_functionName) then
        return false
    end

    return true
end

-- Get the simple name from a full function name
-- @param fullName string Full function name (e.g., "Module.func.ops.add")
-- @return string Simple function name (e.g., "add")
function FunctionParser.getSimpleName(fullName)
    return fullName:match("%.([^%.]+)$") or fullName
end

-- Check if this line could be part of a multi-line function or comment continuation
-- @param line string Line to check
-- @param lineIndex number Current line index
-- @param totalLines number Total number of lines
-- @return boolean True if line could be continuation
function FunctionParser.couldBeContinuation(line, lineIndex, totalLines)
    -- If it's a blank line or we're near the end, it could be continuation
    return line:match("^%s*$") or lineIndex < totalLines - 3
end

return FunctionParser
