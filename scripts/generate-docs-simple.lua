#!/usr/bin/env lua
--[[
Simple Documentation Generator for MediaWiki Lua Modules
A lightweight alternative to complex documentation generation systems.

Usage: lua generate-docs-simple.lua [module_name]

This script generates basic HTML documentation by parsing Lua source files
and extracting JSDoc-style comments without requiring MediaWiki dependencies.
]]

-- Configuration
local config = {
    source_dir = "src/modules",
    output_dir = "src/module-docs",
    verbose = false
}

-- Simple argument parsing
local function parseArgs(args)
    local module_name = nil
    local i = 1
    while i <= #args do
        local arg = args[i]
        if arg == "--help" then
            print([[
Simple Documentation Generator

Usage: lua generate-docs-simple.lua [options] [module_name]

Options:
  --verbose    Enable verbose output
  --help       Show this help

Examples:
  lua generate-docs-simple.lua Array     # Generate docs for Array module
  lua generate-docs-simple.lua          # Generate docs for all modules
]])
            os.exit(0)
        elseif arg == "--verbose" then
            config.verbose = true
        elseif not arg:match("^--") then
            module_name = arg
        end
        i = i + 1
    end
    return module_name
end

-- Extract documentation from Lua file
local function extractDocs(filepath)
    local file = io.open(filepath, "r")
    if not file then
        return nil, "Could not open file: " .. filepath
    end

    local content = file:read("*all")
    file:close()

    local docs = {
        functions = {},
        description = "",
        module_name = filepath:match("([^/]+)%.lua$")
    }

    -- Extract module description from header comments
    local header = content:match("^%s*%-%-+%[%[(.-)%]%]")
    if header then
        docs.description = header:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    end

    -- Extract function documentation
    for comment_block, func_def in content:gmatch("(%-%-+%[%[.-%]%].-)\n%s*([%w_]+%s*=%s*function[^)]*%))") do
        local func_name = func_def:match("([%w_]+)%s*=")
        if func_name then
            docs.functions[func_name] = {
                comment = comment_block,
                definition = func_def
            }
        end
    end

    return docs
end

-- Generate HTML documentation
local function generateHTML(docs, output_path)
    local html = string.format([[
<!DOCTYPE html>
<html>
<head>
    <title>%s Module Documentation</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; border-bottom: 2px solid #ccc; }
        h2 { color: #666; margin-top: 30px; }
        .function { margin: 20px 0; padding: 15px; background: #f9f9f9; border-left: 4px solid #4CAF50; }
        .definition { font-family: monospace; background: #eee; padding: 10px; border-radius: 4px; }
        .description { margin: 10px 0; }
    </style>
</head>
<body>
    <h1>%s Module</h1>
    <div class="description">%s</div>
    <h2>Functions</h2>
]], docs.module_name, docs.module_name, docs.description)

    for func_name, func_info in pairs(docs.functions) do
        local clean_comment = func_info.comment:gsub("%-%-+%[%[", ""):gsub("%]%]", ""):gsub("^%s+", ""):gsub("%s+$", "")
        html = html .. string.format([[
    <div class="function">
        <h3>%s</h3>
        <div class="definition">%s</div>
        <div class="description">%s</div>
    </div>
]], func_name, func_info.definition, clean_comment)
    end

    html = html .. "\n</body>\n</html>"

    local file = io.open(output_path, "w")
    if not file then
        return false, "Could not write to: " .. output_path
    end

    file:write(html)
    file:close()
    return true
end

-- Main function
local function main(args)
    local module_name = parseArgs(args or {})

    -- Ensure output directory exists
    os.execute("mkdir -p " .. config.output_dir)

    if module_name then
        -- Generate docs for specific module
        local source_path = config.source_dir .. "/" .. module_name .. ".lua"
        local output_path = config.output_dir .. "/" .. module_name .. ".html"

        if config.verbose then
            print("Generating documentation for: " .. module_name)
            print("Source: " .. source_path)
            print("Output: " .. output_path)
        end

        local docs, err = extractDocs(source_path)
        if not docs then
            print("Error: " .. err)
            os.exit(1)
        end

        local success, err2 = generateHTML(docs, output_path)
        if not success then
            print("Error: " .. err2)
            os.exit(1)
        end

        print("✅ Documentation generated: " .. output_path)
    else
        -- Generate docs for all modules
        local modules_processed = 0
        local handle = io.popen("ls " .. config.source_dir .. "/*.lua 2>/dev/null")
        if handle then
            for line in handle:lines() do
                local filename = line:match("([^/]+)%.lua$")
                if filename then
                    local source_path = line
                    local output_path = config.output_dir .. "/" .. filename .. ".html"

                    if config.verbose then
                        print("Processing: " .. filename)
                    end

                    local docs, err = extractDocs(source_path)
                    if docs then
                        local success, err2 = generateHTML(docs, output_path)
                        if success then
                            modules_processed = modules_processed + 1
                            if config.verbose then
                                print("  ✅ " .. output_path)
                            end
                        else
                            print("  ❌ Failed: " .. err2)
                        end
                    else
                        print("  ❌ Failed: " .. err)
                    end
                end
            end
            handle:close()
        end

        print(string.format("✅ Documentation generated for %d modules in %s", modules_processed, config.output_dir))
    end
end

-- Execute
main(arg)
