--[[
MediaWiki Environment Detector
Intelligently detects and loads the appropriate MediaWiki environment:
1. Main project environment (when called from wiki-lua)
2. Standalone environment (when used independently)
]]

local EnvironmentDetector = {}

-- Check if we're running in the main wiki-lua project
local function isMainProject()
    -- Look for key indicators of the main project
    local indicators = {
        "src/modules/MediaWikiAutoInit.lua",
        "tests/env/wiki-lua-env.lua",
        "build/modules",
        "Makefile"
    }

    for _, indicator in ipairs(indicators) do
        local file = io.open(indicator, "r")
        if file then
            file:close()
            return true
        end
    end

    return false
end

-- Check if we can find the main project from current location
local function findMainProject()
    local search_paths = {
        "../../",    -- If we're in tools/docs-generator/
        "../../../", -- If we're deeper
        "./",        -- Current directory
    }

    for _, path in ipairs(search_paths) do
        local test_file = path .. "src/modules/MediaWikiAutoInit.lua"
        local file = io.open(test_file, "r")
        if file then
            file:close()
            return path
        end
    end

    return nil
end

-- Initialize the appropriate MediaWiki environment
function EnvironmentDetector.initializeEnvironment(verbose)
    if verbose then
        print("🔍 Detecting MediaWiki environment...")
    end

    -- First, try to use the main project environment
    local main_project_path = findMainProject()

    if main_project_path then
        if verbose then
            print("✅ Found main wiki-lua project at: " .. main_project_path)
            print("🔧 Using main MediaWiki environment")
        end

        -- Add main project paths
        package.path = package.path .. ";" .. main_project_path .. "src/modules/?.lua"
        package.path = package.path .. ";" .. main_project_path .. "tests/env/?.lua"

        -- Try to load the main environment
        local success, result = pcall(function()
            require('MediaWikiAutoInit')
            return true
        end)

        if success then
            if verbose then
                print("✅ Main MediaWiki environment loaded successfully")
            end
            return {
                type = "main",
                path = main_project_path,
                initialized = true
            }
        else
            if verbose then
                print("⚠️  Failed to load main environment: " .. tostring(result))
                print("🔄 Falling back to standalone environment")
            end
        end
    end

    -- Fallback to standalone environment
    if verbose then
        print("🔧 Using standalone MediaWiki environment")
    end

    local success, standalone = pcall(function()
        local MediaWikiStandalone = require('MediaWikiStandalone')
        MediaWikiStandalone.initialize()
        return MediaWikiStandalone
    end)

    if success then
        if verbose then
            print("✅ Standalone MediaWiki environment loaded successfully")
        end
        return {
            type = "standalone",
            environment = standalone,
            initialized = true
        }
    else
        if verbose then
            print("❌ Failed to load standalone environment: " .. tostring(standalone))
        end
        return {
            type = "none",
            initialized = false,
            error = standalone
        }
    end
end

-- Get environment information
function EnvironmentDetector.getEnvironmentInfo()
    local info = {
        is_main_project = isMainProject(),
        main_project_path = findMainProject(),
        has_mediawiki_globals = (_G.mw ~= nil),
        lua_version = _VERSION
    }

    return info
end

return EnvironmentDetector
