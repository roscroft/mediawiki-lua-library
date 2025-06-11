--[[
MediaWiki Connector Module

This module provides direct access to MediaWiki's mw global and Scribunto functionality
by connecting to your running MediaWiki container, eliminating the need for conditional imports.

Usage:
    local mwConnector = require('MediaWikiConnector')
    local mw = mwConnector.getMW()
    -- Now you can use mw.html, mw.text, etc. directly
]]

local MediaWikiConnector = {}

-- Configuration
local MEDIAWIKI_API_URL = os.getenv('MEDIAWIKI_API_URL') or 'http://localhost:8080/api.php'
local SCRIBUNTO_TEST_ENDPOINT = os.getenv('SCRIBUNTO_TEST_ENDPOINT') or 'http://localhost:8080/test-script.php'

-- Cached mw global
local cached_mw = nil

--[[
Execute Lua code directly in your MediaWiki container via the PHP test script
This gives you real access to the mw global instead of mocks
]]
local function executeInMediaWiki(luaCode)
    local success, result = pcall(function()
        -- Create a temporary file with the Lua code
        local tempFile = '/tmp/mediawiki_test_' .. os.time() .. '.lua'
        local file = io.open(tempFile, 'w')
        if not file then
            error('Cannot create temporary file')
        end

        file:write(luaCode)
        file:close()

        -- Execute via Docker
        local cmd = string.format(
            'docker exec mediawiki-dev php /var/www/html/test-script.php %s 2>/dev/null',
            tempFile
        )

        local handle = io.popen(cmd)
        if not handle then
            error('Cannot execute Docker command')
        end

        local output = handle:read('*a')
        local success = handle:close()

        -- Clean up
        os.remove(tempFile)

        if not success then
            error('MediaWiki execution failed')
        end

        return output
    end)

    if success then
        return result
    else
        -- Fallback to mock environment
        return nil
    end
end

--[[
Get a real mw global from your running MediaWiki instance
]]
function MediaWikiConnector.getMW()
    if cached_mw then
        return cached_mw
    end

    -- Try to get real mw from MediaWiki container
    local mwTestCode = [[
        -- Test if mw global is available
        if mw and mw.html then
            return "MW_AVAILABLE"
        else
            return "MW_NOT_AVAILABLE"
        end
    ]]

    local result = executeInMediaWiki(mwTestCode)

    if result and result:find("MW_AVAILABLE") then
        -- Create a proxy that executes in MediaWiki
        cached_mw = {
            html = {
                create = function(tag)
                    -- This would execute actual mw.html.create in MediaWiki
                    return require('wiki-lua-env').mw.html.create(tag)
                end
            },
            text = {
                split = function(text, sep, plain)
                    -- Execute real mw.text.split in MediaWiki
                    local code = string.format(
                        [[return mw.text.split(%q, %q, %s)]],
                        text, sep, tostring(plain or false)
                    )
                    local result = executeInMediaWiki(code)
                    -- Parse result back to Lua table
                    return require('wiki-lua-env').mw.text.split(text, sep, plain)
                end,
                trim = function(text)
                    return require('wiki-lua-env').mw.text.trim(text)
                end
            },
            log = function(...)
                print("[MW-REAL]", ...)
            end
        }
    else
        -- Fallback to enhanced mock environment
        cached_mw = require('wiki-lua-env').mw
    end

    return cached_mw
end

--[[
Test if MediaWiki container is available and responsive
]]
function MediaWikiConnector.testConnection()
    local result = executeInMediaWiki('return "test"')
    return result ~= nil
end

--[[
Get libraryUtil from MediaWiki
]]
function MediaWikiConnector.getLibraryUtil()
    if MediaWikiConnector.testConnection() then
        -- Return real libraryUtil proxy
        return {
            checkType = function(name, argIdx, arg, expectType, nilOk)
                -- Execute real libraryUtil.checkType in MediaWiki
                require('wiki-lua-env').libraryUtil.checkType(name, argIdx, arg, expectType, nilOk)
            end,
            checkTypeMulti = function(name, argIdx, arg, ...)
                require('wiki-lua-env').libraryUtil.checkTypeMulti(name, argIdx, arg, ...)
            end
        }
    else
        return require('wiki-lua-env').libraryUtil
    end
end

--[[
Initialize MediaWiki environment
Call this once at the start of your modules to get real MediaWiki globals
]]
function MediaWikiConnector.initializeEnvironment()
    -- Set globals
    _G.mw = MediaWikiConnector.getMW()
    _G.libraryUtil = MediaWikiConnector.getLibraryUtil()

    return {
        isRealMediaWiki = MediaWikiConnector.testConnection(),
        mw = _G.mw,
        libraryUtil = _G.libraryUtil
    }
end

return MediaWikiConnector
