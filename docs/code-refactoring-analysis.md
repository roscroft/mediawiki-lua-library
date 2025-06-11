# Code Refactoring Analysis for generate-docs.lua

## Overview

The `scripts/generate-docs.lua` script has grown organically and now contains over 600 lines of complex parsing logic. While it works well, there are several opportunities to simplify the code and introduce more general abstractions that would improve maintainability and reusability.

## Current Issues

### 1. **Single Responsibility Violation**

- The `parseFunctionDocs()` function handles multiple responsibilities:
  - Comment block detection
  - JSDoc tag parsing
  - Function definition matching
  - State management (inCommentBlock, inExampleBlock)
  - Complex string processing

### 2. **Scattered String Processing**

- Multiple similar string manipulation functions throughout the file:
  - `countPrefixSymbols()`
  - `generateAsterisks()`
  - `trimLeadingNonWordChars()`
  - `escapePipes()`
- Each serves a specific purpose but could be part of a unified text processing module

### 3. **Complex Parsing Logic**

- The `parseComplexReturnType()` function uses sophisticated word-based analysis
- Comment parsing has complex state management
- Function definition matching uses multiple regex patterns
- These could benefit from a more formal parsing approach

### 4. **Hardcoded MediaWiki Template Logic**

- The `formatFunctionDoc()` function mixes data formatting with MediaWiki-specific template generation
- Template structure is hardcoded throughout the function
- Makes it difficult to adapt to other documentation formats

### 5. **Configuration Scattered Throughout**

- Magic numbers and configuration values embedded in functions
- Template formatting rules scattered across multiple functions
- No centralized configuration management

## Proposed Refactoring Strategy

### Phase 1: Extract Utility Modules

#### 1.1 Text Processing Utils

```lua
-- utils/text-processing.lua
local TextUtils = {}

function TextUtils.countPrefixSymbols(text, symbols)
    -- Generalized version that accepts any symbols to count
end

function TextUtils.trimLeading(text, patterns)
    -- Generic function to trim based on pattern list
end

function TextUtils.escapePipes(text)
    -- Move pipe escaping here
end

function TextUtils.formatList(items, formatter)
    -- Generic list formatting with custom formatter
end

return TextUtils
```

#### 1.2 File System Utils

```lua
-- utils/filesystem.lua
local FileUtils = {}

function FileUtils.readFile(path)
function FileUtils.writeFile(path, content)
function FileUtils.ensureDirectory(path)
function FileUtils.getModuleFiles(directory)

return FileUtils
```

### Phase 2: Extract Parsing Modules

#### 2.1 Comment Parser

```lua
-- parsers/comment-parser.lua
local CommentParser = {}

-- State machine for comment parsing
CommentParser.State = {
    OUTSIDE = "outside",
    IN_COMMENT = "in_comment", 
    IN_EXAMPLE = "in_example"
}

function CommentParser:new()
    return {
        state = CommentParser.State.OUTSIDE,
        currentDoc = nil,
        buffer = {}
    }
end

function CommentParser:processLine(line)
    -- State machine logic for processing each line
end

function CommentParser:getCurrentDoc()
    -- Return completed documentation block
end

return CommentParser
```

#### 2.2 Type Annotation Parser

```lua
-- parsers/type-parser.lua
local TypeParser = {}

function TypeParser.parseReturnType(annotation)
    -- Extract and parse complex return type annotations
end

function TypeParser.parseParameter(annotation)
    -- Parse @param annotations
end

function TypeParser.parseGeneric(annotation)
    -- Parse @generic annotations  
end

return TypeParser
```

#### 2.3 Function Definition Parser

```lua
-- parsers/function-parser.lua
local FunctionParser = {}

FunctionParser.Patterns = {
    FUNCTION_DECLARATION = "^%s*function%s+([%w_%.:]+)%s*%((.-)%)",
    FUNCTION_ASSIGNMENT = "^%s*([%w_%.:]+)%s*=%s*function%s*%((.-)%)",
    LOCAL_PREFIX = "^%s*local%s+"
}

function FunctionParser.extractFunctionInfo(line)
    -- Extract function name and parameters from various patterns
end

function FunctionParser.isPublicFunction(functionName, line)
    -- Determine if function should be documented
end

return FunctionParser
```

### Phase 3: Extract Template Generation

#### 3.1 Template Engine

```lua
-- templates/template-engine.lua
local TemplateEngine = {}

function TemplateEngine:new(config)
    return {
        config = config,
        formatters = {}
    }
end

function TemplateEngine:addFormatter(name, formatter)
    self.formatters[name] = formatter
end

function TemplateEngine:render(templateName, data)
    -- Generic template rendering
end

return TemplateEngine
```

#### 3.2 MediaWiki Templates

```lua
-- templates/mediawiki-templates.lua
local MediaWikiTemplates = {}

MediaWikiTemplates.FUNCTION_DOC = [[
|fname{index} = <nowiki>{fname}</nowiki>
|ftype{index} = {ftype}
|fuse{index} = {fuse}
{notes}
]]

function MediaWikiTemplates.formatFunctionDoc(func, index, config)
    -- Template-based function documentation formatting
end

return MediaWikiTemplates
```

### Phase 4: Centralized Configuration

#### 4.1 Configuration Module

```lua
-- config/doc-config.lua
local DocConfig = {
    directories = {
        source = "./src/modules",
        docs = "./src/module-docs"
    },
    
    parsing = {
        objectDetectionThreshold = 0.3,
        maxDebugOutput = 10
    },
    
    templates = {
        mediawiki = {
            headerTemplate = "{{Documentation}}\n{{Helper module",
            footerTemplate = "}}"
        }
    },
    
    sorting = {
        hierarchical = true,
        primaryByDepth = true,
        secondaryByPath = true
    }
}

return DocConfig
```

### Phase 5: Simplified Main Architecture

#### 5.1 Refactored Main Script

```lua
-- scripts/generate-docs-refactored.lua
local DocConfig = require('config.doc-config')
local FileUtils = require('utils.filesystem')
local TextUtils = require('utils.text-processing')
local CommentParser = require('parsers.comment-parser')
local TypeParser = require('parsers.type-parser')
local FunctionParser = require('parsers.function-parser')
local TemplateEngine = require('templates.template-engine')
local MediaWikiTemplates = require('templates.mediawiki-templates')

local DocumentationGenerator = {}

function DocumentationGenerator:new(config)
    return {
        config = config,
        commentParser = CommentParser:new(),
        templateEngine = TemplateEngine:new(config.templates)
    }
end

function DocumentationGenerator:parseModule(content)
    -- Simplified parsing using extracted modules
    local functions = {}
    local lines = TextUtils.splitLines(content)
    
    for _, line in ipairs(lines) do
        self.commentParser:processLine(line)
        
        if self.commentParser:hasCompleteDoc() then
            local doc = self.commentParser:getCurrentDoc()
            local funcInfo = FunctionParser.extractFunctionInfo(line)
            
            if funcInfo and FunctionParser.isPublicFunction(funcInfo.name, line) then
                table.insert(functions, self:combineDocAndFunction(doc, funcInfo))
            end
        end
    end
    
    return functions
end

function DocumentationGenerator:generateDoc(moduleName, content)
    local functions = self:parseModule(content)
    self:sortFunctions(functions)
    return self.templateEngine:render('module', {
        moduleName = moduleName,
        functions = functions
    })
end
```

## Benefits of Refactoring

### 1. **Separation of Concerns**

- Each module has a single, well-defined responsibility
- Easier to test individual components
- Clearer code organization

### 2. **Reusability**

- Text processing utils can be used across the project
- Template engine can support multiple output formats
- Parsing modules can be extended for other documentation needs

### 3. **Maintainability**

- Smaller, focused functions are easier to understand and modify
- Configuration changes don't require code changes
- Bug fixes can be isolated to specific modules

### 4. **Extensibility**

- Easy to add new JSDoc tags by extending the type parser
- Simple to add new output formats by creating new template modules
- New function patterns can be added to the function parser

### 5. **Testability**

- Each module can be unit tested independently
- Parser state machines can be tested with edge cases
- Template generation can be validated separately

## Implementation Recommendations

### Priority 1 (High Impact, Low Risk)

1. Extract file system utilities
2. Create centralized configuration
3. Extract string processing utilities

### Priority 2 (Medium Impact, Medium Risk)

1. Extract comment parser with state machine
2. Create template engine abstraction
3. Separate MediaWiki-specific formatting

### Priority 3 (High Impact, Higher Risk)

1. Extract complex type parsing logic
2. Implement formal parsing patterns
3. Create extensible plugin architecture

## Migration Strategy

1. **Incremental Refactoring**: Implement one module at a time while keeping the original script functional
2. **Parallel Development**: Create refactored modules alongside existing code
3. **Gradual Migration**: Replace functions one by one in the main script
4. **Comprehensive Testing**: Ensure documentation output remains identical during migration
5. **Final Cleanup**: Remove old code once new modules are proven stable

This refactoring would transform a monolithic 600-line script into a modular, maintainable documentation generation system that could easily be extended for other projects or output formats.
