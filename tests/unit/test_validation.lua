#!/usr/bin/env lua
--[[
Unit Tests for Data Validation Functions
Tests validation utilities across various modules
]]

-- Setup test environment
package.path = package.path .. ';src/modules/?.lua'
local env = dofile('tests/env/wiki-lua-env.lua')
_G.mw = env.mw
_G.libraryUtil = env.libraryUtil

local CodeStandards = require('CodeStandards')

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

local function assert_true(value, msg)
    if not value then
        error(msg or "Expected true value")
    end
end

local function assert_false(value, msg)
    if value then
        error(msg or "Expected false value")
    end
end

print("=== Data Validation Unit Tests ===\n")

-- Test isEmpty function
test("isEmpty detects nil values", function()
    assert_true(CodeStandards.isEmpty(nil))
end)

test("isEmpty detects empty strings", function()
    assert_true(CodeStandards.isEmpty(""))
    assert_true(CodeStandards.isEmpty("   "))
    assert_true(CodeStandards.isEmpty("\t\n"))
end)

test("isEmpty detects empty tables", function()
    assert_true(CodeStandards.isEmpty({}))
end)

test("isEmpty rejects non-empty values", function()
    assert_false(CodeStandards.isEmpty("hello"))
    assert_false(CodeStandards.isEmpty({1}))
    assert_false(CodeStandards.isEmpty(0))
    assert_false(CodeStandards.isEmpty(false))
end)

-- Test isValid function
test("isValid accepts valid required values", function()
    local valid, msg = CodeStandards.isValid("hello", {required = true})
    assert_true(valid)
    assert_equal(msg, nil)
end)

test("isValid rejects empty required values", function()
    local valid, msg = CodeStandards.isValid("", {required = true})
    assert_false(valid)
    assert_not_nil(msg)
end)

test("isValid accepts empty optional values", function()
    local valid, msg = CodeStandards.isValid("", {required = false})
    assert_true(valid)
    assert_equal(msg, nil)
end)

test("isValid validates types correctly", function()
    local valid, msg = CodeStandards.isValid("hello", {type = 'string'})
    assert_true(valid)
    
    local invalid, msg2 = CodeStandards.isValid(123, {type = 'string'})
    assert_false(invalid)
    assert_not_nil(msg2)
end)

test("isValid validates string patterns", function()
    local valid, msg = CodeStandards.isValid("123", {pattern = "^%d+$"})
    assert_true(valid)
    
    local invalid, msg2 = CodeStandards.isValid("abc", {pattern = "^%d+$"})
    assert_false(invalid)
    assert_not_nil(msg2)
end)

test("isValid validates number ranges", function()
    local valid, msg = CodeStandards.isValid(5, {min = 1, max = 10})
    assert_true(valid)
    
    local invalid_low, msg2 = CodeStandards.isValid(0, {min = 1, max = 10})
    assert_false(invalid_low)
    assert_not_nil(msg2)
    
    local invalid_high, msg3 = CodeStandards.isValid(15, {min = 1, max = 10})
    assert_false(invalid_high)
    assert_not_nil(msg3)
end)

test("isValid validates string lengths", function()
    local valid, msg = CodeStandards.isValid("hello", {minLength = 3, maxLength = 10})
    assert_true(valid)
    
    local invalid_short, msg2 = CodeStandards.isValid("hi", {minLength = 3})
    assert_false(invalid_short)
    assert_not_nil(msg2)
    
    local invalid_long, msg3 = CodeStandards.isValid("very long string", {maxLength = 5})
    assert_false(invalid_long)
    assert_not_nil(msg3)
end)

test("isValid validates table lengths", function()
    local valid, msg = CodeStandards.isValid({1, 2, 3}, {minLength = 2, maxLength = 5})
    assert_true(valid)
    
    local invalid_short, msg2 = CodeStandards.isValid({1}, {minLength = 2})
    assert_false(invalid_short)
    assert_not_nil(msg2)
end)

test("isValid uses custom validation functions", function()
    local even_validator = function(x) return x % 2 == 0 end
    
    local valid, msg = CodeStandards.isValid(4, {validate = even_validator})
    assert_true(valid)
    
    local invalid, msg2 = CodeStandards.isValid(5, {validate = even_validator})
    assert_false(invalid)
    assert_not_nil(msg2)
end)

-- Test parameter validation
test("validateParameters handles complex scenarios", function()
    local params = {
        {name = 'name', type = 'string', required = true, validate = function(x) return #x > 2 end},
        {name = 'age', type = 'number', required = true, min = 0, max = 150},
        {name = 'email', type = 'string', required = false, pattern = ".+@.+%..+"}
    }
    
    -- Valid case
    local valid, msg = CodeStandards.validateParameters('testFunc', params, {"John", 25, "john@example.com"})
    assert_true(valid)
    assert_equal(msg, nil)
    
    -- Invalid name (too short)
    local invalid1, msg1 = CodeStandards.validateParameters('testFunc', params, {"Jo", 25, "john@example.com"})
    assert_false(invalid1)
    assert_not_nil(msg1)
    
    -- Invalid age (too high)
    local invalid2, msg2 = CodeStandards.validateParameters('testFunc', params, {"John", 200, "john@example.com"})
    assert_false(invalid2)
    assert_not_nil(msg2)
    
    -- Invalid email pattern
    local invalid3, msg3 = CodeStandards.validateParameters('testFunc', params, {"John", 25, "invalid-email"})
    assert_false(invalid3)
    assert_not_nil(msg3)
end)

test("validateParameters handles optional parameters correctly", function()
    local params = {
        {name = 'required_param', type = 'string', required = true},
        {name = 'optional_param', type = 'number', required = false}
    }
    
    -- With optional parameter
    local valid1, msg1 = CodeStandards.validateParameters('testFunc', params, {"hello", 42})
    assert_true(valid1)
    
    -- Without optional parameter
    local valid2, msg2 = CodeStandards.validateParameters('testFunc', params, {"hello"})
    assert_true(valid2)
    
    -- With nil optional parameter
    local valid3, msg3 = CodeStandards.validateParameters('testFunc', params, {"hello", nil})
    assert_true(valid3)
end)

-- Test edge cases
test("Validation handles edge cases", function()
    -- Test with empty table
    local valid1, msg1 = CodeStandards.isValid({}, {required = false})
    assert_true(valid1)
    
    -- Test with zero
    local valid2, msg2 = CodeStandards.isValid(0, {type = 'number', min = 0})
    assert_true(valid2)
    
    -- Test with false boolean
    local valid3, msg3 = CodeStandards.isValid(false, {type = 'boolean'})
    assert_true(valid3)
    
    -- Test with empty string but no required flag
    local valid4, msg4 = CodeStandards.isValid("", {type = 'string'})
    assert_true(valid4)
end)

-- Test libraryUtil integration
test("libraryUtil validation functions work", function()
    -- Use global libraryUtil instead of requiring it
    
    -- Test checkType
    local success1 = pcall(libraryUtil.checkType, 'test', 1, 'string', 'number')
    assert_false(success1) -- Should throw error for wrong type
    
    local success2 = pcall(libraryUtil.checkType, 'test', 1, 'hello', 'string')
    assert_true(success2) -- Should pass for correct type
end)

-- Test validation performance
test("Validation performs efficiently", function()
    local start_time = os.clock()
    
    -- Run many validation operations
    for i = 1, 1000 do
        CodeStandards.isEmpty("")
        CodeStandards.isEmpty("value")
        CodeStandards.isValid("test", {type = 'string', required = true})
        CodeStandards.isValid(i, {type = 'number', min = 0, max = 2000})
    end
    
    local end_time = os.clock()
    local duration = end_time - start_time
    
    -- Should complete quickly (less than 0.1 seconds for 4000 operations)
    if duration > 0.1 then
        error(string.format("Validation operations took too long: %.3f seconds", duration))
    end
end)

-- Summary
print(string.format("\n=== Test Results ==="))
print(string.format("Tests run: %d", tests_run))
print(string.format("Tests passed: %d", tests_passed))
print(string.format("Tests failed: %d", tests_run - tests_passed))
print(string.format("Success rate: %.1f%%", (tests_passed / tests_run) * 100))

if tests_passed == tests_run then
    print("\n🎉 All validation tests passed!")
    os.exit(0)
else
    print("\n❌ Some validation tests failed.")
    os.exit(1)
end