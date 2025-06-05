-- Use global libraryUtil from MediaWiki environment
local checkType = libraryUtil.checkType
local checkTypeMulti = libraryUtil.checkTypeMulti
local Array = require('Array')

-- Lua 5.1/5.2+ compatibility
---@diagnostic disable-next-line: deprecated
local unpack = unpack or table.unpack

-- ======================
-- PERFORMANCE OPTIMIZATIONS & BENCHMARKING
-- ======================

---Calculates the length of arrays including proxy arrays
---
---This function provides optimized length calculation for different array types:
---- Standard arrays: Uses native # operator (O(1))
---- Proxy arrays: Uses exponential search followed by binary search (O(log n))
---- Empty arrays: Quick detection and return (O(1))
---
---Performance characteristics:
---- Standard arrays with consecutive integer keys: O(1)
---- Proxy arrays or arrays with holes: O(log n)
---- Empty arrays: O(1) with early detection
---Examples:
---```
---local std_array = {1, 2, 3}  -- Standard array
---local proxy_array = setmetatable({[1] = 'a', [2] = 'b'}, proxy_mt)
---print(len(std_array))    -- 3 (O(1) operation)
---print(len(proxy_array))  -- 2 (O(log n) operation)
---print(len({}))           -- 0 (O(1) early detection)
---```
---@param arr any[] Array to measure (can be standard array or proxy table)
---@return integer length The number of elements in the array
local function len(arr)
    local l = #arr
    if l == 0 then
        if arr[1] ~= nil then
            -- Exponential search to find length of proxy table
            local low = 1
            local high = 1
            local ceil = math.ceil
            while arr[high] ~= nil do
                high = high * 2
            end
            while low ~= high do
                local m = ceil((low + high) / 2)
                if arr[m] == nil then
                    high = m - 1
                else
                    low = m
                end
            end
            return low
        else
            return 0
        end
    else
        return l
    end
end

local ArrayOpt = {}

---Memoization cache for frequently called array operations
local memoCache = {}
local maxCacheSize = 1000
local cacheSize = 0

---Clear the memoization cache
function ArrayOpt.clearCache()
    memoCache = {}
    cacheSize = 0
end

---Memoize a function with array-aware key generation
---@generic T, R
---@param fn fun(...: T): R Function to memoize
---@param keyGenerator? fun(...: T): string Custom key generation function
---@return fun(...: T): R Memoized function
local function memoize(fn, keyGenerator)
    return function(...)
        local key
        if keyGenerator then
            key = keyGenerator(...)
        else
            -- Default key generation for arrays
            local args = { ... }
            local parts = {}
            for i, arg in ipairs(args) do
                if type(arg) == 'table' then
                    -- Generate a hash for array contents
                    local hash = 0
                    for j = 1, math.min(len(arg), 10) do -- Limit for performance
                        if arg[j] ~= nil then
                            hash = hash + j * (tonumber(arg[j]) or #tostring(arg[j]))
                        end
                    end
                    parts[i] = string.format("arr_%d_%d", len(arg), hash)
                else
                    parts[i] = tostring(arg)
                end
            end
            key = table.concat(parts, "_")
        end

        if memoCache[key] == nil then
            -- Prevent cache from growing too large
            if cacheSize >= maxCacheSize then
                ArrayOpt.clearCache()
            end
            memoCache[key] = fn(...)
            cacheSize = cacheSize + 1
        end
        return memoCache[key]
    end
end

---Benchmark utility for measuring array operation performance
---@param operation function Function to benchmark
---@param iterations? integer Number of iterations (default: 1000)
---@param warmup? integer Number of warmup iterations (default: 100)
---@return table Performance metrics
function ArrayOpt.benchmark(operation, iterations, warmup)
    iterations = iterations or 1000
    warmup = warmup or 100

    -- Warmup phase
    for i = 1, warmup do
        operation()
    end

    -- Actual benchmark
    local startTime = os.clock()
    for i = 1, iterations do
        operation()
    end
    local endTime = os.clock()

    local totalTime = endTime - startTime
    local avgTime = totalTime / iterations

    return {
        total_time = totalTime,
        average_time = avgTime,
        iterations = iterations,
        operations_per_second = iterations / totalTime
    }
end

---Create performance-optimized versions of common operations
ArrayOpt.fast = {}

---Fast map operation with optional memoization for pure functions
---@generic T: any[]
---@param arr T
---@param fn function
---@param useMemo? boolean Enable memoization for the function
---@return T
function ArrayOpt.fast.map(arr, fn, useMemo)
    checkType('Module:Array.fast.map', 1, arr, 'table')
    checkType('Module:Array.fast.map', 2, fn, 'function')

    local mapFn = useMemo and memoize(fn) or fn
    local r = {}
    local l = 0
    local array_len = len(arr)

    -- Pre-allocate result array for better performance
    if array_len > 0 then
        for i = 1, array_len do
            local tmp = mapFn(arr[i], i)
            if tmp ~= nil then
                l = l + 1
                r[l] = tmp
            end
        end
    end

    return setmetatable(r, getmetatable(arr))
end

---Fast filter with optimized predicate caching
---@generic T: any[]
---@param arr T
---@param fn function
---@return T
function ArrayOpt.fast.filter(arr, fn)
    checkType('Module:Array.fast.filter', 1, arr, 'table')
    checkType('Module:Array.fast.filter', 2, fn, 'function')

    local r = {}
    local l = 0
    local array_len = len(arr)

    -- Optimized loop with minimal function calls
    for i = 1, array_len do
        local elem = arr[i]
        if fn(elem, i) then
            l = l + 1
            r[l] = elem
        end
    end

    return setmetatable(r, getmetatable(arr))
end

-- ======================
-- MEMORY OPTIMIZATION UTILITIES
-- ======================

---Get memory usage statistics for an array
---@param arr any[]
---@return table Memory usage information
function ArrayOpt.getMemoryInfo(arr)
    checkType('Module:Array.getMemoryInfo', 1, arr, 'table')

    local function sizeof(obj, visited)
        visited = visited or {}
        if visited[obj] then return 0 end
        visited[obj] = true

        local bytes = 0
        local objType = type(obj)

        if objType == "table" then
            bytes = bytes + 40                                               -- Base table overhead
            for k, v in pairs(obj) do
                bytes = bytes + sizeof(k, visited) + sizeof(v, visited) + 32 -- Entry overhead
            end
        elseif objType == "string" then
            bytes = bytes + #obj + 24 -- String overhead
        elseif objType == "number" then
            bytes = bytes + 8
        elseif objType == "boolean" then
            bytes = bytes + 1
        else
            bytes = bytes + 8 -- Reference size
        end

        return bytes
    end

    local arrayLen = len(arr)
    local memoryUsed = sizeof(arr)
    local efficiency = arrayLen > 0 and (arrayLen * 8) / memoryUsed or 0

    return {
        length = arrayLen,
        memory_bytes = memoryUsed,
        memory_kb = memoryUsed / 1024,
        efficiency_ratio = efficiency,
        avg_bytes_per_element = arrayLen > 0 and memoryUsed / arrayLen or 0
    }
end
