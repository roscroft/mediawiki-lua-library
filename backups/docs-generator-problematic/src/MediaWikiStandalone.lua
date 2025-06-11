--[[
Simplified MediaWiki Environment for Standalone Documentation Generator

This provides minimal MediaWiki compatibility for the docs generator
when running standalone (not in the main wiki-lua project context).
]]

local MediaWikiStandalone = {}

-- Minimal mw global for template compatibility
if not _G.mw then
    _G.mw = {
        text = {
            trim = function(s)
                return s:match("^%s*(.-)%s*$")
            end,
            split = function(text, pattern)
                local result = {}
                local start = 1
                local splitStart, splitEnd = string.find(text, pattern, start)
                while splitStart do
                    table.insert(result, string.sub(text, start, splitStart - 1))
                    start = splitEnd + 1
                    splitStart, splitEnd = string.find(text, pattern, start)
                end
                table.insert(result, string.sub(text, start))
                return result
            end
        },
        html = {
            create = function(tagName)
                -- Minimal HTML builder for template compatibility
                local element = {
                    tagName = tagName,
                    attributes = {},
                    content = "",
                    addClass = function(self, class)
                        self.attributes.class = (self.attributes.class or "") .. " " .. class
                        return self
                    end,
                    attr = function(self, name, value)
                        self.attributes[name] = value
                        return self
                    end,
                    wikitext = function(self, text)
                        self.content = text
                        return self
                    end,
                    allDone = function(self)
                        return self.content -- Simplified for docs generation
                    end
                }
                return element
            end
        },
        log = function(message)
            -- Simple logging for debugging
            if os.getenv("MW_DEBUG") then
                print("[MW_LOG] " .. tostring(message))
            end
        end
    }
end

-- Minimal MediaWiki global functions
if not _G.type then
    _G.type = type
end

-- Simple argument processing for templates
local function getArgs(frame)
    return frame and frame.args or {}
end

-- Initialize the standalone environment
function MediaWikiStandalone.initialize()
    -- Set up basic MediaWiki compatibility
    _G.getArgs = getArgs

    -- Minimal package.loaded setup for common modules
    if not package.loaded['Module:Arguments'] then
        package.loaded['Module:Arguments'] = {
            getArgs = getArgs
        }
    end

    -- Basic libraryUtil compatibility
    if not package.loaded['libraryUtil'] then
        package.loaded['libraryUtil'] = {
            checkType = function(name, argIdx, arg, expectType, nilOk)
                if arg == nil and nilOk then
                    return
                end
                if type(arg) ~= expectType then
                    error(string.format("bad argument #%d to '%s' (%s expected, got %s)",
                        argIdx, name, expectType, type(arg)))
                end
            end
        }
    end

    -- Mark as initialized
    _G._MW_STANDALONE_INITIALIZED = true

    return true
end

-- Check if we're in standalone mode
function MediaWikiStandalone.isStandalone()
    -- Check if we're in the main wiki-lua project context
    local main_modules_path = "../../src/modules/MediaWikiAutoInit.lua"
    local file = io.open(main_modules_path, "r")
    if file then
        file:close()
        return false -- We're in the main project
    end
    return true      -- We're standalone
end

return MediaWikiStandalone
