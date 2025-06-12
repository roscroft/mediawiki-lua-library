# Functional Programming Refactoring Analysis

## MediaWiki Documentation Generator Simplification

### Overview

This analysis identifies opportunities to simplify the current `generate-docs.lua` script using functional programming patterns from the Functools library. The goal is to reduce complexity,
improve maintainability, and demonstrate elegant functional programming techniques.

## Current Complexity Analysis

### 1. **State Management Issues**

**Current Code:** Complex state machine with multiple flags

```lua
local inComment = false
local currentDescription = {}
local inCodeBlock = false
local currentCodeBlock = {}
local codeBlockLang = "lua"
local inBehaviorSection = false
local inPerformanceSection = false
```

**Functional Solution:** Use immutable state transformations

```lua
-- Replace with functional state pipeline
local processLine = func.pipe(
    detectCommentType,
    updateParserState,
    extractContent
)
```

### 2. **Manual String Processing**

**Current Code:** Repetitive string manipulation

```lua
text = text:gsub("`([^`]+)`", "<code>%1</code>")
text = text:gsub("'''([^']+)'''", "'''%1'''")
paramType = paramType:gsub("%s*|%s*", " {{!}} ")
paramType = paramType:gsub("Array<([^>]+)>", "Array<`%1`>")
```

**Functional Solution:** Composable string processors

```lua
local formatText = func.pipe(
    convertInlineCode,
    formatBoldText,
    normalizeUnionTypes,
    formatArrayTypes
)
```

### 3. **Imperative Loops**

**Current Code:** Manual array processing

```lua
for i, param in ipairs(func.params) do
    local docParam = nil
    for _, dp in ipairs(docInfo.params) do
        if dp.name == param then
            docParam = dp
            break
        end
    end
    -- more processing...
end
```

**Functional Solution:** Map and find operations

```lua
local enrichedParams = func.map(function(param)
    local docParam = func.find(matchesName(param), docInfo.params)
    return enrichParam(param, docParam)
end, func.params)
```

### 4. **Error-Prone File Operations**

**Current Code:** Manual file handling without safety

```lua
local file = io.open(inputFile, "r")
if not file then
    print("❌ Error: Module file not found: " .. inputFile)
    return false
end
```

**Functional Solution:** Maybe monad for safe operations

```lua
local content = func.Maybe.bind(safeFileRead)(inputFile)
local result = func.Maybe.map(processContent)(content)
```

## Specific Functional Programming Opportunities

### 1. **Parser Combinators**

**Replace:** 800-line monolithic parser
**With:** Composable parser functions

```lua
-- Current: Large parseAdvancedJSDocBlock function
-- Functional: Small, composable parsers

local parseGeneric = Parser.match("@generic%s+([%w_]+)")
local parseParam = Parser.sequence(
    Parser.match("@param%s+([%w_]+)"),
    Parser.match("%s+(.+)")
)
local parseReturn = Parser.match("@return%s+([%S]+)%s*(.*)")

local parseJSDoc = Parser.many(
    Parser.choice({
        parseGeneric,
        parseParam, 
        parseReturn,
        parseCodeBlock,
        parseDescription
    })
)
```

### 2. **Template Generation Pipeline**

**Replace:** Manual template building
**With:** Functional composition

```lua
-- Current: Manual string concatenation
local parts = {}
table.insert(parts, "{{Documentation}}")
-- ... many manual insertions

-- Functional: Composable template builders
local generateDoc = func.pipe(
    createHeader,
    func.map(generateFunctionEntry),
    createFooter,
    joinWithNewlines
)
```

### 3. **Type System Processing**

**Replace:** Repetitive type formatting
**With:** Curried type processors

```lua
-- Current: Repeated type formatting logic
paramType = paramType:gsub("%s*|%s*", " {{!}} ")
if not paramType:match("Array<`") then
    paramType = paramType:gsub("Array<([^>]+)>", "Array<`%1`>")
end

-- Functional: Composable type formatters
local formatType = func.pipe(
    normalizeSpacing,
    formatUnionTypes,
    formatArrayTypes,
    escapeWikiChars
)
```

### 4. **Configuration Management**

**Replace:** Global configuration
**With:** Functional lenses and composition

```lua
-- Current: Global config object
local config = {
    sourceDir = "src/modules",
    outputDir = "tools/module-docs",
    extension = ".wiki",
    verbose = true
}

-- Functional: Lens-based configuration
local Config = {
    sourceDir = func.lens(_.sourceDir),
    outputDir = func.lens(_.outputDir),
    verbose = func.lens(_.verbose)
}

local updateConfig = func.pipe(
    Config.sourceDir.set("new/path"),
    Config.verbose.set(false)
)
```

## Functional Refactoring Benefits

### 1. **Reduced Complexity**

- **Before:** 808 lines with complex state management
- **After:** ~400 lines with clear functional pipelines

### 2. **Better Error Handling**

- **Before:** Manual error checking everywhere
- **After:** Maybe monad chains for safe operations

### 3. **Improved Testability**

- **Before:** Large functions with side effects
- **After:** Pure functions that are easy to test

### 4. **Enhanced Reusability**

- **Before:** Coupled, monolithic components
- **After:** Composable, reusable functions

## Implementation Strategy

### Phase 1: **String Processing** (Low Risk)

```lua
-- Replace manual string processing with functional pipelines
local StringProcessor = {
    cleanComment = func.pipe(
        removeCommentMarkers,
        trimWhitespace
    ),
    
    formatDescription = func.curry(function(options, text)
        return func.pipe(
            convertInlineCode(options.convertInlineCode),
            formatBoldText,
            escapeWikiChars
        )(text)
    end)
}
```

### Phase 2: **Template Generation** (Medium Risk)

```lua
-- Replace manual template building with functional composition
local TemplateEngine = {
    generateFunction = func.curry(function(index, func_obj)
        return func.pipe(
            generateSignature,
            generateTypeInfo,
            generateDescription,
            formatAsWikiEntry(index)
        )(func_obj)
    end),
    
    generateModule = func.pipe(
        addHeader,
        func.map(TemplateEngine.generateFunction),
        addFooter,
        joinLines
    )
}
```

### Phase 3: **Parser Refactoring** (High Risk)

```lua
-- Replace state machine with parser combinators
local JSDocParser = {
    -- Atomic parsers
    commentLine = Parser.regex("^%s*%-%-%-?(.*)"),
    paramLine = Parser.regex("@param%s+([%w_]+)%s+(.+)"),
    
    -- Composite parsers
    parseBlock = Parser.many(
        Parser.choice({
            JSDocParser.paramLine,
            JSDocParser.returnLine,
            JSDocParser.genericLine,
            JSDocParser.descriptionLine
        })
    )
}
```

## Practical Examples

### 1. **Safe File Operations**

```lua
-- Current: Error-prone
local function readFile(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end

-- Functional: Safe with Maybe
local readFile = function(path)
    return func.maybe_call(function()
        local file = io.open(path, "r")
        if not file then return nil end
        local content = file:read("*all")
        file:close()
        return content
    end)
end

-- Usage in pipeline
local processFile = func.pipe(
    readFile,
    func.Maybe.bind(parseContent),
    func.Maybe.map(generateDocs),
    func.Maybe.bind(writeOutput)
)
```

### 2. **Function Deduplication**

```lua
-- Current: Imperative
function deduplicateFunctions(functions)
    local seen = {}
    local result = {}
    for _, func in ipairs(functions) do
        if not seen[func.name] then
            seen[func.name] = func
            table.insert(result, func)
        end
    end
    return result
end

-- Functional: Using groupBy and map
local deduplicateFunctions = func.pipe(
    func.group_by(func.prop('name')),
    func.map(func.head),
    func.values
)
```

### 3. **Type Signature Generation**

```lua
-- Current: Manual processing
function generateTypeSignature(func)
    local parts = {}
    
    if #func.generics > 0 then
        for _, generic in ipairs(func.generics) do
            table.insert(parts, string.format("<samp>generic: %s</samp>", generic.name))
        end
    end
    
    for _, param in ipairs(func.params) do
        -- lots of manual processing...
    end
    
    return table.concat(parts, "<br>")
end

-- Functional: Composable pipeline
local generateTypeSignature = function(func_obj)
    return func.pipe(
        func.juxt({
            generateGenerics,
            generateParams, 
            generateReturn
        }),
        func.flatten,
        func.join("<br>")
    )(func_obj)
end
```

## Testing Strategy

### 1. **Unit Testing Pure Functions**

```lua
-- Test individual functional components
local tests = {
    stringProcessing = function()
        local input = "`code` and '''bold'''"
        local expected = "<code>code</code> and '''bold'''"
        assert(StringProcessor.formatDescription({convertInlineCode = true}, input) == expected)
    end,
    
    typeFormatting = function()
        local input = "string | number"
        local expected = "string {{!}} number"
        assert(TypeFormatter.formatUnion(input) == expected)
    end
}
```

### 2. **Property-Based Testing**

```lua
-- Test compositional properties
local testComposition = function()
    local f = func.compose(StringProcessor.clean, StringProcessor.format)
    local g = function(x) return StringProcessor.format(StringProcessor.clean(x)) end
    
    -- Property: f(x) == g(x) for all valid inputs
    for _, input in ipairs(testInputs) do
        assert(f(input) == g(input))
    end
end
```

## Migration Path

### 1. **Gradual Refactoring**

- Keep original generator working
- Implement functional versions alongside
- Gradually replace components
- Maintain backward compatibility

### 2. **Risk Mitigation**

- Extensive testing of each functional component
- Side-by-side output comparison
- Gradual rollout with fallback options

### 3. **Documentation Updates**

- Document functional patterns used
- Provide examples for future development
- Create style guide for functional MediaWiki development

## Conclusion

The functional programming refactoring offers significant benefits:

1. **Reduced Complexity:** From 808 lines to ~400 lines
2. **Better Error Handling:** Maybe monad eliminates crashes
3. **Improved Maintainability:** Pure functions are easier to debug
4. **Enhanced Reusability:** Composable components can be reused
5. **Elegant Code:** Demonstrates sophisticated functional programming

The refactoring demonstrates how MediaWiki Lua development can benefit from functional programming patterns, creating more robust and maintainable code while showcasing the power of the Functools library.
