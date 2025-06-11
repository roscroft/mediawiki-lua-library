--[[
Template Engine for Documentation Generation
Provides generic template rendering with support for different output formats.
]]

local TextUtils = require('utils.text-utils')

local TemplateEngine = {}
TemplateEngine.__index = TemplateEngine

-- Create a new template engine instance
-- @param config table Configuration for template rendering
-- @return table New template engine instance
function TemplateEngine.new(config)
    local self = {
        config = config or {},
        formatters = {}
    }
    setmetatable(self, TemplateEngine)
    return self
end

-- Add a custom formatter function
-- @param name string Name of the formatter
-- @param formatter function Formatter function
function TemplateEngine:addFormatter(name, formatter)
    self.formatters[name] = formatter
end

-- Render a template with data
-- @param templateName string Name of the template to render
-- @param data table Data to use in template rendering
-- @return string Rendered template
function TemplateEngine:render(templateName, data)
    if templateName == 'module' then
        return self:renderModuleDoc(data)
    elseif templateName == 'function' then
        return self:renderFunctionDoc(data)
    else
        error("Unknown template: " .. templateName)
    end
end

-- Render a complete module documentation
-- @param data table Module data {moduleName, functions}
-- @return string Rendered module documentation
function TemplateEngine:renderModuleDoc(data)
    local result = {}
    local config = self.config.mediawiki or {}

    -- Add header
    table.insert(result, config.header or "{{Documentation}}")
    table.insert(result, "|name = " .. data.moduleName)
    table.insert(result, "")

    -- Add each function's documentation
    for i, func in ipairs(data.functions) do
        local funcDoc = self:renderFunctionDoc({
            func = func,
            index = i,
            moduleName = data.moduleName
        })
        table.insert(result, funcDoc)
        table.insert(result, "")
    end

    -- Add example section
    local exampleConfig = config.exampleSection or {}
    table.insert(result, exampleConfig.header or "|example =")
    table.insert(result, exampleConfig.codeStart or "<syntaxhighlight lang='lua'>")
    local placeholder = exampleConfig.placeholder or "    -- Example usage of %s will be added manually"
    table.insert(result, string.format(placeholder, data.moduleName))
    table.insert(result, exampleConfig.codeEnd or "</syntaxhighlight>")
    table.insert(result, config.footer or "}}")

    return TextUtils.join(result, "\n")
end

-- Render a single function's documentation
-- @param data table Function data {func, index, moduleName}
-- @return string Rendered function documentation
function TemplateEngine:renderFunctionDoc(data)
    local func = data.func
    local index = data.index
    local moduleName = data.moduleName
    local config = self.config.mediawiki or {}
    local funcConfig = config.functionTemplate or {}
    local typeConfig = self.config.typeFormatting or {}

    local result = {}

    -- Extract the function name without the module prefix
    local displayName = func.name
    if displayName:find("^" .. moduleName .. "%.") then
        displayName = displayName:sub(#moduleName + 2) -- +2 accounts for the dot after module name
    end

    -- Format function name
    local fname = displayName .. "(&nbsp;" .. func.params_str .. "&nbsp;)"
    local namePrefix = funcConfig.namePrefix or "|fname"
    table.insert(result, string.format("%s%d = <nowiki>%s</nowiki>", namePrefix, index, TextUtils.escapePipes(fname)))

    -- Format type information
    local ftypeParts = {}
    if func.generics then
        for _, generic in ipairs(func.generics) do
            local typeTag = typeConfig.typeTag or "samp"
            local genericPrefix = typeConfig.genericPrefix or "generic: "
            table.insert(ftypeParts, string.format("<%s>%s%s: %s</%s>",
                typeTag, genericPrefix, TextUtils.escapePipes(generic.name), TextUtils.escapePipes(generic.type), typeTag))
        end
    end
    if func.params then
        for _, param in ipairs(func.params) do
            local typeTag = typeConfig.typeTag or "samp"
            local typeSeparator = typeConfig.typeSeparator or ": "
            table.insert(ftypeParts, string.format("<%s>%s%s%s</%s>",
                typeTag, TextUtils.escapePipes(param.name), typeSeparator, TextUtils.escapePipes(param.type), typeTag))
        end
    end

    local rType = (func.returns and func.returns.type) or "any"
    local returnArrow = typeConfig.returnArrow or "-> "
    local typeTag = typeConfig.typeTag or "samp"
    table.insert(ftypeParts, string.format("<%s>%s%s</%s>", typeTag, returnArrow, TextUtils.escapePipes(rType), typeTag))

    local paramSeparator = typeConfig.paramSeparator or "<br>"
    local ftype = TextUtils.join(ftypeParts, paramSeparator)
    local typePrefix = funcConfig.typePrefix or "|ftype"
    table.insert(result, string.format("%s%d = %s", typePrefix, index, ftype))

    -- Format description
    local descriptionText = ""
    if func.description and #func.description > 0 then
        descriptionText = TextUtils.join(func.description, "\n")
    end

    if TextUtils.isEmpty(descriptionText) then
        descriptionText = "No description available."
    else
        -- Convert single backtick inline code
        descriptionText = descriptionText:gsub("`([^`]+)`", "<code>%1</code>")
        -- Add newline before single asterisks for MediaWiki list formatting
        descriptionText = descriptionText:gsub("%*", "\n*")
    end

    local usePrefix = funcConfig.usePrefix or "|fuse"
    table.insert(result, string.format("%s%d = %s", usePrefix, index, descriptionText))

    -- Add function notes if available
    if func.notes and #func.notes > 0 then
        table.insert(result, "")
        for _, note in ipairs(func.notes) do
            -- Convert single backtick inline code in notes
            note = note:gsub("`([^`]+)`", "<code>%1</code>")
            if not note:find("<math>") then
                note = TextUtils.escapePipes(note)
            end
            table.insert(result, note)
        end
    end

    return TextUtils.join(result, "\n")
end

return TemplateEngine
