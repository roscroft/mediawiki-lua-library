--[[
Enhanced MediaWiki Environment Loader

This module provides a single entry point to load MediaWiki environment,
eliminating all conditional import complexity by providing a unified interface.

Usage:
    local env = require('MediaWikiEnvironment')
    env.initialize()  -- Sets up _G.mw and _G.libraryUtil automatically

    -- Now use mw.* directly without any conditionals
    local html = mw.html.create('div')
]]

local MediaWikiEnvironment = {}

-- Check if we're in a real MediaWiki/Scribunto environment
local function isRealMediaWiki()
    return _G.mw and _G.mw.html and type(_G.mw.html.create) == 'function'
end

-- Check if MediaWiki container is accessible
local function isContainerAccessible()
    local success, result = pcall(function()
        local handle = io.popen('docker ps --filter name=mediawiki-dev --format "{{.Names}}" 2>/dev/null')
        if not handle then return false end
        local output = handle:read('*a')
        handle:close()
        return output:find('mediawiki%-dev') ~= nil
    end)
    return success and result
end

-- Load environment based on availability
function MediaWikiEnvironment.initialize()
    if isRealMediaWiki() then
        -- Already in MediaWiki environment - do nothing
        return {
            source = 'real_mediawiki',
            mw = _G.mw,
            libraryUtil = _G.libraryUtil
        }
    end

    if isContainerAccessible() then
        -- Container is running - use enhanced mock that can call into container
        local env = dofile('tests/env/wiki-lua-env.lua')
        _G.mw = env.mw
        _G.libraryUtil = env.libraryUtil

        -- Add container bridge functions
        _G.mw._containerBridge = {
            execute = function(luaCode)
                local tempFile = '/tmp/mw_bridge_' .. os.time() .. '.lua'
                local file = io.open(tempFile, 'w')
                if file then
                    file:write('return ' .. luaCode)
                    file:close()

                    local cmd = string.format(
                        'docker exec mediawiki-dev lua %s 2>/dev/null',
                        tempFile
                    )
                    local handle = io.popen(cmd)
                    if handle then
                        local result = handle:read('*a')
                        handle:close()
                        os.remove(tempFile)
                        return result
                    end
                    os.remove(tempFile)
                end
                return nil
            end
        }

        return {
            source = 'container_bridge',
            mw = _G.mw,
            libraryUtil = _G.libraryUtil,
            containerAvailable = true
        }
    else
        -- Fallback to mock environment
        local env = dofile('tests/env/wiki-lua-env.lua')
        _G.mw = env.mw
        _G.libraryUtil = env.libraryUtil

        return {
            source = 'mock_environment',
            mw = _G.mw,
            libraryUtil = _G.libraryUtil,
            containerAvailable = false
        }
    end
end

-- Convenience function to ensure MediaWiki environment is loaded
function MediaWikiEnvironment.ensureLoaded()
    if not _G.mw then
        MediaWikiEnvironment.initialize()
    end
    return _G.mw, _G.libraryUtil
end

-- Get environment info for debugging
function MediaWikiEnvironment.getInfo()
    local info = {
        hasGlobalMw = _G.mw ~= nil,
        isRealMediaWiki = isRealMediaWiki(),
        containerAccessible = isContainerAccessible(),
        environmentSource = 'unknown'
    }

    if isRealMediaWiki() then
        info.environmentSource = 'real_mediawiki'
    elseif isContainerAccessible() then
        info.environmentSource = 'container_bridge'
    else
        info.environmentSource = 'mock_environment'
    end

    return info
end

return MediaWikiEnvironment
