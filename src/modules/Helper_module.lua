-- <nowiki>
-- Helps [[RuneScape:Lua/Helper modules]] format its table with dynamic documentation
-- See [[Template:Helper module]] for documentation and usage
require('Mw_html_extension')
local getArgs = require("Arguments").getArgs;
local tooltip = require('Tooltip')
local p = {}

function p.main(frame)
    local args = getArgs(frame);
    local function_list = {}
    -- Let there be no limit to number of parameters
    local i = 1
    while args['fname' .. i] do
        local funcname = args['fname' .. i] or ''
        local functype = args['ftype' .. i] or ''
        local funcuse = args['fuse' .. i] or ''
        function_list[i] = {
            fname = funcname,
            ftype = functype,
            fdesc = funcuse
        }
        i = i + 1
    end
    local title = mw.title.getCurrentTitle()
    if not args.name then
        return error(
            "Missing required parameter 'name' to &#123;&#123;[[Template:Helper module|Helper module]]&#125;&#125;",
            "Erroneous parameter"
        );
    end

    if title.namespace == 828 and (title.text == args.name or title.text == args.name .. '/doc') then
        local t = "";
        if #function_list > 0 then
            t = mw.html.create('table')
                :addClass('wikitable')
                :tr()
                :th('Function')
                :th('Type')
                :th('Use')
                :done()
                :node(p._main(args.name, function_list, nil, false))
                :allDone()
        end

        local category = ''
        if not (title.isSubpage and title.subpageText == 'doc') then
            category = '[[Category:Helper modules]][[Category:Modules required by modules]]'
        end
        local reqby = ''
        if not (title.isSubpage and title.subpageText == 'doc') then
            local uri = mw.uri.canonicalUrl('Special:WhatLinksHere', 'target=Module:' .. args.name .. '&namespace=828')
            reqby = 'For a full list of modules using this helper <span class="plainlinks">[' ..
                tostring(uri) .. ' click here]</span>\n'
        end
        local example = ''
        if args.example then
            example = "'''Example:'''\n" .. args.example
        end
        return
            'This module is a helper module to be used by other modules; it may not be designed to be invoked directly. See [[RuneScape:Lua/Helper modules]] for a full list and more information.\n' ..
            reqby .. tostring(t) .. example .. category
    else
        return p._main(args.name, function_list, args.example or '', true)
    end
end

local function formatFuncNames(list)
    list = mw.text.split(list or '', ';;')
    local res = {}

    for _, v in ipairs(list) do
        v = mw.text.trim(v)
        table.insert(res, string.format("<code>%s</code>", v))
    end

    return table.concat(res, "<br><samp>OR</samp><br>")
end

function p._main(modn, func_list, example, showModuleName)
    local ret = mw.html.create('tr')
    local rowspan = math.max(#func_list, 1);
    local func = func_list[1];

    ret:IF(showModuleName)
        :td { '[[Module:' .. modn .. '|' .. modn .. ']]', attr = { 'rowspan', rowspan } } -- Name will group together with all functions once
        :END()
        :IF(func):exec(function(self)
        return self
            :td(formatFuncNames(func.fname))
            :td(func.ftype)
            :td(func.fdesc)
    end):ELSEIF(showModuleName or (example ~= nil))
        :td { class = "table-na", attr = { colspan = 3 } }
        :END()
        :IF(example == '')
        :td { attr = { 'rowspan', rowspan } }
        :ELSEIF(example ~= nil)
        :td { tostring(tooltip._span { name = modn, alt = 'Show' }) ..
        tostring(tooltip._div { name = modn, limitwidth = 'no', content = '<br>' .. (example or '') }),
            attr = { 'rowspan', rowspan } }
        :END()

    for i = 2, #func_list do
        func = func_list[i];
        ret:tr()
            :td(formatFuncNames(func.fname))
            :td(func.ftype)
            :td(func.fdesc)
    end
    return ret
end

return p
-- </nowiki>
