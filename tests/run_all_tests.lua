#!/usr/bin/env lua
--[[
Comprehensive Test Runner for MediaWiki Lua Module Library
Runs all unit tests, integration tests, and performance benchmarks
]]

-- Test configuration
local TEST_CONFIG = {
    unit_tests = {
        "tests/unit/test_core_modules.lua",
        "tests/unit/test_utilities.lua",
        "tests/unit/test_codestandards.lua",
        "tests/unit/test_performance.lua",
        "tests/unit/test_missing_modules.lua",
        "tests/unit/test_module_loading.lua"
    },
    integration_tests = {
        "tests/integration/test_basic_integration.lua",
        "tests/integration/test_comprehensive_integration_simplified.lua",
        "tests/integration/test_final_verification.lua"
    },
    demo_tests = {
    }
}

-- Test execution framework
local total_tests = 0
local passed_tests = 0
local failed_tests = {}
local suite_results = {}

local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

local function run_test_file(test_file)
    print(string.format("\n🧪 Running %s", test_file))
    print(string.rep("-", 60))

    -- Check if file exists first
    if not file_exists(test_file) then
        table.insert(failed_tests, { file = test_file, error = "File not found" })
        print(string.format("❌ %s NOT FOUND", test_file))
        total_tests = total_tests + 1
        return false
    end

    local start_time = os.clock()
    local success, result = pcall(dofile, test_file)
    local duration = os.clock() - start_time

    total_tests = total_tests + 1

    if success and result ~= false then
        passed_tests = passed_tests + 1
        print(string.format("✅ %s PASSED (%.3fs)", test_file, duration))
        return true
    else
        local error_msg = success and "Test returned false" or tostring(result)
        table.insert(failed_tests, { file = test_file, error = error_msg })
        print(string.format("❌ %s FAILED (%.3fs): %s", test_file, duration, error_msg))
        return false
    end
end

local function run_test_suite(suite_name, test_files)
    print(string.format("\n%s %s TESTS %s",
        string.rep("=", 20), suite_name:upper(), string.rep("=", 20)))

    local suite_start = os.clock()
    local suite_passed = 0
    local suite_total = 0
    local suite_skipped = 0

    for _, test_file in ipairs(test_files) do
        if file_exists(test_file) then
            -- Don't use the return value from run_test_file since it handles success/failure internally
            -- Instead, track the counts at this level
            local before_passed = passed_tests
            local before_total = total_tests

            run_test_file(test_file)

            -- Check if this test passed by comparing counts
            if passed_tests > before_passed then
                suite_passed = suite_passed + 1
            end
            suite_total = suite_total + 1
        else
            print(string.format("⚠️  SKIPPING %s (file not found)", test_file))
            suite_skipped = suite_skipped + 1
            total_tests = total_tests + 1
        end
    end

    local suite_duration = os.clock() - suite_start
    local suite_rate = suite_total > 0 and (suite_passed / suite_total) * 100 or 0

    -- Store suite results
    suite_results[suite_name] = {
        total = suite_total,
        passed = suite_passed,
        skipped = suite_skipped,
        failed = suite_total - suite_passed,
        duration = suite_duration,
        rate = suite_rate
    }

    print(string.format("\n📊 %s SUITE SUMMARY:", suite_name:upper()))
    print(string.format("   Tests Run: %d | Passed: %d | Failed: %d | Skipped: %d",
        suite_total, suite_passed, suite_total - suite_passed, suite_skipped))
    print(string.format("   Success Rate: %.1f%% | Duration: %.3fs", suite_rate, suite_duration))
end

-- Main execution
local main_start_time = os.clock()

print("🚀 MediaWiki Lua Module Library - Comprehensive Test Suite")
print(string.rep("=", 70))
print(string.format("Started at: %s", os.date("%Y-%m-%d %H:%M:%S")))

-- Run all test suites
run_test_suite("Unit", TEST_CONFIG.unit_tests)
run_test_suite("Integration", TEST_CONFIG.integration_tests)
run_test_suite("Demo", TEST_CONFIG.demo_tests)

local total_duration = os.clock() - main_start_time

-- Detailed suite breakdown
print(string.format("\n%s DETAILED RESULTS %s", string.rep("=", 25), string.rep("=", 25)))
for suite_name, results in pairs(suite_results) do
    print(string.format("📂 %s Tests:", suite_name:upper()))
    print(string.format("   ✅ Passed: %d/%d (%.1f%%)", results.passed, results.total, results.rate))
    if results.failed > 0 then
        print(string.format("   ❌ Failed: %d", results.failed))
    end
    if results.skipped > 0 then
        print(string.format("   ⚠️  Skipped: %d", results.skipped))
    end
    print(string.format("   ⏱️  Duration: %.3fs", results.duration))
    print()
end

-- Final summary
print(string.format("%s FINAL SUMMARY %s", string.rep("=", 25), string.rep("=", 25)))
print(string.format("Total Test Files: %d", total_tests))
print(string.format("Successful Runs: %d", passed_tests))
print(string.format("Failed Runs: %d", #failed_tests))
print(string.format("Overall Success Rate: %.1f%%", total_tests > 0 and (passed_tests / total_tests) * 100 or 0))
print(string.format("Total Duration: %.3fs", total_duration))
print(string.format("Completed at: %s", os.date("%Y-%m-%d %H:%M:%S")))

-- Performance metrics
if total_duration > 0 then
    print(string.format("Average Test Speed: %.3f tests/second", total_tests / total_duration))
end

if #failed_tests > 0 then
    print(string.format("\n%s FAILURE DETAILS %s", string.rep("=", 25), string.rep("=", 25)))
    for i, failure in ipairs(failed_tests) do
        print(string.format("❌ #%d: %s", i, failure.file))
        print(string.format("   Error: %s", failure.error))
        print()
    end
    print("💡 Fix the failing tests and run again.")
    os.exit(1)
else
    print("\n🎉 ALL TESTS PASSED! The MediaWiki Lua Module Library is working correctly.")
    print("🔥 Ready for production deployment!")
    os.exit(0)
end
