-- <nowiki>
-- Helps [[RuneScape:Lua/Helper modules]] format its table with dynamic documentation
-- See [[Template:Helper module]] for documentation and usage

-- Auto-initialize MediaWiki environment (eliminates conditional imports)
require('MediaWikiAutoInit')

require('Mw_html_extension')
local getArgs = require('Arguments').getArgs
local tooltip = require('Tooltip')
local p = {}

function p.main(frame)
    local args = getArgs(frame)
    local function_list = {}
    -- Parse function parameters from template arguments (no limit)
    local i = 1
    while args['fname' .. i] do
        function_list[i] = {
            fname = args['fname' .. i] or '',
            ftype = args['ftype' .. i] or '',
            fdesc = args['fuse' .. i] or ''
        }
        i = i + 1
    end

    local title = mw.title.getCurrentTitle()
    if not args.name then
        return error(
            'Missing required parameter \'name\' to &#123;&#123;[[Template:Helper module|Helper module]]&#125;&#125;',
            2
        )
    end

    if title.namespace == 828 and (title.text == args.name or title.text == args.name .. '/doc') then
        local t = ''
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

        -- Check if this is a documentation subpage
        local isDocPage = title.isSubpage and title.subpageText == 'doc'

        local category = ''
        if not isDocPage then
            category = '[[Category:Helper modules]][[Category:Modules required by modules]]'
        end

        local reqby = ''
        if not isDocPage then
            local uri = mw.uri.canonicalUrl('Special:WhatLinksHere', 'target=Module:' .. args.name .. '&namespace=828')
            reqby = 'For a full list of modules using this helper <span class="plainlinks">[' ..
                tostring(uri) .. ' click here]</span>\n'
        end

        local example = ''
        if args.example then
            example = '\'\'\'Example:\'\'\'\n' .. args.example
        end

        return
            'This module is a helper module to be used by other modules; it may not be designed to be invoked directly. See [[RuneScape:Lua/Helper modules]] for a full list and more information.\n' ..
            reqby .. tostring(t) .. example .. category
    else
        return p._main(args.name, function_list, args.example or '', true)
    end
end

---Format function names with code formatting
---@param list string Semicolon-separated list of function names
---@return string Formatted function names with HTML markup
local function formatFuncNames(list)
    local parts = mw.text.split(list or '', ';;')
    local res = {}

    for _, v in ipairs(parts) do
        v = mw.text.trim(v)
        table.insert(res, string.format('<code>%s</code>', v))
    end

    return table.concat(res, '<br><samp>OR</samp><br>')
end

function p._main(modn, func_list, example, showModuleName)
    local ret = mw.html.create('tr')
    local rowspan = math.max(#func_list, 1)
    local func = func_list[1]

    ret:IF(showModuleName)
        :td { '[[Module:' .. modn .. '|' .. modn .. ']]', attr = { 'rowspan', rowspan } }
        :END()
        :IF(func):exec(function(self)
        return self
            :td(formatFuncNames(func.fname))
            :td(func.ftype)
            :td(func.fdesc)
    end):ELSEIF(showModuleName or (example ~= nil))
        :td { class = 'table-na', attr = { colspan = 3 } }
        :END()
        :IF(example == '')
        :td { attr = { 'rowspan', rowspan } }
        :ELSEIF(example ~= nil)
        :td { tostring(tooltip._span { name = modn, alt = 'Show' }) ..
        tostring(tooltip._div { name = modn, limitwidth = 'no', content = '<br>' .. (example or '') }),
            attr = { 'rowspan', rowspan } }
        :END()

    for i = 2, #func_list do
        func = func_list[i]
        ret:tr()
            :td(formatFuncNames(func.fname))
            :td(func.ftype)
            :td(func.fdesc)
    end
    return ret
end

---Pipe escaping with MediaWiki-specific handling
---@param text string Text to escape
---@return string Escaped text safe for MediaWiki templates
function p.escapePipes(text)
    if not text then return "" end
    -- Enhanced escaping for MediaWiki templates
    local result = text:gsub("|", "{{!}}")
    result = result:gsub("{", "{{(}}")
    result = result:gsub("}", "{{)}}")
    return result
end

---Format a list of parameters with consistent MediaWiki styling
---@param params table Array of {name, type} parameter objects
---@param options table? Formatting options {tag="samp", separator="<br>", prefix="", suffix=""}
---@return string Formatted parameter list
function p.formatParameterList(params, options)
    options = options or {}
    local tag = options.tag or "samp"
    local separator = options.separator or "<br>"
    local prefix = options.prefix or ""
    local suffix = options.suffix or ""

    local formatted = {}
    for _, param in ipairs(params) do
        local name = p.escapePipes(param.name or "")
        local paramType = p.escapePipes(param.type or "any")
        local formatted_param = string.format("<%s>%s: %s</%s>", tag, name, paramType, tag)
        table.insert(formatted, formatted_param)
    end

    return prefix .. table.concat(formatted, separator) .. suffix
end

---Format function signature with consistent styling
---@param funcData table Function data {name, params, returns, generics}
---@param options table? Formatting options
---@return string Complete formatted function type signature
function p.formatFunctionSignature(funcData, options)
    options = options or {}
    local parts = {}

    -- Add generics
    if funcData.generics and #funcData.generics > 0 then
        for _, generic in ipairs(funcData.generics) do
            local formatted = string.format("<samp>generic: %s: %s</samp>",
                p.escapePipes(generic.name),
                p.escapePipes(generic.type))
            table.insert(parts, formatted)
        end
    end

    -- Add parameters
    if funcData.params and #funcData.params > 0 then
        local paramList = p.formatParameterList(funcData.params)
        table.insert(parts, paramList)
    end

    -- Add return type
    local returnType = (funcData.returns and funcData.returns.type) or "any"
    table.insert(parts, string.format("<samp>-> %s</samp>", p.escapePipes(returnType)))

    return table.concat(parts, "<br>")
end

---Format MediaWiki code blocks with proper escaping
---@param code string Code content
---@param language string? Programming language (default: "lua")
---@param options table? Additional options {highlight, lineNumbers}
---@return string Formatted code block
function p.formatCodeBlock(code, language, options)
    language = language or "lua"
    options = options or {}

    local result = {}
    table.insert(result, string.format("<syntaxhighlight lang='%s'", language))

    if options.highlight then
        table.insert(result, string.format(" highlight='%s'", options.highlight))
    end
    if options.lineNumbers then
        table.insert(result, " line")
    end

    table.insert(result, ">")
    table.insert(result, code)
    table.insert(result, "</syntaxhighlight>")

    return table.concat(result)
end

---Format description text with MediaWiki markup conversion
---@param description string|table Raw description text or array of lines
---@param options table? Formatting options {convertInlineCode, addBullets}
---@return string Formatted description with proper MediaWiki markup
function p.formatDescription(description, options)
    options = options or {}

    local text = type(description) == "table" and table.concat(description, "\n") or tostring(description or "")
    if not text or text == "" then
        return "No description available."
    end

    -- Convert inline code - capture only the string result
    if options.convertInlineCode ~= false then
        text = (text:gsub("`([^`]+)`", "<code>%1</code>"))
    end

    -- Add bullet formatting - capture only the string result
    if options.addBullets then
        text = (text:gsub("^%*", "\n*"))
    end

    return p.escapePipes(text)
end

---Format a complete function entry for Helper module template
---@param funcData table Function data with all properties
---@param index number Function index for template numbering
---@param moduleName string? Module name for display name extraction
---@return table Template entries {fname, ftype, fuse}
function p.formatFunctionEntry(funcData, index, moduleName)
    -- Extract display name
    local displayName = funcData.name
    if moduleName and displayName:find("^" .. moduleName .. "%.") then
        displayName = displayName:sub(#moduleName + 2)
    end

    -- Format function name with parameters
    local fname = displayName .. "(&nbsp;" .. (funcData.params_str or "") .. "&nbsp;)"

    -- Use the enhanced signature formatter
    local ftype = p.formatFunctionSignature({
        generics = funcData.generics,
        params = funcData.params,
        returns = funcData.returns
    })

    -- Format description with enhanced formatting
    local fuse = p.formatDescription(funcData.description, {
        convertInlineCode = true,
        addBullets = true
    })

    return {
        fname = fname,
        ftype = ftype,
        fuse = fuse
    }
end

return p
-- </nowiki>
