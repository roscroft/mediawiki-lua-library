--[[
{{Helper module|name=Yesno
|fname1=(arg)
|ftype1=Any value
|fuse1=Reads arg for yes/no and returns the appropriate boolean or nil
|fname2=(arg1,arg2)
|ftype2=Any value, Any value
|fuse2=Reads arg1 for yes/no and returns the appropriate boolean; returns arg2 if arg1 was not an applicable value
}}
--]]
-- <pre>
-- Used to evaluate args to booleans where applicable
--
-- Based on <https://en.wikipedia.org/wiki/Module:Yesno>
-- see page history there for contributors
--

return function(arg, default)
    arg = type(arg) == 'string' and mw.ustring.lower(arg) or arg

    if arg == nil then
        return nil
    end

    if
        arg == true or
        arg == 'yes' or
        arg == 'y' or
        arg == 'true' or
        tonumber(arg) == 1
    then
        return true
    end

    if
        arg == false or
        arg == 'no' or
        arg == 'n' or
        arg == 'false' or
        arg == '' or
        tonumber(arg) == 0
    then
        return false
    end

    return default
end
