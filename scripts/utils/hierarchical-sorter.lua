--[[
Hierarchical Sorting for Documentation Generation
Provides sophisticated function sorting based on object structure and hierarchy.
]]

local HierarchicalSorter = {}

-- Detect main object names from function names using statistical analysis
-- @param functions table Array of function objects
-- @return string|nil, table Primary object name and object counts
function HierarchicalSorter.detectObjectNames(functions)
    local objectCounts = {}
    local totalFunctions = 0

    for _, func in ipairs(functions) do
        totalFunctions = totalFunctions + 1
        local fullName = func.name

        -- Extract potential object names (before first dot)
        local objectName = fullName:match("^([^%.]+)%.")
        if objectName then
            objectCounts[objectName] = (objectCounts[objectName] or 0) + 1
        end
    end

    -- Find the primary object name (most frequently used, minimum 30% of functions)
    local primaryObject = nil
    local maxCount = 0
    local threshold = math.floor(totalFunctions * 0.3)

    for objName, count in pairs(objectCounts) do
        if count > maxCount and count >= threshold then
            maxCount = count
            primaryObject = objName
        end
    end

    return primaryObject, objectCounts
end

-- Parse hierarchical function name structure
-- @param functionName string Full function name
-- @param primaryObject string|nil Primary object name
-- @return table Hierarchy information
function HierarchicalSorter.parseHierarchicalName(functionName, primaryObject)
    -- Remove module prefix if present (e.g., "Module.func.ops.add" -> "func.ops.add")
    local cleanName = functionName:gsub("^[^%.]*%.", "", 1)

    -- Split by dots to get hierarchy levels
    local parts = {}
    for part in cleanName:gmatch("[^%.]+") do
        table.insert(parts, part)
    end

    if #parts == 0 then
        return {
            depth = 0,
            objectPath = "",
            subPath = "",
            functionName = functionName,
            sortKey = "0000_" .. functionName
        }
    end

    local funcName = parts[#parts] -- Last part is the function name
    local objectPath = ""
    local subPath = ""

    if #parts > 1 then
        -- Build object path (all parts except the last)
        local pathParts = {}
        for i = 1, #parts - 1 do
            table.insert(pathParts, parts[i])
        end
        objectPath = table.concat(pathParts, ".")

        -- Extract subpath (everything after primary object)
        if primaryObject and objectPath:find("^" .. primaryObject .. "%.") then
            subPath = objectPath:sub(#primaryObject + 2) -- +2 to skip the dot
        elseif primaryObject and objectPath == primaryObject then
            subPath = ""
        else
            subPath = objectPath
        end
    end

    local depth = #parts - 1

    -- Create sort key: depth (descending) + object path (ascending) + function name (ascending)
    -- Format: 9999-depth_objectpath_functionname
    local depthKey = string.format("%04d", 9999 - depth)
    local sortKey = depthKey .. "_" .. objectPath .. "_" .. funcName

    return {
        depth = depth,
        objectPath = objectPath,
        subPath = subPath,
        functionName = funcName,
        sortKey = sortKey
    }
end

-- Sort functions using hierarchical criteria
-- @param functions table Array of function objects to sort
-- @param config table Configuration options
function HierarchicalSorter.sortFunctionsHierarchically(functions, config)
    config = config or {}
    local debugConfig = config.debug or {}

    -- Detect primary object names
    local primaryObject, objectCounts = HierarchicalSorter.detectObjectNames(functions)

    if debugConfig.showObjectDetection then
        print(string.format("  Detected primary object: %s", primaryObject or "none"))
        if primaryObject then
            print(string.format("  Object usage counts: %s=%d", primaryObject, objectCounts[primaryObject]))
            for obj, count in pairs(objectCounts) do
                if obj ~= primaryObject then
                    print(string.format("    %s=%d", obj, count))
                end
            end
        end
    end

    -- Parse hierarchical structure for each function
    for _, func in ipairs(functions) do
        func.hierarchy = HierarchicalSorter.parseHierarchicalName(func.name, primaryObject)
    end

    -- Sort by hierarchical criteria
    table.sort(functions, function(a, b)
        local aHier, bHier = a.hierarchy, b.hierarchy

        -- Primary sort: by depth (descending - deeper hierarchies first)
        if aHier.depth ~= bHier.depth then
            return aHier.depth > bHier.depth
        end

        -- Secondary sort: by object path (ascending - alphabetical)
        if aHier.objectPath ~= bHier.objectPath then
            return aHier.objectPath < bHier.objectPath
        end

        -- Tertiary sort: by function name (ascending - alphabetical)
        return aHier.functionName < bHier.functionName
    end)

    -- Debug output
    if debugConfig.showSortingOrder then
        print("  Function sorting order:")
        local maxDebugOutput = config.parsing and config.parsing.maxDebugOutput or 10
        for i, func in ipairs(functions) do
            local h = func.hierarchy
            print(string.format("    %d. %s (depth=%d, path='%s', func='%s')",
                i, func.name, h.depth, h.objectPath, h.functionName))
            if i > maxDebugOutput then
                print(string.format("    ... and %d more functions", #functions - maxDebugOutput))
                break
            end
        end
    end
end

return HierarchicalSorter
