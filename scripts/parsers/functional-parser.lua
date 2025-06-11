--[[
Elegant Functional Parser - Advanced Functional Programming Patterns
Demonstrates sophisticated functional parsing using Functools.lua combinators

This module showcases:
- Monadic parser combinators
- Function composition pipelines
- Curried parsing functions
- Pure functional state management
- Advanced combinator usage
]]

-- Load functional programming library
local func = require('../src/modules/Functools')
local TextUtils = require('utils.text-utils')

local FunctionalParser = {}

-- ======================
-- MONADIC PARSER COMBINATORS
-- ======================

-- Parser state monad
local ParserState = {}

-- Create parser state
-- @param input string Input to parse
-- @param position number Current position
-- @return table Parser state
ParserState.new = function(input, position)
    return {
        input = input,
        position = position or 1,
        line = 1,
        column = 1
    }
end

-- Parser result type (Either success or failure)
local ParseResult = {}

-- Successful parse result
-- @param value any Parsed value
-- @param state table New parser state
-- @return table Success result
ParseResult.success = function(value, state)
    return { success = true, value = value, state = state }
end

-- Failed parse result
-- @param error string Error message
-- @param state table Parser state at failure
-- @return table Failure result
ParseResult.failure = function(error, state)
    return { success = false, error = error, state = state }
end

-- Monadic bind for parser results
-- @param parser function Parser function to apply
-- @return function Function that operates on ParseResult
ParseResult.bind = func.c2(function(parser, result)
    if result.success then
        return parser(result.value, result.state)
    else
        return result
    end
end)

-- Monadic map for parser results
-- @param f function Function to apply to parsed value
-- @return function Function that operates on ParseResult
ParseResult.map = func.c2(function(f, result)
    if result.success then
        return ParseResult.success(f(result.value), result.state)
    else
        return result
    end
end)

-- ======================
-- BASIC PARSER COMBINATORS
-- ======================

-- Parse a single character matching predicate
-- @param predicate function Character predicate function
-- @return function Parser function
local char = function(predicate)
    return function(state)
        if state.position > #state.input then
            return ParseResult.failure("End of input", state)
        end

        local c = state.input:sub(state.position, state.position)
        if predicate(c) then
            local newState = ParserState.new(
                state.input,
                state.position + 1
            )
            return ParseResult.success(c, newState)
        else
            return ParseResult.failure("Character doesn't match predicate", state)
        end
    end
end

-- Parse a specific string
-- @param str string String to match
-- @return function Parser function
local string = function(str)
    return function(state)
        local endPos = state.position + #str - 1
        if endPos > #state.input then
            return ParseResult.failure("Not enough input for string: " .. str, state)
        end

        local substr = state.input:sub(state.position, endPos)
        if substr == str then
            local newState = ParserState.new(state.input, endPos + 1)
            return ParseResult.success(str, newState)
        else
            return ParseResult.failure("String mismatch: expected " .. str .. ", got " .. substr, state)
        end
    end
end

-- Alternative parser combinator (try first, then second)
-- @param parser1 function First parser to try
-- @param parser2 function Second parser to try if first fails
-- @return function Combined parser
local alt = func.c2(function(parser1, parser2)
    return function(state)
        local result1 = parser1(state)
        if result1.success then
            return result1
        else
            return parser2(state)
        end
    end
end)

-- Sequence parser combinator
-- @param parser1 function First parser
-- @param parser2 function Second parser
-- @return function Parser that applies both in sequence
local seq = func.c2(function(parser1, parser2)
    return function(state)
        local result1 = parser1(state)
        if result1.success then
            local result2 = parser2(result1.state)
            if result2.success then
                return ParseResult.success({ result1.value, result2.value }, result2.state)
            else
                return result2
            end
        else
            return result1
        end
    end
end)

-- Many combinator (zero or more)
-- @param parser function Parser to repeat
-- @return function Parser that collects multiple results
local many = function(parser)
    return function(state)
        local results = {}
        local currentState = state

        while true do
            local result = parser(currentState)
            if result.success then
                table.insert(results, result.value)
                currentState = result.state
            else
                break
            end
        end

        return ParseResult.success(results, currentState)
    end
end

-- ======================
-- ELEGANT JSDoc PARSING USING COMBINATORS
-- ======================

-- Parse whitespace
local whitespace = char(function(c) return c:match("%s") end)
local spaces = many(whitespace)

-- Parse word characters
local wordChar = char(function(c) return c:match("[%w_]") end)
local word = ParseResult.map(function(chars) return table.concat(chars) end)(many(wordChar))

-- Parse JSDoc parameter annotation using functional composition
local parseParam = function(state)
    local paramParser = func.compose(
        ParseResult.map(function(parts)
            return {
                type = "param",
                name = parts[2],
                paramType = parts[3],
                description = parts[4] or ""
            }
        end),
        func.compose(
            seq(word), -- parameter name
            func.compose(
                seq(spaces),
                func.compose(
                    seq(word), -- parameter type
                    func.compose(
                        seq(spaces),
                        many(char(function(c) return c ~= '\n' end)) -- description
                    )
                )
            )
        )
    )(seq(string("@param"), seq(spaces, word)))

    return paramParser(state)
end

-- Parse JSDoc return annotation
local parseReturn = function(state)
    local returnParser = func.compose(
        ParseResult.map(function(parts)
            return {
                type = "return",
                returnType = parts[2],
                description = parts[3] or ""
            }
        end),
        func.compose(
            seq(word), -- return type
            func.compose(
                seq(spaces),
                many(char(function(c) return c ~= '\n' end)) -- description
            )
        )
    )(seq(string("@return"), seq(spaces, word)))

    return returnParser(state)
end

-- ======================
-- FUNCTIONAL PIPELINE COMPOSITION
-- ======================

-- Create a functional parsing pipeline using elegant composition
-- @param content string Content to parse
-- @return table Parsed documentation structure
FunctionalParser.parseDocumentation = function(content)
    -- Stage 1: Line splitting using functional operations
    local lines = TextUtils.splitLines(content)

    -- Stage 2: Functional comment detection and extraction
    local commentLines = func.Array.filter(function(line)
        return line:match("^%s*%-%-%-")
    end)(lines)

    -- Stage 3: Elegant comment text extraction using composition
    local extractComment = func.compose(
        function(text) return text:gsub("^(.-)%s*$", "%1") end,
        function(text) return text:gsub("^%s*%-%-%-", "") end
    )

    local commentTexts = func.Array.map(extractComment)(commentLines)

    -- Stage 4: Functional parsing using monadic combinators
    local parseCommentText = function(text)
        local state = ParserState.new(text)

        -- Try different parsers using alternation
        local jsDocParser = alt(
            parseParam,
            alt(
                parseReturn,
                function(state)
                    return ParseResult.success({
                        type = "description",
                        text = text
                    }, state)
                end
            )
        )

        return jsDocParser(state)
    end

    -- Stage 5: Apply parsing to all comments using functional mapping
    local parsedComments = func.Array.map(function(text)
        local result = parseCommentText(text)
        return result.success and result.value or { type = "error", text = text }
    end)(commentTexts)

    -- Stage 6: Functional grouping and structuring
    local groupByType = func.Array.groupBy(function(comment)
        return comment.type
    end)

    return {
        comments = parsedComments,
        grouped = groupByType(parsedComments),
        totalComments = #parsedComments
    }
end

-- ======================
-- ADVANCED FUNCTIONAL TRANSFORMATIONS
-- ======================

-- Create documentation structure using functional composition
-- @param parseResult table Result from parsing
-- @return table Documentation structure
FunctionalParser.createDocStructure = function(parseResult)
    -- Use functional composition to build structure
    local extractParams = func.Array.filter(function(comment)
        return comment.type == "param"
    end)

    local extractReturns = func.Array.filter(function(comment)
        return comment.type == "return"
    end)

    local extractDescriptions = func.Array.filter(function(comment)
        return comment.type == "description"
    end)

    -- Functional pipeline for structure creation
    local buildStructure = func.compose(
        function(comments)
            return {
                parameters = extractParams(comments),
                returns = extractReturns(comments),
                descriptions = extractDescriptions(comments),
                metadata = {
                    totalItems = #comments,
                    hasParams = #extractParams(comments) > 0,
                    hasReturns = #extractReturns(comments) > 0
                }
            }
        end,
        function(result) return result.comments end
    )

    return buildStructure(parseResult)
end

-- ======================
-- ELEGANT DEMONSTRATION FUNCTIONS
-- ======================

-- Demonstrate advanced functional parsing patterns
-- @param sampleContent string Sample content to parse
FunctionalParser.demonstrate = function(sampleContent)
    print("🎨 Elegant Functional Parsing Demonstration")
    print("=============================================")

    -- Parse using functional pipeline
    local parseResult = FunctionalParser.parseDocumentation(sampleContent)
    local docStructure = FunctionalParser.createDocStructure(parseResult)

    print("📊 Parsing Results:")
    print("   Total comments:", parseResult.totalComments)
    print("   Parameters found:", #docStructure.parameters)
    print("   Returns found:", #docStructure.returns)
    print("   Descriptions found:", #docStructure.descriptions)

    -- Demonstrate advanced combinators
    print("\n🔧 Advanced Combinator Patterns:")

    -- 1. Function composition chains
    local processDescription = func.compose(
        function(s) return "Processed: " .. s end,
        func.compose(
            function(s) return s:gsub("%s+", " ") end,
            function(s) return s:gsub("^%s*(.-)%s*$", "%1") end

        )
    )

    if #docStructure.descriptions > 0 then
        local processed = processDescription(docStructure.descriptions[1].text)
        print("   Composed processing:", processed)
    end

    -- 2. Curried filtering and mapping
    local filterByType = func.c2(function(type, comments)
        return func.Array.filter(function(comment)
            return comment.type == type
        end)(comments)
    end)

    local paramFilter = filterByType("param")
    local params = paramFilter(parseResult.comments)
    print("   Curried filtering found:", #params, "parameters")

    -- 3. Monadic error handling demonstration
    local safeAccess = function(obj, key)
        if obj and obj[key] then
            return func.Maybe.just(obj[key])
        else
            return func.Maybe.nothing
        end
    end

    local firstParam = func.Maybe.bind(function(params)
        return #params > 0 and func.Maybe.just(params[1]) or func.Maybe.nothing
    end)(func.Maybe.just(params))

    local paramName = func.Maybe.bind(function(param)
        return safeAccess(param, "name")
    end)(firstParam)

    print("   Monadic access result:", func.Maybe.fromMaybe("none")(paramName))
end

return FunctionalParser
