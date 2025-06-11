--[[
Template Engine for Documentation Generation
Provides generic template rendering with support for different output formats.
]]

-- Auto-initialize MediaWiki environment
require('MediaWikiAutoInit')

local TextUtils = require('utils.text-utils')

-- Load Helper_module (now always available due to auto-init)
local Helper_module = require('Helper_module')
local helper_available = true

local TemplateEngine = {}
TemplateEngine.__index = TemplateEngine

-- Create a new template engine instance
-- @param config table Configuration for template rendering
-- @return table New template engine instance
function TemplateEngine.new(config)
    local self = {
        config = config or {},
        formatters = {},
        useHelperModule = true -- Always true now
    }
    setmetatable(self, TemplateEngine)

    print("✅ TemplateEngine: Helper_module loaded successfully - using enhanced formatting")

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

    -- Use Helper_module if available for enhanced formatting
    if self.useHelperModule then
        return self:renderFunctionDocWithHelper(data)
    else
        return self:renderFunctionDocFallback(data)
    end
end

-- Enhanced function documentation using Helper_module
-- @param data table Function data {func, index, moduleName}
-- @return string Rendered function documentation
function TemplateEngine:renderFunctionDocWithHelper(data)
    local func = data.func
    local index = data.index
    local moduleName = data.moduleName
    local config = self.config.mediawiki or {}
    local funcConfig = config.functionTemplate or {}

    -- Safety check for Helper_module
    if not Helper_module then
        return self:renderFunctionDocFallback(data)
    end

    -- Use Helper_module's formatFunctionEntry for complete formatting
    local entry = Helper_module.formatFunctionEntry(func, index, moduleName)

    local result = {}

    -- Format using Helper_module's enhanced functions
    local namePrefix = funcConfig.namePrefix or "|fname"
    table.insert(result, string.format("%s%d = <nowiki>%s</nowiki>",
        namePrefix, index, entry.fname or ""))

    local typePrefix = funcConfig.typePrefix or "|ftype"
    table.insert(result, string.format("%s%d = %s", typePrefix, index, entry.ftype or ""))

    local usePrefix = funcConfig.usePrefix or "|fuse"
    table.insert(result, string.format("%s%d = %s", usePrefix, index, entry.fuse or ""))

    -- Handle notes if available
    if func.notes and #func.notes > 0 then
        table.insert(result, "")
        for _, note in ipairs(func.notes) do
            local formattedNote = Helper_module.formatDescription(note, {
                convertInlineCode = true
            })
            table.insert(result, formattedNote)
        end
    end

    return TextUtils.join(result, "\n")
end

-- Fallback function documentation (original implementation)
-- @param data table Function data {func, index, moduleName}
-- @return string Rendered function documentation
function TemplateEngine:renderFunctionDocFallback(data)
    local func = data.func
    local index = data.index
    local moduleName = data.moduleName
    local config = self.config.mediawiki or {}
    local funcConfig = config.functionTemplate or {}

    local result = {}

    -- Extract the function name without the module prefix
    local displayName = func.name
    if displayName:find("^" .. moduleName .. "%.") then
        displayName = displayName:sub(#moduleName + 2) -- +2 accounts for the dot after module name
    end

    -- Simple pipe escaping function (fallback if Helper_module not available)
    local function escapePipes(text)
        if not text then return "" end
        local result = text:gsub("|", "{{!}}")
        result = result:gsub("{", "{{(}}")
        result = result:gsub("}", "{{)}}")
        return result
    end

    -- Format function name
    local fname = displayName .. "(&nbsp;" .. func.params_str .. "&nbsp;)"
    local namePrefix = funcConfig.namePrefix or "|fname"
    table.insert(result, string.format("%s%d = <nowiki>%s</nowiki>",
        namePrefix, index, escapePipes(fname)))

    -- Format type information using simplified approach
    local ftypeParts = {}

    -- Add generics
    if func.generics then
        for _, generic in ipairs(func.generics) do
            local genericName = generic.name or ""
            local genericType = generic.type or "any"
            table.insert(ftypeParts, string.format("<samp>generic: %s: %s</samp>",
                escapePipes(genericName), escapePipes(genericType)))
        end
    end

    -- Add parameters
    if func.params then
        for _, param in ipairs(func.params) do
            local paramName = param.name or ""
            local paramType = param.type or "any"
            table.insert(ftypeParts, string.format("<samp>%s: %s</samp>",
                escapePipes(paramName), escapePipes(paramType)))
        end
    end

    -- Add return type
    local rType = (func.returns and func.returns.type) or "any"
    table.insert(ftypeParts, string.format("<samp>-> %s</samp>", escapePipes(rType)))

    local ftype = table.concat(ftypeParts, "<br>")
    local typePrefix = funcConfig.typePrefix or "|ftype"
    table.insert(result, string.format("%s%d = %s", typePrefix, index, ftype))

    -- Format description with improved handling
    local descriptionText = ""
    if func.description and #func.description > 0 then
        descriptionText = table.concat(func.description, "\n")
    end

    if not descriptionText or descriptionText == "" then
        descriptionText = "No description available."
    else
        -- Convert single backtick inline code
        descriptionText = descriptionText:gsub("`([^`]+)`", "<code>%1</code>")
        -- Add newline before single asterisks for MediaWiki list formatting
        descriptionText = descriptionText:gsub("^%*", "\n*")
        descriptionText = escapePipes(descriptionText)
    end

    local usePrefix = funcConfig.usePrefix or "|fuse"
    table.insert(result, string.format("%s%d = %s", usePrefix, index, descriptionText))

    -- Format function notes if available
    if func.notes and #func.notes > 0 then
        table.insert(result, "")
        for _, note in ipairs(func.notes) do
            local formattedNote = note:gsub("`([^`]+)`", "<code>%1</code>")
            -- Preserve math markup without escaping
            if not note:find("<math>") then
                formattedNote = escapePipes(formattedNote)
            end
            table.insert(result, formattedNote)
        end
    end

    return TextUtils.join(result, "\n")
end

return TemplateEngine
