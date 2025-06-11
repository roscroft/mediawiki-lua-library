#!/usr/bin/env lua
--[[
Simple Working MediaWiki Documentation Generator
===============================================

This generator creates MediaWiki documentation with:
- {{Documentation}} template format
- Function parameter documentation
- Proper MediaWiki markup formatting

Usage: lua generate-docs-mediawiki-simple.lua [module_name]
]]

-- Configuration
local config = {
    sourceDir = "src/modules",
    outputDir = "tools/module-docs"
}

-- Simple function to extract basic function information
local function extractFunctions(content)
    local functions = {}
    local lines = {}
    
    -- Split content into lines
    for line in content:gmatch("([^\r\n]*)\r?\n?") do
        table.insert(lines, line)
    end
    
    for i, line in ipairs(lines) do
        -- Look for function definitions
        local funcName = line:match("([%w_%.]+)%s*=%s*function%s*%(")
        if not funcName then
            funcName = line:match("function%s+([%w_%.]+)%s*%(")
        end
        if not funcName then
            funcName = line:match("local%s+function%s+([%w_%.]+)%s*%(")
        end
        
        if funcName then
            -- Extract parameters from function signature
            local params = {}
            local paramString = line:match("%((.-)%)")
            if paramString and paramString ~= "" then
                for param in paramString:gmatch("([^,]+)") do
                    param = param:gsub("^%s+", ""):gsub("%s+$", "")
                    if param ~= "" then
                        table.insert(params, param)
                    end
                end
            end
            
            -- Look for JSDoc description in preceding comments
            local description = "No description available."
            for j = i - 1, math.max(1, i - 10), -1 do
                local commentLine = lines[j]
                if commentLine:match("^%s*%-%-%-") then
                    local cleanComment = commentLine:gsub("^%s*%-%-%-?%s*", "")
                    if cleanComment ~= "" and not cleanComment:match("^@") then
                        description = cleanComment
                        break
                    end
                end
            end
            
            table.insert(functions, {
                name = funcName,
                params = params,
                description = description,
                lineNumber = i
            })
        end
    end
    
    return functions
end

-- Generate MediaWiki documentation
local function generateMediaWikiDoc(moduleName, functions)
    local parts = {}
    
    -- Header
    table.insert(parts, "{{Documentation}}")
    table.insert(parts, "|name = " .. moduleName)
    table.insert(parts, "")
    
    -- Functions
    for i, func in ipairs(functions) do
        -- Function name with parameters
        local signature = func.name
        if #func.params > 0 then
            signature = signature .. "(&nbsp;" .. table.concat(func.params, ", ") .. "&nbsp;)"
        else
            signature = signature .. "()"
        end
        
        table.insert(parts, "|fname" .. i .. " = <nowiki>" .. signature .. "</nowiki>")
        table.insert(parts, "|ftype" .. i .. " = <samp>-> any</samp>")
        table.insert(parts, "|fuse" .. i .. " = " .. func.description)
        table.insert(parts, "")
    end
    
    -- Footer
    table.insert(parts, "}}")
    
    return table.concat(parts, "\n")
end

-- Process a single module
local function processModule(moduleName)
    print("🔍 Processing module: " .. moduleName)
    
    -- Read source file
    local sourcePath = config.sourceDir .. "/" .. moduleName .. ".lua"
    local file = io.open(sourcePath, "r")
    if not file then
        print("❌ Could not read: " .. sourcePath)
        return false
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Extract functions
    local functions = extractFunctions(content)
    print("📊 Found " .. #functions .. " functions")
    
    -- Generate documentation
    local documentation = generateMediaWikiDoc(moduleName, functions)
    
    -- Ensure output directory exists
    os.execute("mkdir -p " .. config.outputDir)
    
    -- Write output
    local outputPath = config.outputDir .. "/" .. moduleName .. ".wiki"
    local outFile = io.open(outputPath, "w")
    if not outFile then
        print("❌ Could not write: " .. outputPath)
        return false
    end
    
    outFile:write(documentation)
    outFile:close()
    
    print("✅ Generated: " .. outputPath .. " (" .. #documentation .. " bytes)")
    return true
end

-- Main execution
local function main()
    print("📚 Simple MediaWiki Documentation Generator")
    print("=" .. string.rep("=", 45))
    
    local moduleName = arg and arg[1]
    print("🎯 Module to process:", moduleName or "ALL")
    
    if moduleName then
        processModule(moduleName)
    else
        print("🔄 Processing all modules...")
        local sourceDir = config.sourceDir
        local handle = io.popen("ls " .. sourceDir .. "/*.lua 2>/dev/null")
        if handle then
            local count = 0
            for filename in handle:lines() do
                local module = filename:match("([^/]+)%.lua$")
                if module then
                    if processModule(module) then
                        count = count + 1
                    end
                end
            end
            handle:close()
            print("✅ Processed " .. count .. " modules")
        end
    end
end

-- Execute
local success, err = pcall(main)
if not success then
    print("❌ Error: " .. tostring(err))
    os.exit(1)
end
