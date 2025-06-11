--[[
Refactored Documentation Generator for MediaWiki Lua Modules
Modular architecture with separated concerns for parsing, templating, and utilities.

Usage: lua generate-docs-refactored.lua [module_name]
If module_name is not provided, generates documentation for all modules.
]]

-- Set up package path for local modules
local script_dir = debug.getinfo(1, "S").source:match("@(.*)/[^/]*$")
if script_dir then
    package.path = package.path .. ";" .. script_dir .. "/?.lua;" .. script_dir .. "/?/init.lua"
else
    -- Fallback: assume we're in the scripts directory
    package.path = package.path .. ";./?.lua;./?/init.lua"
end

-- Import modules
local DocConfig = require('config.doc-config')
local FileUtils = require('utils.file-utils')
local TextUtils = require('utils.text-utils')
local CommentParser = require('parsers.comment-parser')
local TypeParser = require('parsers.type-parser')
local FunctionParser = require('parsers.function-parser')
local TemplateEngine = require('templates.template-engine')
local HierarchicalSorter = require('utils.hierarchical-sorter')

-- Documentation Generator Class
local DocumentationGenerator = {}
DocumentationGenerator.__index = DocumentationGenerator

-- Create a new documentation generator instance
-- @param config table Configuration options
-- @return table New generator instance
function DocumentationGenerator.new(config)
    config = config or DocConfig
    local self = {
        config = config,
        templateEngine = TemplateEngine.new(config.templates)
    }
    setmetatable(self, DocumentationGenerator)
    return self
end

-- Parse function documentation from Lua module content
-- @param content string Lua module source code
-- @return table, number Array of functions and count
function DocumentationGenerator:parseModule(content)
    local functions = {}
    local functionCount = 0
    local commentParser = CommentParser.new()

    local lines = TextUtils.splitLines(content)

    for i, line in ipairs(lines) do
        local isCommentLine = commentParser:processLine(line)

        if commentParser:hasCompleteDoc() then
            -- Check if this line contains a function definition
            local funcInfo = FunctionParser.extractFunctionInfo(line)

            if funcInfo and FunctionParser.isPublicFunction(funcInfo.name, line) then
                -- Successfully found a function to associate with the comment
                functionCount = functionCount + 1
                local doc = commentParser:getCurrentDoc()

                -- Combine documentation with function info
                local func = self:combineDocAndFunction(doc, funcInfo)
                functions[functionCount] = func
            else
                -- This line doesn't contain a function we want to document
                if not (TextUtils.isEmpty(line) or FunctionParser.couldBeContinuation(line, i, #lines)) then
                    -- Abandon the current comment block
                    commentParser:abandonCurrentDoc()
                end
            end
        end
    end

    return functions, functionCount
end

-- Combine documentation block with function information
-- @param doc table Documentation from comment parser
-- @param funcInfo table Function information from function parser
-- @return table Combined function documentation
function DocumentationGenerator:combineDocAndFunction(doc, funcInfo)
    local func = {
        name = funcInfo.name,
        params_str = funcInfo.params,
        simple_name = FunctionParser.getSimpleName(funcInfo.name),
        description = doc.description,
        params = doc.params,
        returns = doc.returns,
        generics = doc.generics,
        notes = doc.notes
    }

    return func
end

-- Sort functions using configured sorting strategy
-- @param functions table Array of functions to sort
function DocumentationGenerator:sortFunctions(functions)
    if self.config.sorting.hierarchical then
        HierarchicalSorter.sortFunctionsHierarchically(functions, self.config)
    else
        -- Simple alphabetical sorting
        table.sort(functions, function(a, b)
            return a.name < b.name
        end)
    end
end

-- Generate complete documentation for a module
-- @param moduleName string Name of the module
-- @param content string Module source code
-- @return string|nil Generated documentation or nil if no functions found
function DocumentationGenerator:generateDoc(moduleName, content)
    if self.config.debug.showParsingProgress then
        print("Processing module: " .. moduleName)
    end

    local functions, count = self:parseModule(content)
    if count == 0 then
        print("  Warning: No functions found with documentation in " .. moduleName)
        return nil
    end

    -- Sort functions using configured strategy
    self:sortFunctions(functions)

    -- Generate documentation using template engine
    return self.templateEngine:render('module', {
        moduleName = moduleName,
        functions = functions
    })
end

-- Process a single module file
-- @param filename string Module filename (e.g., "Array.lua")
function DocumentationGenerator:processModule(filename)
    local moduleName = FileUtils.getModuleName(filename)
    if not moduleName then
        return
    end

    local sourcePath = self.config.directories.source .. "/" .. filename
    local content = FileUtils.readFile(sourcePath)
    if not content then
        print("  Error: Could not read file: " .. sourcePath)
        return
    end

    local docContent = self:generateDoc(moduleName, content)
    if not docContent then
        return
    end

    local docPath = self.config.directories.docs .. "/" .. moduleName .. ".html"
    if self.config.debug.showParsingProgress then
        print("  Writing documentation to: " .. docPath)
    end
    FileUtils.writeFile(docPath, docContent)
end

-- Process all modules in the source directory
function DocumentationGenerator:processAllModules()
    print("Generating documentation for all modules...")
    FileUtils.ensureDirectory(self.config.directories.docs)

    local files = FileUtils.getModuleFiles(self.config.directories.source)
    for _, file in ipairs(files) do
        self:processModule(file)
    end

    print("Documentation generation complete!")
end

-- Main entry point
-- @param moduleName string|nil Specific module to process, or nil for all modules
function DocumentationGenerator:run(moduleName)
    if moduleName then
        local filename = moduleName .. ".lua"
        self:processModule(filename)
    else
        self:processAllModules()
    end
end

-- Main execution function
local function main()
    local moduleName = nil

    -- Parse command line arguments
    for i = 1, #arg do
        if not moduleName then -- First non-flag argument is module name
            moduleName = arg[i]
        end
    end

    -- Create and run documentation generator
    local generator = DocumentationGenerator.new()
    if moduleName then
        local filename = moduleName .. ".lua"
        generator:processModule(filename)
    else
        generator:processAllModules()
    end
end

-- Run main function
main()
