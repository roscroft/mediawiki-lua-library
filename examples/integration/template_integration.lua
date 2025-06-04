--[[
MediaWiki Template Integration Example

This example demonstrates how to create a MediaWiki Scribunto module that uses
the functional programming library to process template parameters and generate
dynamic content.

Usage in MediaWiki:
1. Create Module:TemplateProcessor
2. Use in templates: {{#invoke:TemplateProcessor|processItems}}
]] --

local p = {}

-- Import the functional programming modules
local Array = require('Module:Array')
local Functools = require('Module:Functools')
local TableTools = require('Module:TableTools')
local CodeStandards = require('Module:CodeStandards')

--[[
Process a list of items from template parameters
Parameters can be passed as: item1=value1|item2=value2|item3=value3
]] --
function p.processItems(frame)
    local success, result = CodeStandards.handleError(function()
        -- Extract parameters starting with "item"
        local items = Array.new()
        local itemPattern = "^item(%d+)$"

        -- Collect all item parameters
        for key, value in pairs(frame.args) do
            local itemNum = string.match(key, itemPattern)
            if itemNum and value ~= "" then
                items:push({
                    index = tonumber(itemNum),
                    value = value,
                    processed = false
                })
            end
        end

        -- Sort items by index
        items = items:sort(function(a, b) return a.index < b.index end)

        -- Process items using functional patterns
        local processedItems = items
            :map(function(item)
                return {
                    index = item.index,
                    value = item.value,
                    length = string.len(item.value),
                    words = Array.new(TableTools.split(item.value, "%s+")),
                    processed = true
                }
            end)
            :filter(function(item) return item.length > 0 end)

        -- Generate HTML output
        local htmlParts = processedItems:map(function(item)
            local wordCount = item.words:length()
            return string.format([[
                <div class="processed-item" data-index="%d">
                    <strong>Item %d:</strong> %s
                    <small>(%d words, %d characters)</small>
                </div>
            ]], item.index, item.index, item.value, wordCount, item.length)
        end)

        -- Combine into final output
        local header = string.format("<div class='item-processor'>")
        local footer = string.format("</div>")
        local body = htmlParts:join("\n")

        return header .. body .. footer
    end, "Template processing")

    if success then
        return result
    else
        return '<div class="error">Error processing template: ' .. tostring(result) .. '</div>'
    end
end

--[[
Create a navigation menu from template parameters
Parameters: menu1=Home|menu2=About|menu3=Contact
]] --
function p.createNavigation(frame)
    local success, result = CodeStandards.handleError(function()
        local menuItems = Array.new()

        -- Extract menu parameters
        for key, value in pairs(frame.args) do
            local menuNum = string.match(key, "^menu(%d+)$")
            if menuNum and value ~= "" then
                menuItems:push({
                    order = tonumber(menuNum),
                    title = value,
                    slug = string.lower(string.gsub(value, "%s+", "-"))
                })
            end
        end

        -- Sort and process menu items
        local navigation = menuItems
            :sort(function(a, b) return a.order < b.order end)
            :map(function(item)
                return string.format(
                    '<li><a href="#%s" class="nav-link">%s</a></li>',
                    item.slug,
                    item.title
                )
            end)
            :join("\n")

        return string.format([[
            <nav class="wiki-navigation">
                <ul>%s</ul>
            </nav>
        ]], navigation)
    end, "Navigation creation")

    return success and result or ('<div class="error">Navigation error: ' .. tostring(result) .. '</div>')
end

--[[
Advanced data transformation using functional composition
Demonstrates currying and function composition in MediaWiki context
]] --
function p.transformData(frame)
    local success, result = CodeStandards.handleError(function()
        local rawData = frame.args.data or ""

        -- Create transformation pipeline using functional composition
        local transformPipeline = Functools.compose(
        -- Step 3: Format as HTML list
            function(items)
                return "<ul>" .. items:join("") .. "</ul>"
            end,
            -- Step 2: Convert to HTML list items
            function(items)
                return items:map(function(item)
                    return "<li>" .. item .. "</li>"
                end)
            end,
            -- Step 1: Clean and filter items
            function(text)
                return Array.new(TableTools.split(text, "[,;]"))
                    :map(function(item) return string.gsub(item, "^%s*(.-)%s*$", "%1") end)
                    :filter(function(item) return item ~= "" end)
            end
        )

        return transformPipeline(rawData)
    end, "Data transformation")

    return success and result or ('<div class="error">Transform error: ' .. tostring(result) .. '</div>')
end

return p
