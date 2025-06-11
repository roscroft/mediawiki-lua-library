#!/usr/bin/env lua
--[[
MediaWiki Template Documentation Generator
Generates MediaWiki {{Documentation}} template format for modules.

This generator specifically produces MediaWiki template syntax with:
- {{Documentation}} templates
- |fname1, |ftype1, |fuse1 parameters
- Proper MediaWiki markup formatting

Usage: lua bin/generate-docs-mediawiki.lua [options] [module_name]
]]

-- Set up package path for local modules
local script_dir = debug.getinfo(1, "S").source:match("@(.*)/[^/]*$")
local project_root = script_dir .. "/.."
package.path = package.path .. ";" .. project_root .. "/lib/?.lua"
package.path = package.path .. ";" .. project_root .. "/lib/parsers/?.lua"
package.path = package.path .. ";" .. project_root .. "/lib/utils/?.lua"
package.path = package.path .. ";" .. project_root .. "/templates/?.lua"
package.path = package.path .. ";" .. project_root .. "/config/?.lua"
package.path = package.path .. ";" .. project_root .. "/src/?.lua"

-- Import required modules
local DocConfig = require('doc-config')

-- Load parsers with validation
local function loadParserModule(name)
    local parser_path = project_root .. "/lib/parsers/" .. name .. ".lua"
    if arg[0]:match("verbose") then
        print("🔍 Looking for parser at: " .. parser_path)
    end

    -- First check if file exists
    local file_exists = io.open(parser_path, "r")
    if file_exists then
        file_exists:close()
        -- Try direct file loading
        local success, result = pcall(function()
            local chunk = loadfile(parser_path)
            if not chunk then
                error("Could not load parser module: " .. name)
            end
            return chunk()
        end)

        if success and type(result) == "table" then
            return result
        else
            print("⚠️ Parser module loaded but returned invalid type: " .. name)
            print("   Got: " .. type(result) .. ", Expected: table")
            -- Return a minimal fallback implementation
            return {
                new = function() return { processLine = function() end } end,
                extractFunctionInfo = function() return nil end
            }
        end
    else
        print("⚠️ Parser module not found: " .. name)
        -- Return a minimal fallback implementation
        return {
            new = function() return { processLine = function() end } end,
            extractFunctionInfo = function() return nil end
        }
    end
end

-- Load parsers with validation
local CommentParser = loadParserModule("comment-parser")
local FunctionParser = loadParserModule("function-parser")
local FileUtils = require('file-utils')

-- Utility functions for parsing files with the available parsers
local function parseComments(filename)
    local file = io.open(filename, "r")
    if not file then return { comments = {} } end

    -- Validate CommentParser before using
    if not CommentParser or not CommentParser.new or type(CommentParser.new) ~= "function" then
        print("⚠️ Warning: CommentParser not available, skipping comment parsing")
        return { comments = {} }
    end

    local parser = CommentParser.new()
    local comments = {}

    -- Process all lines in the file
    for line in file:lines() do
        parser:processLine(line)
    end

    file:close()

    -- Try different ways to access comments from the parser
    if parser.comments then
        -- Try accessing comments as a property of the parser object
        comments = parser.comments
    elseif parser.getComments and type(parser.getComments) == "function" then
        -- Try using getComments method if it exists
        comments = parser:getComments() or {}
    elseif CommentParser.comments then
        -- Fallback: try accessing comments directly from the parser module
        comments = CommentParser.comments
    end

    if config and config.verbose then
        print("📝 Found " .. #comments .. " comments in " .. filename)
    end

    return { comments = comments }
end

local function parseFunctions(filename
)
    local file = io.open(filename, "r")
    if not file then return { functions = {} } end

    -- First pass: get all comments with their line numbers
    local comments = parseComments(filename).comments
    local comment_map = {}

    -- Build a map of line numbers to comments for faster lookup
    for _, comment in ipairs(comments or {}) do
        if comment.line then
            comment_map[comment.line] = comment
        end
    end

    local functions = {}
    local lineNumber = 1
    local last_comment = nil
    local lines = {}

    -- Read all lines into a table first for context analysis
    for line in file:lines() do
        table.insert(lines, line)
    end
    file:close()

    -- Second pass: extract functions with context
    for i, line in ipairs(lines) do
        lineNumber = i

        -- Find JSDoc comments above current line
        local preceding_comment = nil
        for j = i - 1, math.max(1, i - 10), -1 do
            if lines[j] and lines[j]:match("^%s*%-%-%-") then
                -- Found JSDoc-style comment (starts with ---)
                preceding_comment = comment_map[j]
                break
            elseif lines[j] and not lines[j]:match("^%s*$") and not lines[j]:match("^%s*%-%-") then
                -- Found non-comment, non-empty line - stop searching
                break
            end
        end

        -- Extract function information
        local funcInfo = FunctionParser.extractFunctionInfo(line)
        if funcInfo then
            funcInfo.line = lineNumber

            -- FIXED: Extract return type from JSDoc comment or function signature
            funcInfo.returns = "any" -- Default

            -- Try to extract return type from function signature
            local return_type = line:match("%)%s*:%s*([^%s%(%)]+)")
            if return_type then
                funcInfo.returns = return_type
            end

            -- Look for return type in comment
            if preceding_comment and preceding_comment.returns then
                funcInfo.returns = preceding_comment.returns
            end

            -- FIXED: Extract description from JSDoc comment
            funcInfo.description = "No description available."
            if preceding_comment and preceding_comment.description then
                funcInfo.description = preceding_comment.description
            end

            -- FIXED: Handle parameters correctly for template engine
            -- Store the original params string if it exists
            if type(funcInfo.params) == "string" then
                funcInfo.params_str = funcInfo.params
                funcInfo.params = {} -- Convert to empty table
            else
                -- Ensure params is always a table
                funcInfo.params = funcInfo.params or {}
                funcInfo.params_str = table.concat(funcInfo.params, ", ")
            end

            funcInfo.displayName = funcInfo.name

            -- Add parameter information from JSDoc comment if available
            if preceding_comment and preceding_comment.params then
                for _, param in ipairs(preceding_comment.params) do
                    table.insert(funcInfo.params, param)
                end
            end

            table.insert(functions, funcInfo)
        end
    end

    return { functions = functions }
end

-- Version information
local VERSION = "1.0.0"

-- Configuration structure
local default_config = {
    input_dir = "src/modules", -- Change from "src" to "src/modules"
    output_dir = "tools/module-docs",
    format = "mediawiki",
    verbose = false,
    use_local_env = false,
    module_name = nil
}

-- Parse command line arguments
local function parseArgs(args)
    local config = {}
    for k, v in pairs(default_config) do
        config[k] = v
    end

    local i = 1
    while i <= #args do
        local arg = args[i]

        if arg == "--help" or arg == "-h" then
            return nil
        elseif arg == "--version" or arg == "-v" then
            print("MediaWiki Documentation Generator " .. VERSION)
            os.exit(0)
        elseif arg == "--verbose" then
            config.verbose = true
        elseif arg == "--use-local-env" then
            config.use_local_env = true
        elseif arg == "--input-dir" then
            i = i + 1
            if i <= #args then
                config.input_dir = args[i]
            else
                error("--input-dir requires a directory path")
            end
        elseif arg == "--output-dir" then
            i = i + 1
            if i <= #args then
                config.output_dir = args[i]
            else
                error("--output-dir requires a directory path")
            end
        elseif not arg:match("^%-") then
            -- This is the module name
            config.module_name = arg
        end

        i = i + 1
    end

    return config
end

-- Print usage information
local function printUsage()
    print("MediaWiki Documentation Generator " .. VERSION)
    print()
    print("Usage: lua " .. arg[0] .. " [options] [module_name]")
    print()
    print("Options:")
    print("  --help, -h           Show this help message")
    print("  --version, -v        Show version information")
    print("  --verbose            Enable verbose output")
    print("  --use-local-env      Use local MediaWiki environment (default: standalone)")
    print("  --input-dir DIR      Input directory (default: src)")
    print("  --output-dir DIR     Output directory (default: src/module-docs)")
    print()
    print("Arguments:")
    print("  module_name          Name of specific module to process (optional)")
    print()
    print("Output Format:")
    print("  Generates .wiki files with MediaWiki {{Documentation}} template syntax")
    print("  Example: {{Documentation")
    print("           |fname1=functionName |ftype1=function |fuse1=Description")
    print("           |fname2=functionName2 |ftype2=function |fuse2=Description")
    print("           }}")
end

-- Generate documentation for a single module
local function generateModuleDoc(module_name, config, template_engine)
    local input_file = config.input_dir .. "/" .. module_name .. ".lua"

    -- Check if input file exists
    if not FileUtils.readFile(input_file) then
        if module_name:match("%.lua$") then
            input_file = config.input_dir .. "/" .. module_name
        else
            print("❌ Error: Module file not found: " .. input_file)
            return false
        end
    end

    if config.verbose then
        print("📖 Processing: " .. input_file)
    end

    -- Parse the module file
    local content = FileUtils.readFile(input_file)
    if not content then
        print("❌ Error: Could not read file: " .. input_file)
        return false
    end

    -- Extract documentation using parsers
    local comment_data = parseComments(input_file)
    local function_data = parseFunctions(input_file)

    -- Prepare data for template
    local template_data = {
        moduleName = module_name:gsub("%.lua$", ""),
        functions = function_data.functions or {},
        comments = comment_data.comments or {},
        metadata = {
            file_path = input_file,
            generated_at = os.date("%Y-%m-%d %H:%M:%S"),
            generator = "MediaWiki Template Generator v" .. VERSION
        }
    }

    -- More robust validation of all template data structures before rendering
    -- This ensures the template engine always receives the expected data types
    for i, func in ipairs(template_data.functions) do
        -- Ensure function has a description
        func.description = func.description or "No description available."

        -- Ensure function has a return type
        func.returns = func.returns or "any"

        -- Format return type with proper syntax
        if func.returns ~= "any" and func.returns ~= "nil" then
            func.ftype = "<samp>-> " .. func.returns .. "</samp>"
        else
            func.ftype = "<samp>-> " .. func.returns .. "</samp>"
        end

        -- Format function use description
        func.fuse = func.description

        -- CRITICAL: Ensure ALL potential array fields are properly initialized as tables
        local fields_to_check = { "params", "returns_table", "examples", "see_also", "throws" }
        for _, field in ipairs(fields_to_check) do
            if type(func[field]) ~= "table" then
                func[field] = {}
            end
        end

        -- First, handle params_str (string representation of parameters)
        if not func.params_str or type(func.params_str) ~= "string" then
            if type(func.params) == "table" then
                -- Convert table to string
                local param_names = {}
                for _, param in ipairs(func.params) do
                    if type(param) == "string" then
                        table.insert(param_names, param)
                    elseif type(param) == "table" and param.name then
                        table.insert(param_names, param.name)
                    end
                end
                func.params_str = table.concat(param_names, ", ")
            else
                func.params_str = ""
            end
        end

        -- Handle params table with even more defensive checks
        if type(func.params) ~= "table" then
            func.params = {}
        end

        -- Ensure params is an array table, not a key-value table
        if func.params and next(func.params) ~= nil and func.params[1] == nil then
            local new_params = {}
            for k, v in pairs(func.params) do
                if type(v) == "string" then
                    table.insert(new_params, { name = k, type = v })
                elseif type(v) == "table" then
                    table.insert(new_params, v)
                else
                    table.insert(new_params, { name = k, type = "any" })
                end
            end
            func.params = new_params
        end

        -- Debug output in verbose mode
        if config.verbose then
            print(string.format("📊 Function [%s]: %d parameters, return type: %s",
                func.name or "unknown",
                #func.params,
                func.returns or "unknown"))
        end
    end

    -- Safety check: ensure template_data.functions is ALWAYS an array
    if type(template_data.functions) ~= "table" then
        template_data.functions = {}
    end

    -- Safety check: ensure template_data.comments is ALWAYS an array
    if type(template_data.comments) ~= "table" then
        template_data.comments = {}
    end

    if config.verbose then
        print(string.format("📦 Template data prepared: %d functions, %d comments",
            #template_data.functions,
            #template_data.comments))
    end

    -- Generate MediaWiki template documentation
    local wiki_content = template_engine:renderModuleDoc(template_data)

    -- Ensure output directory exists
    FileUtils.ensureDirectory(config.output_dir)

    -- Write output file
    local output_file = config.output_dir .. "/" .. template_data.moduleName .. ".wiki"
    local success = pcall(function()
        FileUtils.writeFile(output_file, wiki_content)
    end)

    if success then
        if config.verbose then
            print("✅ Generated: " .. output_file)
        end
        return true
    else
        print("❌ Error: Could not write file: " .. output_file)
        return false
    end
end

-- Initialize MediaWiki environment based on configuration
local function initializeEnvironment(config)
    if config.use_local_env then
        if config.verbose then
            print("🔧 Attempting to use local MediaWiki environment")
        end

        -- Try to load the main project's MediaWiki environment
        local success, result = pcall(function()
            -- Look for main project MediaWiki modules
            local main_paths = {
                "../../src/modules/?.lua",    -- From tools/docs-generator/
                "../../../src/modules/?.lua", -- If deeper
                "./src/modules/?.lua"         -- If run from project root
            }

            for _, path in ipairs(main_paths) do
                package.path = package.path .. ";" .. path
            end

            require('MediaWikiAutoInit')
            return "main"
        end)

        if success then
            if config.verbose then
                print("✅ Local MediaWiki environment loaded successfully")
            end
            return { type = result, initialized = true }
        else
            if config.verbose then
                print("⚠️  Failed to load local environment: " .. tostring(result))
                print("🔄 Falling back to standalone environment")
            end
        end
    end

    -- Use standalone environment (default)
    if config.verbose then
        print("🔧 Using standalone MediaWiki environment")
    end

    local success, standalone = pcall(function()
        local MediaWikiStandalone = require('MediaWikiStandalone')
        MediaWikiStandalone.initialize()
        return MediaWikiStandalone
    end)

    if success then
        if config.verbose then
            print("✅ Standalone MediaWiki environment loaded successfully")
        end
        return { type = "standalone", environment = standalone, initialized = true }
    else
        return { type = "none", initialized = false, error = standalone }
    end
end

-- Main function
local function main()
    local config = parseArgs(arg)

    if not config then
        printUsage()
        return
    end

    -- Initialize MediaWiki environment based on config
    local env_info = initializeEnvironment(config)

    if not env_info.initialized then
        print("❌ Error: Could not initialize MediaWiki environment")
        if env_info.error then
            print("   Details: " .. tostring(env_info.error))
        end
        os.exit(1)
    end

    -- Check if template engine file exists first
    local template_engine_path = project_root .. "/templates/template-engine.lua"
    if config.verbose then
        print("🔍 Looking for template engine at: " .. template_engine_path)
        local file = io.open(template_engine_path, "r")
        if file then
            file:close()
            print("  ✅ Template engine file exists")
        else
            print("  ❌ Template engine file not found")
        end
    end

    -- Now load template engine with better error handling
    local success, result = pcall(function()
        -- Try direct file loading if require fails
        local chunk = loadfile(template_engine_path)
        if not chunk then
            error("Could not load template engine file")
        end

        -- Execute the chunk to get the module table
        local module = chunk()
        if type(module) ~= "table" then
            error("Template engine did not return a table")
        end

        return module
    end)

    if not success then
        print("❌ Error loading template engine: " .. tostring(result))
        os.exit(1)
    end

    local templateEngine = result

    if not templateEngine.new or type(templateEngine.new) ~= "function" then
        print("❌ Error: Template engine does not have a 'new' function")
        os.exit(1)
    end

    if config.verbose then
        print("✅ Template engine loaded successfully")
    end

    -- Initialize template engine with MediaWiki configuration
    local doc_config = DocConfig
    local template_engine = templateEngine.new(doc_config) -- Use local variable

    if config.module_name then
        -- Generate documentation for specific module
        local success = generateModuleDoc(config.module_name, config, template_engine)
        if success then
            print("✅ MediaWiki documentation generated for " .. config.module_name)
        else
            print("❌ Failed to generate documentation for " .. config.module_name)
            os.exit(1)
        end
    else
        -- Generate documentation for all modules
        local lua_files = FileUtils.getModuleFiles(config.input_dir)
        local total_processed = 0
        local total_success = 0

        for _, file in ipairs(lua_files) do
            local module_name = FileUtils.getModuleName(file)
            if module_name then
                total_processed = total_processed + 1
                if generateModuleDoc(module_name, config, template_engine) then
                    total_success = total_success + 1
                end
            end
        end

        print(string.format("✅ Processed %d modules, %d successful", total_processed, total_success))
    end
end

-- Run the generator
main()
