-- Performance Benchmark Example
-- Demonstrates performance analysis tools and techniques

-- Load required modules
local PerformanceDashboard = require('src.modules.PerformanceDashboard')
local Array = require('src.modules.Array')
local Tables = require('src.modules.Tables')

print("=== Performance Benchmark Example ===")

-- Create test data
local smallArray = Array.new({})
for i = 1, 100 do
    smallArray:push(math.random(1, 1000))
end

local largeArray = Array.new({})
for i = 1, 10000 do
    largeArray:push(math.random(1, 1000))
end

-- Benchmark different sorting approaches
local function benchmarkSort()
    local results = {}

    -- Test 1: Native table.sort
    local start = os.clock()
    local nativeCopy = Tables.deepcopy(smallArray:toTable())
    table.sort(nativeCopy)
    local nativeTime = os.clock() - start
    results.native = nativeTime

    -- Test 2: Array sort method
    start = os.clock()
    local arrayCopy = Array.new(Tables.deepcopy(smallArray:toTable()))
    arrayCopy:sort()
    local arrayTime = os.clock() - start
    results.array = arrayTime

    -- Test 3: Custom quicksort implementation
    local function quicksort(arr, low, high)
        if low < high then
            local pi = partition(arr, low, high)
            quicksort(arr, low, pi - 1)
            quicksort(arr, pi + 1, high)
        end
    end

    local function partition(arr, low, high)
        local pivot = arr[high]
        local i = low - 1

        for j = low, high - 1 do
            if arr[j] <= pivot then
                i = i + 1
                arr[i], arr[j] = arr[j], arr[i]
            end
        end
        arr[i + 1], arr[high] = arr[high], arr[i + 1]
        return i + 1
    end

    start = os.clock()
    local customCopy = Tables.deepcopy(smallArray:toTable())
    quicksort(customCopy, 1, #customCopy)
    local customTime = os.clock() - start
    results.custom = customTime

    return results
end

-- Run benchmarks
print("\n1. Sorting Performance Comparison (100 elements):")
local sortResults = benchmarkSort()
print(string.format("Native sort: %.6f seconds", sortResults.native))
print(string.format("Array sort:  %.6f seconds", sortResults.array))
print(string.format("Custom sort: %.6f seconds", sortResults.custom))

-- Memory usage benchmark
print("\n2. Memory Usage Analysis:")
local function measureMemory(operation, iterations)
    collectgarbage("collect")
    local before = collectgatbage("count")

    for i = 1, iterations do
        operation()
    end

    collectgarbage("collect")
    local after = collectgarbage("count")
    return after - before
end

local function createArray()
    local arr = Array.new({})
    for i = 1, 1000 do
        arr:push(i)
    end
    return arr
end

local function createTable()
    local tbl = {}
    for i = 1, 1000 do
        tbl[i] = i
    end
    return tbl
end

local arrayMemory = measureMemory(createArray, 10)
local tableMemory = measureMemory(createTable, 10)

print(string.format("Array creation memory: %.2f KB", arrayMemory))
print(string.format("Table creation memory: %.2f KB", tableMemory))

-- Performance dashboard integration
print("\n3. Performance Dashboard Integration:")
if PerformanceDashboard then
    local metrics = {
        sort_native = sortResults.native,
        sort_array = sortResults.array,
        sort_custom = sortResults.custom,
        memory_array = arrayMemory,
        memory_table = tableMemory,
        timestamp = os.time()
    }

    print("Performance metrics collected:")
    for key, value in pairs(metrics) do
        if key ~= "timestamp" then
            print(string.format("  %s: %.6f", key, value))
        end
    end

    -- In a real scenario, you would save these metrics
    print("Metrics would be saved to performance dashboard")
else
    print("PerformanceDashboard module not available")
end

print("\n=== Benchmark Complete ===")
