--[[
Performance Regression Tests for Enhanced Array and Functools Modules

This test suite ensures that performance optimizations don't introduce regressions
and that new features perform within expected parameters.
]]

-- Setup paths and environment
package.path = package.path .. ';src/modules/?.lua'

-- Load MediaWiki environment
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

local Array = require('Array')
local functools = require('Functools')
local funclib = require('Funclib')

-- Test framework setup
local test = {}
local passed = 0
local failed = 0

local function assert_performance(name, operation, max_time, iterations)
    iterations = iterations or 1000
    
    print(string.format("Testing %s performance...", name))
    
    local start_time = os.clock()
    for i = 1, iterations do
        operation()
    end
    local end_time = os.clock()
    
    local total_time = end_time - start_time
    local avg_time = total_time / iterations
    
    local status = total_time <= max_time and "PASS" or "FAIL"
    print(string.format("%s: %s (%.4fs total, %.6fs avg, %d ops/s)", 
        name, status, total_time, avg_time, math.floor(iterations / total_time)))
    
    if total_time <= max_time then
        passed = passed + 1
    else
        failed = failed + 1
        print(string.format("  FAILED: Expected <= %.4fs, got %.4fs", max_time, total_time))
    end
end

local function assert_equal(actual, expected, message)
    if actual == expected then
        passed = passed + 1
        print("PASS: " .. (message or "values equal"))
    else
        failed = failed + 1
        print("FAIL: " .. (message or "values not equal"))
        print(string.format("  Expected: %s", tostring(expected)))
        print(string.format("  Actual: %s", tostring(actual)))
    end
end

-- ======================
-- ARRAY PERFORMANCE TESTS
-- ======================

-- Test Array.each optimization
local large_array = Array.range(1, 1000)
assert_performance("Array.each on large array", function()
    local sum = 0
    Array.each(large_array, function(x) sum = sum + x end)
end, 0.1)

-- Test Array.map optimization  
assert_performance("Array.map on large array", function()
    Array.map(large_array, function(x) return x * 2 end)
end, 0.15)

-- Test Array.filter optimization
assert_performance("Array.filter on large array", function()
    Array.filter(large_array, function(x) return x % 2 == 0 end)
end, 0.15)

-- Test Array.find optimization (early termination)
assert_performance("Array.find early termination", function()
    Array.find(large_array, function(x) return x > 10 end)
end, 0.01)

-- Test Array.find value search optimization
assert_performance("Array.find value search", function()
    Array.find(large_array, 500)
end, 0.05)

-- Test fast array operations
assert_performance("Array.fast.map with memoization", function()
    Array.fast.map({1, 2, 3, 4, 5}, function(x) return x * x end, true)
end, 0.01)

assert_performance("Array.fast.filter optimization", function()
    Array.fast.filter(large_array, function(x) return x > 500 end)
end, 0.1)

-- ======================
-- FUNCTOOLS PERFORMANCE TESTS
-- ======================

-- Test memoization performance
local expensive_fn = functools.memoize(function(x)
    local result = 0
    for i = 1, 100 do
        result = result + i * x
    end
    return result
end)

-- First call (cache miss)
assert_performance("Memoize cache miss", function()
    expensive_fn(10)
end, 0.01)

-- Second call (cache hit)
assert_performance("Memoize cache hit", function()
    expensive_fn(10)
end, 0.001)

-- Test function composition performance
local composed = functools.compose(
    function(x) return x * 2 end,
    function(x) return x + 1 end,
    function(x) return x * x end
)

assert_performance("Function composition", function()
    composed(5)
end, 0.001)

-- Test currying performance
local curried = functools.c3(function(a, b, c) return a + b + c end)
assert_performance("Curried function calls", function()
    curried(1)(2)(3)
end, 0.001)

-- Test chain_safe performance
local safe_chain = functools.chain_safe(
    function(x) return functools.Maybe.just(x * 2) end,
    function(x) return functools.Maybe.just(x + 1) end,
    function(x) return functools.Maybe.just(x / 2) end
)

assert_performance("Safe function chaining", function()
    safe_chain(10)
end, 0.01)

-- ======================
-- FUNCLIB PERFORMANCE TESTS
-- ======================

-- Test column building performance
assert_performance("Column building", function()
    funclib.make_column("Test", {align = "center", sortable = true})
end, 0.02)

-- Test fast column with caching
assert_performance("Fast column with caching", function()
    funclib.fast_column("Test", {align = "center"})
end, 0.001)

-- Test batch column creation
local column_configs = Array.map(Array.range(1, 50), function(i)
    return {header = "Column " .. i, options = {align = "left"}}
end)

assert_performance("Batch column creation", function()
    funclib.batch_columns(column_configs)
end, 0.05)

-- Test template builder performance
assert_performance("Template builder", function()
    local builder = funclib.template_builder("TestTemplate")
    builder:param("param1", "value1")
           :param("param2", "value2")
           :numbered_param("numbered1")
    builder:build()
end, 0.005)

-- ======================
-- MEMORY EFFICIENCY TESTS
-- ======================

-- Test memory usage
local test_array = Array.range(1, 100)
local memory_info = Array.getMemoryInfo(test_array)

print(string.format("\nMemory efficiency for 100-element array:"))
print(string.format("  Length: %d", memory_info.length))
print(string.format("  Memory: %.2f KB", memory_info.memory_kb))
print(string.format("  Efficiency: %.2f%%", memory_info.efficiency_ratio * 100))
print(string.format("  Avg bytes/element: %.2f", memory_info.avg_bytes_per_element))

-- Verify memory efficiency is reasonable
assert_equal(memory_info.length, 100, "Array length correct")
assert_equal(memory_info.efficiency_ratio > 0.1, true, "Memory efficiency reasonable")

-- ======================
-- CORRECTNESS TESTS
-- ======================

-- Verify optimizations don't break functionality
local test_data = {1, 2, 3, 4, 5}

-- Test Array.each correctness
local sum = 0
Array.each(test_data, function(x) sum = sum + x end)
assert_equal(sum, 15, "Array.each correctness")

-- Test Array.map correctness
local doubled = Array.map(test_data, function(x) return x * 2 end)
assert_equal(doubled[3], 6, "Array.map correctness")

-- Test Array.filter correctness
local evens = Array.filter(test_data, function(x) return x % 2 == 0 end)
assert_equal(#evens, 2, "Array.filter correctness")

-- Test Array.find correctness
local found, index = Array.find(test_data, function(x) return x > 3 end)
assert_equal(found, 4, "Array.find result correctness")
assert_equal(index, 4, "Array.find index correctness")

-- Test memoization correctness
local call_count = 0
local memoized = functools.memoize(function(x)
    call_count = call_count + 1
    return x * 2
end)

memoized(5)
memoized(5) -- Should not increase call_count
assert_equal(call_count, 1, "Memoization correctness")

-- ======================
-- BENCHMARK UTILITY TESTS
-- ======================

-- Test the benchmark utility itself
local bench_result = Array.benchmark(function()
    local sum = 0
    for i = 1, 100 do
        sum = sum + i
    end
end, 100, 10)

assert_equal(type(bench_result.total_time), "number", "Benchmark returns total_time")
assert_equal(type(bench_result.operations_per_second), "number", "Benchmark returns ops/sec")
assert_equal(bench_result.iterations, 100, "Benchmark tracks iterations correctly")

-- ======================
-- RESULTS SUMMARY
-- ======================

print(string.format("\n=== PERFORMANCE TEST RESULTS ==="))
print(string.format("Passed: %d", passed))
print(string.format("Failed: %d", failed))
print(string.format("Total: %d", passed + failed))

if failed > 0 then
    print("❌ Some performance tests failed!")
    return false
else
    print("✅ All performance tests passed!")
    return true
end
