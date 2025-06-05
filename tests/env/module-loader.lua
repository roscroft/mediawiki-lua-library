-- Enhanced Module Loader for Reorganized Structure
-- Maps "Module:X" requires to the actual files in the new src/ structure

local moduleMap = {}

-- Function to scan and register modules
local function scanModules()
    -- Define module paths in the new structure
    local modulePaths = {
        "/var/www/html/src/modules/",  -- New organized modules
        "/var/www/html/src/lib/",      -- Supporting libraries
        "/var/www/html/src/data/",     -- Data modules
        "/var/www/html/"              -- Legacy compatibility
    }

    print("Scanning for modules in new structure...")

    for _, path in ipairs(modulePaths) do
        local handle = io.popen("find " .. path .. " -type f -name '*.lua' 2>/dev/null")
        if handle then
            for filename in handle:lines() do
                local basename = filename:match("([^/]+)%.lua$")
                if basename then
                    -- Skip loader files
                    if basename ~= "module-loader" and basename ~= "wiki-lua-env" then
                        -- Register multiple name variants for flexibility
                        local cleanName = basename:gsub("_", " ") -- Convert underscores back to spaces

                        -- Register both Module: and direct names
                        moduleMap["Module:" .. cleanName] = filename
                        moduleMap["Module:" .. basename] = filename
                        moduleMap[basename] = filename
                        moduleMap[cleanName] = filename

                        print("Registered " .. basename .. " → " .. filename)
                    end
                end
            end
            handle:close()
        end
    end

    -- Debug: print all registered modules
    print("Module map contents:")
    for k, v in pairs(moduleMap) do
        print("  " .. k .. " -> " .. v)
    end
end

-- Enhanced require function
local originalRequire = require
function require(modname)
    print("Requiring: " .. modname)

    if moduleMap[modname] then
        -- MediaWiki module - load from file
        print("Loading module: " .. modname .. " from " .. moduleMap[modname])
        local func, err = loadfile(moduleMap[modname])
        if not func then
            error("Error loading " .. modname .. ": " .. tostring(err))
        end
        return func()
    else
        -- Check if we need to normalize the name
        local normalizedName = modname:gsub(" ", "_")
        if moduleMap[normalizedName] then
            print("Loading module via normalized name: " .. normalizedName)
            local func, err = loadfile(moduleMap[normalizedName])
            if not func then
                error("Error loading " .. normalizedName .. ": " .. tostring(err))
            end
            return func()
        end

        -- Try standard require
        print("Using standard require for: " .. modname)
        return originalRequire(modname)
    end
end

-- Initialize module scanning
scanModules()

-- Load the shared environment
local envFile = "/var/www/html/wiki-lua-env.lua"
if not io.open(envFile, "r") then
    envFile = "/var/www/html/tests/env/wiki-lua-env.lua"
    if not io.open(envFile, "r") then
        error("Cannot find wiki-lua-env.lua in any expected location")
    end
end
print("Loading environment from: " .. envFile)
dofile(envFile)

print("Enhanced module loader initialized with new structure")
