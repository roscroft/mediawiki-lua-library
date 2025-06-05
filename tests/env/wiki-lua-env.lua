-- wiki-lua-env.lua
-- Shared environment definitions for MediaWiki Lua testing

-- Define mw global table
mw = {
    -- Logging function
    log = function(...)
        -- In test environment, just print to stdout
        print("[MW-LOG]", ...)
    end,

    -- HTML builder
    html = {
        create = function(tag)
            return {
                attrs = {},
                classes = {},
                children = {},
                content = "",

                attr = function(self, name, value)
                    self.attrs[name] = value
                    return self
                end,

                addClass = function(self, class)
                    if class then
                        table.insert(self.classes, class)
                    end
                    return self
                end,

                wikitext = function(self, text)
                    self.content = text or ""
                    return self
                end,

                tag = function(self, tagName)
                    local child = mw.html.create(tagName)
                    table.insert(self.children, child)
                    return child
                end,

                done = function(self)
                    return self.parent or self
                end,

                __tostring = function(self)
                    local result = "<" .. self.tag

                    -- Add attributes
                    for name, value in pairs(self.attrs) do
                        result = result .. string.format(" %s=\"%s\"", name, tostring(value))
                    end

                    -- Add classes
                    if #self.classes > 0 then
                        result = result .. string.format(" class=\"%s\"", table.concat(self.classes, " "))
                    end

                    result = result .. ">"

                    -- Add content
                    result = result .. tostring(self.content)

                    -- Add children
                    for _, child in ipairs(self.children) do
                        result = result .. tostring(child)
                    end

                    result = result .. "</" .. self.tag .. ">"
                    return result
                end
            }
        end
    },

    -- Text processing
    text = {
        trim = function(text)
            return (text:gsub("^%s*(.-)%s*$", "%1"))
        end,

        split = function(text, sep, plain)
            local result = {}
            local pattern = plain and sep or string.format("([^%s]+)", sep)
            for match in string.gmatch(text, pattern) do
                table.insert(result, match)
            end
            return result
        end,

        -- Add JSON support if available
        jsonEncode = function(data)
            -- Try to use JSON module if available
            local ok, json = pcall(require, "dkjson")
            if ok then
                return json.encode(data)
            else
                -- Minimal fallback for simple types
                if type(data) == "string" then
                    return '"' .. data:gsub('"', '\\"') .. '"'
                elseif type(data) == "number" or type(data) == "boolean" then
                    return tostring(data)
                else
                    return '"' .. tostring(data) .. '"'
                end
            end
        end,

        jsonDecode = function(text)
            local ok, json = pcall(require, "dkjson")
            if ok then
                return json.decode(text)
            else
                -- Very basic fallback - only works for simple values
                if text == "null" then return nil end
                if text == "true" then return true end
                if text == "false" then return false end
                if text:match("^%d+%.?%d*$") then return tonumber(text) end
                if text:match('^".*"$') then return text:sub(2, -2) end
                return nil
            end
        end
    },

    -- Basic i18n support
    message = {
        new = function(key)
            return {
                plain = function() return key end,
                text = function() return key end,
                exists = function() return true end
            }
        end
    }
}

-- Basic libraryUtil functions
libraryUtil = {
    checkType = function(name, argIdx, arg, expectType, nilOk)
        if arg == nil and nilOk then return end
        if type(arg) ~= expectType then
            error(string.format("bad argument #%d to %s (%s expected, got %s)",
                argIdx, name, expectType, type(arg)), 2)
        end
    end,

    checkTypeMulti = function(name, argIdx, arg, ...)
        if arg == nil and select(select('#', ...), ...) then
            return
        end

        local expectTypes = {...}
        for i, expectType in ipairs(expectTypes) do
            if type(arg) == expectType then
                return
            end
        end

        error(string.format(
            "bad argument #%d to '%s' (%s expected, got %s)",
            argIdx, name, table.concat(expectTypes, " or "), type(arg)
        ), 2)
    end
}

-- Return the environment
return {
    mw = mw,
    libraryUtil = libraryUtil
}
