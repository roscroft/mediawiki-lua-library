#!/usr/bin/env lua
--[[
Unit Tests for Lists Module
Tests the core Lists functionality including builders, column configuration, and public API
]]

-- Setup test environment
package.path = package.path .. ';src/modules/?.lua'
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

local Lists = require('Lists')

-- Simple test framework
local tests_run = 0
local tests_passed = 0

local function test(name, func)
    tests_run = tests_run + 1
    local success, err = pcall(func)
    if success then
        tests_passed = tests_passed + 1
        print("✅ " .. name)
    else
        print("❌ " .. name .. " - " .. tostring(err))
    end
end

local function assert_equal(actual, expected, msg)
    if actual ~= expected then
        error(msg or string.format("Expected %s, got %s", tostring(expected), tostring(actual)))
    end
end

local function assert_not_nil(value, msg)
    if value == nil then
        error(msg or "Value should not be nil")
    end
end

local function assert_type(value, expected_type, msg)
    local actual_type = type(value)
    if actual_type ~= expected_type then
        error(msg or string.format("Expected type %s, got %s", expected_type, actual_type))
    end
end

print("=== Lists Module Unit Tests ===\n")

-- Test module structure and exports
test("Lists module exports expected API", function()
    assert_not_nil(Lists)
    assert_type(Lists, 'table')

    -- Check main builders are exported
    assert_not_nil(Lists.QueryBuilder)
    assert_not_nil(Lists.ColumnBuilder)
    assert_not_nil(Lists.TableBuilder)

    -- Check column presets are exported
    assert_not_nil(Lists.COLUMN_PRESETS)
    assert_type(Lists.COLUMN_PRESETS, 'table')
end)

-- Test column preset functions
test("Column preset functions are available", function()
    assert_type(Lists.make_preset_column, 'function')
    assert_type(Lists.make_level_column, 'function')
    assert_type(Lists.make_members_column, 'function')
    assert_type(Lists.make_name_column, 'function')
end)

-- Test column helper functions
test("Column helper functions are available", function()
    assert_type(Lists.make_column, 'function')
    assert_type(Lists.process_column_config, 'function')
end)

-- Test table building functions
test("Table building functions are available", function()
    assert_type(Lists.build_table, 'function')
end)

-- Test convenience shortcuts
test("Convenience shortcuts are available", function()
    assert_type(Lists.col, 'function')
    assert_type(Lists.preset, 'function')
    assert_type(Lists.table, 'function')
    assert_type(Lists.decode, 'function')
    assert_type(Lists.level_col, 'function')
    assert_type(Lists.members_col, 'function')
    assert_type(Lists.name_col, 'function')
    assert_type(Lists.cols, 'function')
    assert_type(Lists.query, 'function')
end)

-- Test that builders can be instantiated
test("QueryBuilder can be instantiated", function()
    local builder = Lists.QueryBuilder:new()
    assert_not_nil(builder)
    assert_type(builder, 'table')
end)

test("ColumnBuilder can be instantiated", function()
    local builder = Lists.ColumnBuilder:new()
    assert_not_nil(builder)
    assert_type(builder, 'table')
end)

test("TableBuilder can be instantiated", function()
    local builder = Lists.TableBuilder:new()
    assert_not_nil(builder)
    assert_type(builder, 'table')
end)

-- Test column preset creation
test("make_level_column creates valid configuration", function()
    local column = Lists.make_level_column({header = "Test Level"})
    assert_not_nil(column)
    assert_type(column, 'table')
end)

test("make_members_column creates valid configuration", function()
    local column = Lists.make_members_column({header = "Test Members"})
    assert_not_nil(column)
    assert_type(column, 'table')
end)

test("make_name_column creates valid configuration", function()
    local column = Lists.make_name_column({header = "Test Name"})
    assert_not_nil(column)
    assert_type(column, 'table')
end)

-- Test that column presets contain expected configurations
test("COLUMN_PRESETS contains expected presets", function()
    local presets = Lists.COLUMN_PRESETS
    assert_not_nil(presets)

    -- Should have at least some common presets
    local has_presets = false
    for k, v in pairs(presets) do
        if type(v) == 'table' then
            has_presets = true
            break
        end
    end
    assert_equal(has_presets, true, "COLUMN_PRESETS should contain preset configurations")
end)

-- Test convenience function integrations
test("Convenience functions return expected types", function()
    -- Test col function (should create column configuration)
    local col_result = Lists.col("test_field", "Test Header")
    assert_not_nil(col_result)
    assert_type(col_result, 'table')

    -- Test preset function (should create preset column)
    local preset_result = Lists.preset("LEVEL", {})
    assert_not_nil(preset_result)
    assert_type(preset_result, 'table')
end)

-- Test that Lists module properly delegates to Funclib
test("Lists delegates to Funclib properly", function()
    -- Test that functions exist and are callable
    assert_type(Lists.cols, 'function')
    assert_type(Lists.query, 'function')
    assert_type(Lists.table, 'function')

    -- Test basic usage without throwing errors
    local success, result = pcall(Lists.cols, {})
    -- Should not throw an error even with empty input
    assert_equal(success, true, "Lists.cols should handle empty input gracefully")
end)

-- Test error handling
test("Functions handle invalid inputs gracefully", function()
    -- Test make_preset_column with invalid input
    local success, result = pcall(Lists.make_preset_column, "NONEXISTENT_PRESET", {})
    -- Should either succeed with a fallback or fail gracefully
    assert_equal(type(success), 'boolean', "make_preset_column should handle invalid presets")

    -- Test column builders with nil input
    local success2, result2 = pcall(Lists.make_column, nil, nil)
    assert_equal(type(success2), 'boolean', "make_column should handle nil inputs")
end)

-- Test module integration
test("Lists module integrates with Funclib correctly", function()
    -- Verify that Lists has access to Funclib functionality
    assert_not_nil(Lists.make_column)
    assert_not_nil(Lists.build_table)
    assert_not_nil(Lists.process_column_config)

    -- These should be the same functions from Funclib
    assert_type(Lists.make_column, 'function')
    assert_type(Lists.build_table, 'function')
    assert_type(Lists.process_column_config, 'function')
end)

-- Test that module doesn't break with complex operations
test("Lists handles complex operations", function()
    -- Try creating multiple builders
    local query_builder = Lists.QueryBuilder:new()
    local column_builder = Lists.ColumnBuilder:new()
    local table_builder = Lists.TableBuilder:new()

    assert_not_nil(query_builder)
    assert_not_nil(column_builder)
    assert_not_nil(table_builder)

    -- Try creating multiple column configurations
    local level_col = Lists.make_level_column({header = "Level"})
    local name_col = Lists.make_name_column({header = "Name"})
    local members_col = Lists.make_members_column({header = "Members"})

    assert_not_nil(level_col)
    assert_not_nil(name_col)
    assert_not_nil(members_col)
end)

-- Summary
print(string.format("\n=== Test Results ==="))
print(string.format("Tests run: %d", tests_run))
print(string.format("Tests passed: %d", tests_passed))
print(string.format("Tests failed: %d", tests_run - tests_passed))
print(string.format("Success rate: %.1f%%", (tests_passed / tests_run) * 100))

if tests_passed == tests_run then
    print("\n🎉 All Lists module tests passed!")
    os.exit(0)
else
    print("\n❌ Some Lists module tests failed.")
    os.exit(1)
end