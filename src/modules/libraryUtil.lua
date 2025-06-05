-- libraryUtil.lua
-- Mock implementation for testing environment
-- In MediaWiki, this is provided by the Scribunto extension

local libraryUtil = {}

function libraryUtil.checkType(name, argIdx, arg, expectType, nilOk)
    if arg == nil and nilOk then
        return
    end
    if type(arg) ~= expectType then
        error(string.format("bad argument #%d to %s (%s expected, got %s)",
            argIdx, name, expectType, type(arg)), 2)
    end
end

function libraryUtil.checkTypeMulti(name, argIdx, arg, ...)
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

function libraryUtil.checkTypeForIndex(index, value, expectType, nilOk)
    if value == nil and nilOk then
        return
    end
    if type(value) ~= expectType then
        error(string.format("bad value for index %s (%s expected, got %s)",
            tostring(index), expectType, type(value)), 2)
    end
end

function libraryUtil.checkTypeForNamedArg(name, argName, arg, expectType, nilOk)
    if arg == nil and nilOk then
        return
    end
    if type(arg) ~= expectType then
        error(string.format("bad named argument %s to %s (%s expected, got %s)",
            argName, name, expectType, type(arg)), 2)
    end
end

function libraryUtil.checkSelf(self, name)
    if type(self) ~= "table" then
        error(string.format("bad self argument to %s (table expected, got %s)",
            name, type(self)), 2)
    end
end

return libraryUtil