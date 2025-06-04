--[[
Complete Scribunto Module Example

This is a fully functional MediaWiki Scribunto module that demonstrates
how to integrate the functional programming library into a production
MediaWiki environment.

Usage:
1. Create this as "Module:FunctionalExample" in your MediaWiki
2. Call from templates: {{#invoke:FunctionalExample|processData}}
]] --

local p = {}

-- Import the functional programming modules
local Array = require('Module:Array')
local Functools = require('Module:Functools')
local TableTools = require('Module:TableTools')
local CodeStandards = require('Module:CodeStandards')

--[[
Process wiki data using functional programming patterns
Example: {{#invoke:FunctionalExample|processData|data=apple,banana,cherry|format=list}}
]] --
function p.processData(frame)
    local success, result = CodeStandards.handleError(function()
        local data = frame.args.data or ""
        local format = frame.args.format or "list"
        local separator = frame.args.separator or ","

        -- Parse input data
        local items = Array.new(TableTools.split(data, separator))
            :map(function(item) return string.gsub(item, "^%s*(.-)%s*$", "%1") end)
            :filter(function(item) return item ~= "" end)

        -- Apply transformations based on format
        if format == "list" then
            return items:map(function(item)
                return "* " .. item
            end):join("\n")
        elseif format == "numbered" then
            return items:mapWithIndex(function(item, index)
                return index .. ". " .. item
            end):join("\n")
        elseif format == "csv" then
            return items:join(", ")
        elseif format == "table" then
            local headers = "! Item !! Length !! Type"
            local rows = items:map(function(item)
                local itemType = tonumber(item) and "number" or "text"
                return string.format("|-\n| %s || %d || %s", item, #item, itemType)
            end):join("\n")

            return string.format("{| class=\"wikitable\"\n%s\n%s\n|}", headers, rows)
        else
            return "Unknown format: " .. format
        end
    end, "Data processing")

    return success and result or ('<div class="error">Error: ' .. tostring(result) .. '</div>')
end

--[[
Create a dynamic infobox using functional patterns
Example: {{#invoke:FunctionalExample|createInfobox|title=Example|field1=Value1|field2=Value2}}
]] --
function p.createInfobox(frame)
    local success, result = CodeStandards.handleError(function()
        local title = frame.args.title or "Information"
        local fields = Array.new()

        -- Extract field parameters
        for key, value in pairs(frame.args) do
            local fieldName = string.match(key, "^field(%d+)$")
            if fieldName and value ~= "" then
                fields:push({
                    order = tonumber(fieldName),
                    name = key,
                    value = value
                })
            end
        end

        -- Sort fields by order and create infobox
        local infoboxRows = fields
            :sort(function(a, b) return a.order < b.order end)
            :map(function(field)
                return string.format("|-\n! %s\n| %s", field.name, field.value)
            end)
            :join("\n")

        return string.format([[
{| class="infobox" style="border: 1px solid #aaa; float: right; margin: 0 0 1em 1em; width: 300px;"
|+ style="font-size: larger; font-weight: bold;" | %s
%s
|}]], title, infoboxRows)
    end, "Infobox creation")

    return success and result or ('<div class="error">Infobox error: ' .. tostring(result) .. '</div>')
end

--[[
Advanced data analysis with functional composition
Example: {{#invoke:FunctionalExample|analyzeData|numbers=1,5,3,9,2,7}}
]] --
function p.analyzeData(frame)
    local success, result = CodeStandards.handleError(function()
        local numbersStr = frame.args.numbers or ""

        -- Parse and validate numbers
        local numbers = Array.new(TableTools.split(numbersStr, "[,;%s]+"))
            :map(function(str) return tonumber(str) end)
            :filter(function(num) return num ~= nil end)

        if numbers:length() == 0 then
            return "No valid numbers provided"
        end

        -- Create analysis pipeline using function composition
        local analyzeNumbers = Functools.compose(
        -- Step 3: Format results
            function(stats)
                return string.format([[
=== Data Analysis Results ===
* '''Count:''' %d numbers
* '''Sum:''' %.2f
* '''Average:''' %.2f
* '''Minimum:''' %.2f
* '''Maximum:''' %.2f
* '''Range:''' %.2f
* '''Sorted:''' %s
]], stats.count, stats.sum, stats.average, stats.min, stats.max, stats.range, stats.sorted)
            end,
            -- Step 2: Calculate statistics
            function(nums)
                local sum = nums:reduce(function(acc, num) return acc + num end, 0)
                local sorted = nums:sort():join(", ")
                return {
                    count = nums:length(),
                    sum = sum,
                    average = sum / nums:length(),
                    min = nums:min(),
                    max = nums:max(),
                    range = nums:max() - nums:min(),
                    sorted = sorted
                }
            end,
            -- Step 1: Input validation (identity function)
            function(nums) return nums end
        )

        return analyzeNumbers(numbers)
    end, "Data analysis")

    return success and result or ('<div class="error">Analysis error: ' .. tostring(result) .. '</div>')
end

--[[
Category management using functional patterns
Example: {{#invoke:FunctionalExample|manageCategories|add=Category:Example|remove=Category:Old}}
]] --
function p.manageCategories(frame)
    local success, result = CodeStandards.handleError(function()
        local addCats = frame.args.add or ""
        local removeCats = frame.args.remove or ""

        -- Process category additions
        local additions = Array.new()
        if addCats ~= "" then
            additions = Array.new(TableTools.split(addCats, "[,;]"))
                :map(function(cat) return string.gsub(cat, "^%s*(.-)%s*$", "%1") end)
                :filter(function(cat) return cat ~= "" end)
                :map(function(cat)
                    -- Ensure proper category format
                    if not string.match(cat, "^Category:") then
                        cat = "Category:" .. cat
                    end
                    return "[[" .. cat .. "]]"
                end)
        end

        -- Process category removals (for documentation)
        local removals = Array.new()
        if removeCats ~= "" then
            removals = Array.new(TableTools.split(removeCats, "[,;]"))
                :map(function(cat) return string.gsub(cat, "^%s*(.-)%s*$", "%1") end)
                :filter(function(cat) return cat ~= "" end)
        end

        local result = ""

        -- Add categories
        if additions:length() > 0 then
            result = result .. additions:join("")
        end

        -- Document removals
        if removals:length() > 0 then
            result = result .. "<!-- Removed categories: " .. removals:join(", ") .. " -->"
        end

        return result
    end, "Category management")

    return success and result or ""
end

--[[
Performance monitoring integration
Shows how to use performance monitoring in production
]] --
function p.performanceDemo(frame)
    local success, result = CodeStandards.handleError(function()
        local iterations = tonumber(frame.args.iterations) or 100

        -- Demonstrate performance monitoring
        local testData = Array.new()
        for i = 1, iterations do
            testData:push(math.random(1, 1000))
        end

        -- Time different operations
        local sortedData = testData:sort()
        local filteredData = testData:filter(function(x) return x > 500 end)
        local mappedData = testData:map(function(x) return x * 2 end)

        -- Get performance metrics if available
        local metrics = CodeStandards.getPerformanceMetrics and
            CodeStandards.getPerformanceMetrics() or {}

        return string.format([[
=== Performance Demonstration ===
* '''Test Data Size:''' %d items
* '''Sorted Count:''' %d items
* '''Filtered Count:''' %d items (>500)
* '''Mapped Count:''' %d items (doubled)
* '''Performance Metrics:''' %d tracked functions

''Note: Performance monitoring is active for this module.''
]], testData:length(), sortedData:length(), filteredData:length(),
            mappedData:length(), TableTools.length(metrics))
    end, "Performance demonstration")

    return success and result or ('<div class="error">Performance demo error: ' .. tostring(result) .. '</div>')
end

return p
