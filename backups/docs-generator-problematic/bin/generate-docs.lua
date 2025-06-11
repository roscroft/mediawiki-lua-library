#!/usr/bin/env lua
--[[
MediaWiki Documentation Generator - Main Executable
Standalone version of the MediaWiki Lua module documentation generator.

Usage: lua bin/generate-docs.lua [options] [module_name]

This is a standalone version of the working MediaWiki documentation generation
system from the wiki-lua repository.
]]

-- Set up package path for local modules
local script_dir = debug.getinfo(1, "S").source:match("@(.*)/[^/]*$")
local project_root = script_dir .. "/.."
package.path = package.path .. ";" .. project_root .. "/lib/?.lua"
package.path = package.path .. ";" .. project_root .. "/lib/parsers/?.lua"
package.path = package.path .. ";" .. project_root .. "/lib/utils/?.lua"
package.path = package.path .. ";" .. project_root .. "/lib/templates/?.lua"
package.path = package.path .. ";" .. project_root .. "/config/?.lua"

-- Version information
local VERSION = "1.0.0"

-- Show help message
local function showHelp()
    print("MediaWiki Documentation Generator v" .. VERSION)
    print()
    print("Usage: lua bin/generate-docs.lua [options] [module_name]")
    print()
    print("Options:")
    print("  --style=STYLE         Documentation style: elegant, functional, refactored, ultimate")
    print("                        (default: refactored)")
    print("  --generator=TYPE      Generator type: unified, simple (default: unified)")
    print("  --source=DIR          Source directory (default: src/modules)")
    print("  --output=DIR          Output directory (default: src/module-docs)")
    print("  --format=FORMAT       Output format: html, markdown, mediawiki, both (default: html)")
    print("  --verbose             Verbose output")
    print("  --help, -h            Show this help")
    print("  --version             Show version")
    print()
    print("Examples:")
    print("  lua bin/generate-docs.lua Array                    # Generate Array module")
    print("  lua bin/generate-docs.lua --style=elegant          # All modules, elegant style")
    print("  lua bin/generate-docs.lua --generator=simple Array # Use simple generator")
    print("  lua bin/generate-docs.lua --verbose --format=both  # All modules, both formats")
end

-- Parse command line arguments
local function parseArgs(args)
    local config = {
        generator = "unified",
        style = "refactored",
        source_dir = "src/modules",
        output_dir = "src/module-docs",
        format = "html",
        verbose = false,
        module_name = nil
    }

    for _, arg in ipairs(args) do
        if arg == "--help" or arg == "-h" then
            showHelp()
            os.exit(0)
        elseif arg == "--version" then
            print("MediaWiki Documentation Generator v" .. VERSION)
            os.exit(0)
        elseif arg == "--verbose" then
            config.verbose = true
        elseif arg:match("^--style=") then
            config.style = arg:match("^--style=(.+)")
        elseif arg:match("^--generator=") then
            config.generator = arg:match("^--generator=(.+)")
        elseif arg:match("^--source=") then
            config.source_dir = arg:match("^--source=(.+)")
        elseif arg:match("^--output=") then
            config.output_dir = arg:match("^--output=(.+)")
        elseif arg:match("^--format=") then
            config.format = arg:match("^--format=(.+)")
        elseif not arg:match("^--") then
            config.module_name = arg
        end
    end

    return config
end

-- Main execution
local function main(args)
    args = args or arg or {}
    local config = parseArgs(args)

    if config.verbose then
        print("🔧 MediaWiki Documentation Generator Configuration:")
        print("  Generator: " .. config.generator)
        print("  Style: " .. config.style)
        print("  Source: " .. config.source_dir)
        print("  Output: " .. config.output_dir)
        print("  Format: " .. config.format)
        if config.module_name then
            print("  Module: " .. config.module_name)
        end
        print()
    end

    -- Build arguments for the chosen generator
    local generator_args = {}

    if config.generator == "unified" then
        -- Use the unified generator
        table.insert(generator_args, "--style=" .. config.style)
        table.insert(generator_args, "--source=" .. config.source_dir)
        table.insert(generator_args, "--output=" .. config.output_dir)
        table.insert(generator_args, "--format=" .. config.format)
        if config.verbose then
            table.insert(generator_args, "--verbose")
        end
        if config.module_name then
            table.insert(generator_args, config.module_name)
        end

        -- Run unified generator as external script
        local cmd = "cd " ..
            project_root .. " && lua bin/generate-docs-unified.lua " .. table.concat(generator_args, " ")
        local result = os.execute(cmd)
        if result ~= 0 then
            print("❌ Error: Unified generator failed")
            os.exit(1)
        end
    elseif config.generator == "simple" then
        -- Use the simple generator
        table.insert(generator_args, "--source=" .. config.source_dir)
        table.insert(generator_args, "--output=" .. config.output_dir)
        if config.verbose then
            table.insert(generator_args, "--verbose")
        end
        if config.module_name then
            table.insert(generator_args, config.module_name)
        end

        -- Run simple generator as external script
        local cmd = "cd " .. project_root .. " && lua bin/generate-docs-simple.lua " .. table.concat(generator_args, " ")
        local result = os.execute(cmd)
        if result ~= 0 then
            print("❌ Error: Simple generator failed")
            os.exit(1)
        end
    else
        print("❌ Error: Unknown generator type: " .. config.generator)
        print("Available generators: unified, simple")
        os.exit(1)
    end
end

-- Execute
main(arg)
