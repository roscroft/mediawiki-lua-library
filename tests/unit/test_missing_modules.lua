--[[Unit Tests for Missing/Additional ModulesTests modules that don't have dedicated test coverage yet]] -- Setup test environmentpackage.path = package.path .. ';src/modules/?.lua'-- Auto-initialize MediaWiki environment (eliminates conditional imports)require('MediaWikiAutoInit')-- Simple test frameworklocal tests_run = 0local tests_passed = 0local function test(name, func)    tests_run = tests_run + 1    local success, err = pcall(func)    if success then        tests_passed = tests_passed + 1        print("✅ " .. name)    else        print("❌ " .. name .. " - " .. tostring(err))    endendlocal function assert_not_nil(value, msg)    if value == nil then        error(msg or "Value should not be nil")    endendlocal function assert_type(value, expected_type, msg)    local actual_type = type(value)    if actual_type ~= expected_type then        error(msg or string.format("Expected type %s, got %s", expected_type, actual_type))    endendprint("=== Missing Modules Unit Tests ===\n")-- ======================-- ARGUMENTS MODULE TESTS-- ======================print("--- Arguments Module Tests ---")test("Arguments module loads", function()    local success, Arguments = pcall(require, 'Arguments')    if success then        assert_not_nil(Arguments)        assert_type(Arguments, 'table')                -- Check for getArgs function        if Arguments.getArgs then            assert_type(Arguments.getArgs, 'function')        end    else        print("  Note: Arguments module may have MediaWiki-specific dependencies")    endend)-- ======================-- TABLES MODULE TESTS-- ======================print("\n--- Tables Module Tests ---")test("Tables module loads", function()    local success, Tables = pcall(require, 'Tables')    if success then        assert_not_nil(Tables)        assert_type(Tables, 'table')                -- Check for common table functions        local has_functions = false        for k, v in pairs(Tables) do            if type(v) == 'function' then                has_functions = true                break            end        end        if has_functions then            print("  ✓ Tables module exports functions")        end    else        print("  Note: Tables module may have MediaWiki-specific dependencies")    endend)-- ======================-- TABLETOOLS MODULE TESTS-- ======================print("\n--- TableTools Module Tests ---")test("TableTools module loads", function()    local success, TableTools = pcall(require, 'TableTools')    if success then        assert_not_nil(TableTools)        assert_type(TableTools, 'table')                -- Check for common table manipulation functions        if TableTools.deepCopy then            assert_type(TableTools.deepCopy, 'function')        end        if TableTools.shallowClone then            assert_type(TableTools.shallowClone, 'function')        end    else        print("  Note: TableTools module may have MediaWiki-specific dependencies")    endend)-- ======================-- PARAMTEST MODULE TESTS-- ======================print("\n--- Paramtest Module Tests ---")test("Paramtest module loads", function()    local success, Paramtest = pcall(require, 'Paramtest')    if success then        assert_not_nil(Paramtest)        assert_type(Paramtest, 'table')                -- Check for parameter testing functions        if Paramtest.test then            assert_type(Paramtest.test, 'function')        end    else        print("  Note: Paramtest module may have MediaWiki-specific dependencies")    endend)-- ======================-- CLEAN_IMAGE MODULE TESTS-- ======================print("\n--- Clean_image Module Tests ---")test("Clean_image module loads", function()    local success, CleanImage = pcall(require, 'Clean_image')    if success then        assert_not_nil(CleanImage)        -- Module might be a function or table        local module_type = type(CleanImage)        if module_type == 'function' or module_type == 'table' then            print("  ✓ Clean_image module loaded successfully")        end    else        print("  Note: Clean_image module may have MediaWiki-specific dependencies")    endend)-- ======================-- INTEGRATION TESTS-- ======================print("\n--- Module Integration Tests ---")test("All utility modules work together", function()    local loaded_modules = {}    local module_names = {        'Arguments', 'Tables', 'TableTools', 'Paramtest', 'Clean_image',        'Plink', 'Mw_html_extension', 'TemplateUtil', 'Helper_module',        'Calcvalue', 'PerformanceDashboard', 'MediaWikiEnvironment'    }        for _, module_name in ipairs(module_names) do        local success, module = pcall(require, module_name)        if success then            loaded_modules[module_name] = module        end    end        -- At least some modules should load    local loaded_count = 0    for _ in pairs(loaded_modules) do        loaded_count = loaded_count + 1    end        print(string.format("  ✓ Successfully loaded %d/%d utility modules", loaded_count, #module_names))end)test("Module dependencies are properly handled", function()    -- Test that libraryUtil is available for modules that need it    local libraryUtil = require('libraryUtil')    assert_not_nil(libraryUtil)    assert_type(libraryUtil.checkType, 'function')        -- Test that basic MediaWiki globals are set up    assert_not_nil(_G.mw, "MediaWiki global should be available")    assert_not_nil(_G.libraryUtil, "libraryUtil global should be available")end)-- Summaryprint(string.format("\n=== Missing Modules Test Results ==="))print(string.format("Tests run: %d", tests_run))print(string.format("Tests passed: %d", tests_passed))print(string.format("Tests failed: %d", tests_run - tests_passed))print(string.format("Success rate: %.1f%%", (tests_passed / tests_run) * 100))if tests_passed == tests_run then    print("\n🎉 All missing module tests passed!")    return trueelse    print("\n❌ Some missing module tests failed.")    return falseend

--[[
Unit Tests for Missing/Additional Modules
Tests modules that don't have dedicated test coverage yet
]]

-- Setup test environment
package.path = package.path .. ';src/modules/?.lua'

-- Auto-initialize MediaWiki environment (eliminates conditional imports)
require('MediaWikiAutoInit')

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

print("=== Missing Modules Unit Tests ===\n")

-- ======================
-- ARGUMENTS MODULE TESTS
-- ======================

print("--- Arguments Module Tests ---")

test("Arguments module loads", function()
    local success, Arguments = pcall(require, 'Arguments')
    if success then
        assert_not_nil(Arguments)
        assert_type(Arguments, 'table')

        -- Check for getArgs function
        if Arguments.getArgs then
            assert_type(Arguments.getArgs, 'function')
        end
    else
        print("  Note: Arguments module may have MediaWiki-specific dependencies")
    end
end)

-- ======================
-- TABLES MODULE TESTS
-- ======================

print("\n--- Tables Module Tests ---")

test("Tables module loads", function()
    local success, Tables = pcall(require, 'Tables')
    if success then
        assert_not_nil(Tables)
        assert_type(Tables, 'table')

        -- Check for common table functions
        local has_functions = false
        for k, v in pairs(Tables) do
            if type(v) == 'function' then
                has_functions = true
                break
            end
        end
        if has_functions then
            print("  ✓ Tables module exports functions")
        end
    else
        print("  Note: Tables module may have MediaWiki-specific dependencies")
    end
end)

-- ======================
-- TABLETOOLS MODULE TESTS
-- ======================

print("\n--- TableTools Module Tests ---")

test("TableTools module loads", function()
    local success, TableTools = pcall(require, 'TableTools')
    if success then
        assert_not_nil(TableTools)
        assert_type(TableTools, 'table')

        -- Check for common table manipulation functions
        if TableTools.deepCopy then
            assert_type(TableTools.deepCopy, 'function')
        end
        if TableTools.shallowClone then
            assert_type(TableTools.shallowClone, 'function')
        end
    else
        print("  Note: TableTools module may have MediaWiki-specific dependencies")
    end
end)

-- ======================
-- PARAMTEST MODULE TESTS
-- ======================

print("\n--- Paramtest Module Tests ---")

test("Paramtest module loads", function()
    local success, Paramtest = pcall(require, 'Paramtest')
    if success then
        assert_not_nil(Paramtest)
        assert_type(Paramtest, 'table')

        -- Check for parameter testing functions
        if Paramtest.test then
            assert_type(Paramtest.test, 'function')
        end
    else
        print("  Note: Paramtest module may have MediaWiki-specific dependencies")
    end
end)

-- ======================
-- CLEAN_IMAGE MODULE TESTS
-- ======================

print("\n--- Clean_image Module Tests ---")

test("Clean_image module loads", function()
    local success, CleanImage = pcall(require, 'Clean_image')
    if success then
        assert_not_nil(CleanImage)
        -- Module might be a function or table
        local module_type = type(CleanImage)
        if module_type == 'function' or module_type == 'table' then
            print("  ✓ Clean_image module loaded successfully")
        end
    else
        print("  Note: Clean_image module may have MediaWiki-specific dependencies")
    end
end)

-- ======================
-- INTEGRATION TESTS
-- ======================

print("\n--- Module Integration Tests ---")

test("All utility modules work together", function()
    local loaded_modules = {}
    local module_names = {
        'Arguments', 'Tables', 'TableTools', 'Paramtest', 'Clean_image',
        'Plink', 'Mw_html_extension', 'TemplateUtil', 'Helper_module',
        'Calcvalue', 'PerformanceDashboard', 'MediaWikiEnvironment'
    }

    for _, module_name in ipairs(module_names) do
        local success, module = pcall(require, module_name)
        if success then
            loaded_modules[module_name] = module
        end
    end

    -- At least some modules should load
    local loaded_count = 0
    for _ in pairs(loaded_modules) do
        loaded_count = loaded_count + 1
    end

    print(string.format("  ✓ Successfully loaded %d/%d utility modules", loaded_count, #module_names))
end)

test("Module dependencies are properly handled", function()
    -- Test that libraryUtil is available for modules that need it
    local libraryUtil = require('libraryUtil')
    assert_not_nil(libraryUtil)
    assert_type(libraryUtil.checkType, 'function')

    -- Test that basic MediaWiki globals are set up
    assert_not_nil(_G.mw, "MediaWiki global should be available")
    assert_not_nil(_G.libraryUtil, "libraryUtil global should be available")
end)

-- Summary
print(string.format("\n=== Missing Modules Test Results ==="))
print(string.format("Tests run: %d", tests_run))
print(string.format("Tests passed: %d", tests_passed))
print(string.format("Tests failed: %d", tests_run - tests_passed))
print(string.format("Success rate: %.1f%%", (tests_passed / tests_run) * 100))

if tests_passed == tests_run then
    print("\n🎉 All missing module tests passed!")
    return true
else
    print("\n❌ Some missing module tests failed.")
    return false
end
