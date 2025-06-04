--[[
Comprehensive Integration Tests for Enhanced Wiki Lua Project

This test suite validates the integration and interaction between all modules
in the enhanced Wiki Lua project, ensuring that all components work together
seamlessly and that the functional programming workflows operate correctly.

Test Coverage:
- Cross-module integration
- Functional programming workflows  
- Performance consistency across modules
- Error handling standardization
- Advanced features compatibility
- Real-world usage scenarios

@module test_integration
@author Wiki Lua Team
@license MIT
@version 1.0.0
]]

-- Setup proper paths for module loading
package.path = package.path .. ';../../src/modules/?.lua'

-- Load environment setup
dofile('../env/wiki-lua-env.lua')

-- Module imports with proper paths
local Array = require('../../src/modules/Array')
local functools = require('../../src/modules/Functools')
local funclib = require('../../src/modules/Funclib')
local standards = require('../../src/modules/CodeStandards')
-- Note: AdvancedFunctional module has been removed as part of API migration

-- Test framework
local test = {}
local passed = 0
local failed = 0

local function assert_equal(actual, expected, message)
    if actual == expected then
        passed = passed + 1
        print("✓ PASS: " .. (message or "values equal"))
    else
        failed = failed + 1
        print("✗ FAIL: " .. (message or "values not equal"))
        print(string.format("  Expected: %s", tostring(expected)))
        print(string.format("  Actual: %s", tostring(actual)))
    end
end

local function assert_true(condition, message)
    assert_equal(condition, true, message)
end

local function assert_false(condition, message)
    assert_equal(condition, false, message)
end

local function assert_type(actual, expected_type, message)
    assert_equal(type(actual), expected_type, message)
end

local function assert_not_nil(value, message)
    assert_true(value ~= nil, message or "value should not be nil")
end

-- ======================
-- CROSS-MODULE INTEGRATION TESTS
-- ======================

print("\n=== Cross-Module Integration Tests ===")

-- Test Array + Functools integration
print("\n--- Array + Functools Integration ---")

local test_data = Array.range(1, 10)
local mapped_with_functools = Array.map(test_data, functools.c2(functools.ops.add)(5))
assert_equal(mapped_with_functools[1], 6, "Array.map with curried functools operation")
assert_equal(mapped_with_functools[5], 10, "Array.map with curried functools operation (middle)")

-- Test functional composition with arrays
local compose_test = functools.compose(
    Array.sum,
    functools.pmap(function(x) return x * 2 end),
    Array.filter(function(x) return x % 2 == 0 end)
)
local composition_result = compose_test({1, 2, 3, 4, 5, 6})
assert_equal(composition_result, 24, "Functional composition with Array operations") -- (2+4+6)*2 = 24

-- Test Funclib + Array integration
print("\n--- Funclib + Array Integration ---")

local column_configs = Array.map(Array.range(1, 3), function(i)
    return {header = "Col" .. i, options = {align = "center"}}
end)

local batch_result = funclib.batch_columns(column_configs)
assert_equal(#batch_result, 3, "Batch column creation with Array.map")
assert_equal(batch_result[1].header, "Col1", "Batch column creation correctness")

-- Test CodeStandards integration
print("\n--- CodeStandards Integration ---")

-- Test standardized function creation with Array operations
local standardized_sum = standards.createStandardizedFunction({
    module_name = 'TestModule',
    function_name = 'standardized_sum',
    fn = Array.sum,
    validations = {
        {name = 'array', rules = {type = 'table', required = true}}
    },
    default_return = 0
})

local sum_result = standardized_sum({1, 2, 3, 4, 5})
assert_equal(sum_result, 15, "Standardized Array.sum function")

-- Test error logging
local invalid_result = standardized_sum(nil)
assert_equal(invalid_result, 0, "Standardized function default return on validation failure")

local error_log = standards.getErrorLog()
assert_true(#error_log > 0, "Error logging captured validation failure")

-- ======================
-- FUNCTIONAL PROGRAMMING WORKFLOW TESTS
-- ======================

print("\n=== Functional Programming Workflow Tests ===")

-- Test Maybe monad workflow
print("\n--- Maybe Monad Workflow ---")

local safe_divide = function(x, y)
    if y == 0 then
        return functools.Maybe.nothing
    else
        return functools.Maybe.just(x / y)
    end
end

local maybe_workflow = functools.compose(
    functools.Maybe.getOrElse(-1),
    functools.Maybe.map(function(x) return x * 2 end),
    function(x) return safe_divide(x, 2) end
)

assert_equal(maybe_workflow(10), 10, "Maybe workflow with valid input") -- 10/2 * 2 = 10
assert_equal(maybe_workflow(0), -1, "Maybe workflow with edge case") -- 0/2 * 2 = 0, but 0 is falsy so -1

-- Test Either monad workflow (AdvancedFunctional) - REMOVED
-- Note: AdvancedFunctional module removed during API migration
print("\n--- Either Monad Workflow - SKIPPED ---")
print("AdvancedFunctional module removed during API migration")

-- Test State monad workflow - REMOVED  
print("\n--- State Monad Workflow - SKIPPED ---")
print("AdvancedFunctional module removed during API migration")

local state_result = advanced.State.run(counter_workflow, 5)
assert_equal(state_result[1], 6, "State monad workflow result")
assert_equal(state_result[2], 6, "State monad workflow final state")

-- ======================
-- PERFORMANCE INTEGRATION TESTS
-- ======================

print("\n=== Performance Integration Tests ===")

-- Test performance monitoring across modules
standards.clearPerformanceMetrics()

local perf_test_data = Array.range(1, 1000)

-- Array operations with performance monitoring
local monitored_map = standards.wrapWithPerformanceMonitoring('Array', 'map', Array.map)
local monitored_filter = standards.wrapWithPerformanceMonitoring('Array', 'filter', Array.filter)

local map_result = monitored_map(perf_test_data, function(x) return x * 2 end)
local filter_result = monitored_filter(perf_test_data, function(x) return x % 2 == 0 end)

local metrics = standards.getPerformanceMetrics()
assert_not_nil(metrics['Array.map'], "Performance metrics captured for Array.map")
assert_not_nil(metrics['Array.filter'], "Performance metrics captured for Array.filter")

-- Test memoization integration
print("\n--- Memoization Integration ---")

local expensive_operation = function(n)
    local sum = 0
    for i = 1, n do
        sum = sum + i
    end
    return sum
end

local memoized_operation = advanced.memoizeAdvanced(
    expensive_operation,
    advanced.MemoizationStrategy.lru(10)
)

local start_time = os.clock()
local result1 = memoized_operation(100)
local first_call_time = os.clock() - start_time

start_time = os.clock()
local result2 = memoized_operation(100) -- Should be cached
local second_call_time = os.clock() - start_time

assert_equal(result1, result2, "Memoized function returns same result")
assert_true(second_call_time < first_call_time, "Memoized call is faster than original")

-- ======================
-- ERROR HANDLING INTEGRATION TESTS
-- ======================

print("\n=== Error Handling Integration Tests ===")

-- Test error propagation across modules
standards.clearErrorLog()

local error_prone_function = function(x)
    if x < 0 then
        error("Negative numbers not allowed")
    end
    return x * 2
end

local safe_error_function = standards.wrapFunction('TestModule', 'error_function', error_prone_function, -1)

assert_equal(safe_error_function(5), 10, "Safe function with valid input")
assert_equal(safe_error_function(-5), -1, "Safe function with invalid input returns default")

local errors = standards.getErrorLog()
assert_true(#errors > 0, "Error was logged when function failed")
assert_equal(errors[#errors].module, 'TestModule', "Error log contains correct module name")

-- Test validation integration across modules
print("\n--- Validation Integration ---")

local validation_result = standards.validateParameters('TestModule', 'test_function', {
    {name = 'array_param', value = {1, 2, 3}, rules = {type = 'table', required = true}},
    {name = 'number_param', value = 42, rules = {type = 'number', required = true}},
    {name = 'optional_param', value = nil, rules = {type = 'string', required = false}}
})

assert_true(validation_result.valid, "Parameter validation with valid inputs")

local invalid_validation = standards.validateParameters('TestModule', 'test_function', {
    {name = 'required_param', value = nil, rules = {type = 'string', required = true}}
})

assert_false(invalid_validation.valid, "Parameter validation catches missing required parameter")
assert_true(#invalid_validation.errors > 0, "Parameter validation provides error details")

-- ======================
-- ADVANCED FEATURES INTEGRATION TESTS
-- ======================

print("\n=== Advanced Features Integration Tests ===")

-- Test parallel execution framework
print("\n--- Parallel Execution Integration ---")

local executor = advanced.ParallelExecutor.new()

executor:addTask('task1', function() return Array.sum({1, 2, 3}) end)
executor:addTask('task2', function() return Array.map({1, 2, 3}, function(x) return x * 2 end) end)
executor:addTask('task3', function() 
    -- This task depends on task1 and task2 (simulated)
    return "combined_result" 
end, {'task1', 'task2'})

local exec_results = executor:execute()

assert_equal(exec_results.task1.status, 'completed', "Task 1 completed successfully")
assert_equal(exec_results.task1.result, 6, "Task 1 returned correct result")
assert_equal(exec_results.task2.status, 'completed', "Task 2 completed successfully")
assert_equal(exec_results.task3.status, 'completed', "Task 3 with dependencies completed")

-- Test reactive programming integration
print("\n--- Reactive Programming Integration ---")

local observed_values = {}
local observable = advanced.Observable.fromArray({1, 2, 3, 4, 5})

local mapped_observable = advanced.Observable.map(function(x) return x * 2 end)(observable)
local filtered_observable = advanced.Observable.filter(function(x) return x > 4 end)(mapped_observable)

filtered_observable.subscribe({
    next = function(value)
        table.insert(observed_values, value)
    end,
    error = function(err)
        print("Observable error: " .. err)
    end,
    complete = function()
        -- Observable completed
    end
})

assert_equal(#observed_values, 3, "Reactive pipeline processed correct number of values") -- 6, 8, 10
assert_equal(observed_values[1], 6, "Reactive pipeline first value correct")
assert_equal(observed_values[3], 10, "Reactive pipeline last value correct")

-- Test functional data structures integration
print("\n--- Functional Data Structures Integration ---")

local func_list = advanced.FunctionalList.fromArray({1, 2, 3, 4, 5})
local mapped_list = advanced.FunctionalList.map(function(x) return x * 2 end, func_list)
local filtered_list = advanced.FunctionalList.filter(function(x) return x > 4 end, mapped_list)
local result_array = advanced.FunctionalList.toArray(filtered_list)

assert_equal(#result_array, 3, "Functional list operations return correct length")
assert_equal(result_array[1], 6, "Functional list operations return correct values")

-- ======================
-- REAL-WORLD USAGE SCENARIO TESTS
-- ======================

print("\n=== Real-World Usage Scenario Tests ===")

-- Test MediaWiki column processing workflow
print("\n--- MediaWiki Column Processing Workflow ---")

local wiki_data = {
    {name = "Item1", level = 10, members = 100},
    {name = "Item2", level = 20, members = 200},
    {name = "Item3", level = 15, members = 150}
}

-- Create processing pipeline
local process_wiki_data = functools.compose(
    function(processed_data) 
        return funclib.build_table(
            {
                funclib.make_column("Name", {align = "left"}),
                funclib.make_column("Level", {align = "center"}),
                funclib.make_column("Members", {align = "right"})
            },
            processed_data
        )
    end,
    Array.sort(function(a, b) return a.level < b.level end),
    Array.filter(function(item) return item.level >= 10 end),
    Array.map(function(item) 
        return {
            name = funclib.format_name(item.name),
            level = tostring(item.level),
            members = tostring(item.members)
        }
    end)
)

local wiki_result = process_wiki_data(wiki_data)
assert_type(wiki_result, 'table', "Wiki data processing returns table result")

-- Test error-safe data transformation pipeline
print("\n--- Error-Safe Data Transformation Pipeline ---")

local transform_pipeline = funclib.create_pipeline({
    funclib.transforms.filter_empty,
    funclib.transforms.sort_by('value'),
    function(data)
        return Array.map(data, function(item)
            if not item.value then
                error("Missing value field")
            end
            return {processed_value = item.value * 2}
        end)
    end
})

local safe_data = {{value = 5}, {value = 3}, {value = 8}}
local pipeline_result = transform_pipeline(safe_data)
assert_equal(#pipeline_result, 3, "Safe pipeline processes all valid data")
assert_equal(pipeline_result[1].processed_value, 6, "Safe pipeline transforms data correctly") -- 3*2

-- Test unsafe data (with missing fields)
local unsafe_data = {{value = 5}, {}, {value = 8}}
local unsafe_result = transform_pipeline(unsafe_data)
assert_type(unsafe_result, 'string', "Pipeline returns error message for invalid data")

-- ======================
-- COMPREHENSIVE WORKFLOW TEST
-- ======================

print("\n=== Comprehensive Workflow Test ===")

-- This test combines all modules in a complex real-world scenario
local comprehensive_workflow = function(raw_data, config)
    -- Step 1: Validate input using CodeStandards
    local validation = standards.validateParameters('ComprehensiveWorkflow', 'process', {
        {name = 'raw_data', value = raw_data, rules = {type = 'table', required = true}},
        {name = 'config', value = config, rules = {type = 'table', required = true}}
    })
    
    if not validation.valid then
        return advanced.Either.left("Validation failed: " .. validation.errors[1].message)
    end
    
    -- Step 2: Process data using functional pipeline
    local processing_result = functools.safe_call(function()
        local filtered = Array.filter(raw_data, function(item) 
            return item and item.value and item.value > (config.min_value or 0)
        end)
        
        local enhanced = Array.map(filtered, function(item)
            return {
                original_value = item.value,
                processed_value = item.value * (config.multiplier or 1),
                category = item.value > 10 and "high" or "low"
            }
        end)
        
        local sorted = Array.sort(enhanced, function(a, b) 
            return a.processed_value < b.processed_value 
        end)
        
        return sorted
    end, 'ComprehensiveWorkflow', {})
    
    if not functools.Maybe.isJust(processing_result) then
        return advanced.Either.left("Processing failed")
    end
    
    -- Step 3: Create presentation using Funclib
    local presentation_result = functools.safe_call(function()
        local columns = {
            funclib.make_column("Original", {align = "right"}),
            funclib.make_column("Processed", {align = "right"}),
            funclib.make_column("Category", {align = "center"})
        }
        
        local rows = Array.map(processing_result.value, function(item)
            return {
                original = tostring(item.original_value),
                processed = tostring(item.processed_value),
                category = item.category
            }
        end)
        
        return funclib.build_table(columns, rows)
    end, 'ComprehensiveWorkflow', {})
    
    if not functools.Maybe.isJust(presentation_result) then
        return advanced.Either.left("Presentation failed")
    end
    
    return advanced.Either.right({
        processed_data = processing_result.value,
        presentation = presentation_result.value,
        metadata = {
            input_count = #raw_data,
            output_count = #processing_result.value,
            config = config
        }
    })
end

-- Test comprehensive workflow
local test_raw_data = {
    {value = 5}, {value = 15}, {value = 2}, {value = 25}, {value = 8}
}

local test_config = {
    min_value = 3,
    multiplier = 2
}

local workflow_result = comprehensive_workflow(test_raw_data, test_config)

assert_true(workflow_result.isRight, "Comprehensive workflow succeeded")
if workflow_result.isRight then
    local result = workflow_result.value
    assert_equal(result.metadata.input_count, 5, "Workflow tracked input count")
    assert_equal(result.metadata.output_count, 4, "Workflow filtered correctly") -- 2 is below min_value
    assert_type(result.presentation, 'table', "Workflow generated presentation")
end

-- ======================
-- TEST SUMMARY
-- ======================

print("\n=== Integration Test Summary ===")
print(string.format("Total tests: %d", passed + failed))
print(string.format("Passed: %d", passed))
print(string.format("Failed: %d", failed))
print(string.format("Success rate: %.1f%%", (passed / (passed + failed)) * 100))

-- Generate comprehensive report
local report = standards.generateReport()
print(string.format("\nPerformance metrics collected: %d", 
    Array.length(Array.keys(report.performance_summary))))
print(string.format("Errors logged during testing: %d", 
    report.error_summary[standards.ErrorLevel.ERROR] or 0))

if failed == 0 then
    print("\n🎉 ALL INTEGRATION TESTS PASSED!")
    print("✅ Cross-module integration verified")
    print("✅ Functional programming workflows operational")
    print("✅ Performance monitoring functional")
    print("✅ Error handling standardized")
    print("✅ Advanced features compatible")
    print("✅ Real-world scenarios validated")
else
    print(string.format("\n❌ %d INTEGRATION TESTS FAILED", failed))
    print("❗ Please review the failed test output above")
end

return {
    passed = passed,
    failed = failed,
    success_rate = (passed / (passed + failed)) * 100
}
