--[[
Elegant Functional Text Processing Utilities
Demonstrates sophisticated functional programming patterns for text manipulation.

This module showcases:
- Pure functional string operations
- Function composition pipelines
- Curried text transformations
- Monadic error handling for text processing
- Advanced combinator usage
]]

-- Load functional programming library
local func = require('../src/modules/Functools')

local FunctionalTextUtils = {}

-- ======================
-- PURE FUNCTIONAL CHARACTER OPERATIONS
-- ======================

-- Pure character predicates using functional composition
local isAsterisk = func.const('*'):sameAs()
local isDash = func.const('-'):sameAs()
local isSpace = function(char) return char:match("%s") ~= nil end
local isWordChar = function(char) return char:match("[%w]") ~= nil end
local isPrefixSymbol = function(char) return isAsterisk(char) or isDash(char) end

-- Higher-order function for character testing
-- @param predicate function Character predicate function
-- @return function Function that tests characters
local charTest = func.c2(function(predicate, char)
    return predicate(char)
end)

-- ======================
-- ELEGANT FUNCTIONAL STRING PROCESSING
-- ======================

-- Pure functional character sequence processing
-- @param text string Text to process
-- @return table Array of characters
FunctionalTextUtils.toCharArray = function(text)
    local chars = {}
    for i = 1, #text do
        chars[i] = text:sub(i, i)
    end
    return chars
end

-- Functional prefix symbol counting using elegant composition
-- @param commentText string Text to analyze
-- @return number Count of prefix symbols
FunctionalTextUtils.countPrefixSymbols = function(commentText)
    -- Create a functional pipeline for counting
    local countPrefixChars = func.compose(
    -- Stage 3: Count the prefix symbols
        func.Array.length,
        func.compose(
        -- Stage 2: Take characters while they are prefix symbols or spaces
            func.Array.takeWhile(function(char)
                return isPrefixSymbol(char) or isSpace(char)
            end),
            -- Stage 1: Convert to character array
            FunctionalTextUtils.toCharArray
        )
    )

    -- Apply the pipeline and filter only actual symbols
    local allPrefixChars = countPrefixChars(commentText)
    local symbolsOnly = func.Array.filter(isPrefixSymbol)(
        func.Array.takeWhile(function(char)
            return isPrefixSymbol(char) or isSpace(char)
        end)(FunctionalTextUtils.toCharArray(commentText))
    )

    return #symbolsOnly
end

-- Elegant asterisk generation using functional repetition
-- @param count number Number of asterisks to generate
-- @return string String containing asterisks
FunctionalTextUtils.generateAsterisks = func.compose(
    func.Array.join(""),
    func.Array.map(func.const("*")),
    func.Array.range(1)
)

-- Pure functional leading character trimming
-- @param str string String to trim
-- @return string Trimmed string
FunctionalTextUtils.trimLeadingNonWordChars = function(str)
    if not str or type(str) ~= "string" then
        return str
    end

    -- Functional approach using dropWhile
    local chars = FunctionalTextUtils.toCharArray(str)
    local trimmedChars = func.Array.dropWhile(function(char)
        return not isWordChar(char)
    end)(chars)

    return func.Array.join("")(trimmedChars)
end

-- ======================
-- MONADIC TEXT PROCESSING
-- ======================

-- Text processing with Maybe monad for safe operations
-- @param text string|nil Text to process
-- @return Maybe<string> Maybe containing processed text
FunctionalTextUtils.safeProcessText = function(text)
    return func.Maybe.bind(function(t)
        if type(t) ~= "string" then
            return func.Maybe.nothing
        else
            return func.Maybe.just(t)
        end
    end)(func.Maybe.fromNullable(text))
end

-- Safe pipe escaping using monadic composition
-- @param str string|nil String to escape
-- @return string Escaped string or original
FunctionalTextUtils.safeEscapePipes = function(str)
    local escapeOperation = func.Maybe.map(function(s)
        return s:gsub("|", "{{!}}")
    end)

    return func.Maybe.fromMaybe(str or "")(
        escapeOperation(FunctionalTextUtils.safeProcessText(str))
    )
end

-- ======================
-- ADVANCED FUNCTIONAL COMPOSITION PATTERNS
-- ======================

-- Create a text processing pipeline using function composition
-- @param operations table Array of text transformation functions
-- @return function Composed text processing function
FunctionalTextUtils.createPipeline = function(operations)
    return func.Array.foldl(func.compose)(func.id)(operations)
end

-- Elegant text formatting using curried functions
-- @param formatter function Text formatting function
-- @return function Curried function for formatting lists
FunctionalTextUtils.formatWith = func.c2(function(formatter, items)
    return func.Array.map(formatter)(items)
end)

-- Advanced text analysis using functional composition
-- @param text string Text to analyze
-- @return table Analysis results
FunctionalTextUtils.analyzeText = function(text)
    -- Create analysis pipeline using pure functions
    local getLength = function(s) return #s end
    local getWords = function(s)
        local words = {}
        for word in s:gmatch("%S+") do
            table.insert(words, word)
        end
        return words
    end
    local getLines = function(s)
        local lines = {}
        for line in s:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
        return lines
    end

    -- Apply analysis functions using functional composition
    local words = getWords(text)
    local lines = getLines(text)

    return {
        characters = getLength(text),
        words = #words,
        lines = #lines,
        avgWordsPerLine = #lines > 0 and #words / #lines or 0,
        longestWord = func.Array.foldl(function(acc, word)
            return #word > #acc and word or acc
        end)("")(words)
    }
end

-- ======================
-- ELEGANT LIST OPERATIONS
-- ======================

-- Functional line splitting with enhanced processing
-- @param text string Text to split
-- @return table Array of processed lines
FunctionalTextUtils.splitLinesEnhanced = function(text)
    local rawLines = {}
    for line in text:gmatch("[^\r\n]+") do
        table.insert(rawLines, line)
    end

    -- Apply functional transformations to each line
    local processLine = FunctionalTextUtils.createPipeline({
        function(line) return line:gsub("^%s*(.-)%s*$", "%1") end, -- trim
        function(line) return line == "" and nil or line end       -- filter empty
    })

    return func.Array.filter(function(line) return line ~= nil end)(
        func.Array.map(processLine)(rawLines)
    )
end

-- Elegant joining with customizable separators
-- @param separator string Separator to use
-- @return function Curried join function
FunctionalTextUtils.joinWith = func.c2(function(separator, parts)
    return table.concat(func.Array.filter(function(part)
        return part ~= nil and part ~= ""
    end)(parts), separator)
end)

-- ======================
-- DEMONSTRATION OF ELEGANT PATTERNS
-- ======================

-- Demonstrate advanced functional text processing
-- @param sampleText string Sample text for demonstration
FunctionalTextUtils.demonstrate = function(sampleText)
    print("🎨 Elegant Functional Text Processing")
    print("=" .. string.rep("=", 38))

    -- 1. Monadic safe processing
    local safeResult = FunctionalTextUtils.safeProcessText(sampleText)
    print("✓ Safe processing:", func.Maybe.isJust(safeResult) and "success" or "failed")

    -- 2. Functional composition pipeline
    local textPipeline = FunctionalTextUtils.createPipeline({
        function(s) return s:upper() end,
        function(s) return s:gsub("%s+", "_") end,
        FunctionalTextUtils.trimLeadingNonWordChars
    })

    print("✓ Pipeline result:", textPipeline("  hello world  "))

    -- 3. Advanced text analysis
    local analysis = FunctionalTextUtils.analyzeText(sampleText)
    print("✓ Text analysis:")
    print("   Characters:", analysis.characters)
    print("   Words:", analysis.words)
    print("   Lines:", analysis.lines)
    print("   Longest word:", analysis.longestWord)

    -- 4. Curried operations
    local addPrefix = func.c2(function(prefix, text)
        return prefix .. text
    end)

    local addDoc = addPrefix("doc_")
    local prefixedText = addDoc("example")
    print("✓ Curried prefix:", prefixedText)

    -- 5. Functional list processing
    local words = { "functional", "elegant", "composition" }
    local uppercaseWords = func.Array.map(string.upper)(words)
    print("✓ Functional mapping:", FunctionalTextUtils.joinWith(", ")(uppercaseWords))
end

-- Enhanced utilities with functional elegance
FunctionalTextUtils.isEmpty = func.compose(
    function(result) return result ~= nil end,
    function(str) return str and str:match("^%s*$") end
)

FunctionalTextUtils.isNotEmpty = func.compose(
    func.not_,
    FunctionalTextUtils.isEmpty
)

return FunctionalTextUtils
