--[[
MediaWiki Auto-Initializer

Simply require this at the top of any module and it automatically sets up
the MediaWiki environment. No more conditional imports needed!

Usage:
    require('MediaWikiAutoInit')  -- Just this one line
    -- Now use mw.* and libraryUtil directly
]]

-- Auto-initialize MediaWiki environment if not already present
if not _G.mw then
    local MediaWikiEnvironment = require('MediaWikiEnvironment')
    MediaWikiEnvironment.initialize()
end

-- Return empty table (this module is for side effects only)
return {}
