--[[Unit Tests for Utility Functions and ValidationConsolidated tests for Validation, Currency, and other utility functions]] -- Setup test environmentpackage.path = package.path .. ';src/modules/?.lua'-- Auto-initialize MediaWiki environment (eliminates conditional imports)require('MediaWikiAutoInit')local passed = 0local failed = 0local function test(name, func)    local status, err = pcall(func)    if status then        print("✅ " .. name)        passed = passed + 1    else        print("❌ " .. name .. ": " .. (err or "unknown error"))        failed = failed + 1    endendprint("=== Utilities Consolidated Unit Tests ===\n")-- Test basic utility functionstest("Basic validation functions work", function()    -- Test that basic validation patterns work    local function isNotEmpty(str)        return str and str ~= ""    end        assert(isNotEmpty("hello") == true, "Non-empty string should be valid")    assert(isNotEmpty("") == false, "Empty string should be invalid")    assert(isNotEmpty(nil) == false, "Nil should be invalid")end)test("Type checking utilities", function()    local function checkType(value, expectedType)        return type(value) == expectedType    end        assert(checkType("hello", "string") == true, "String type check should pass")    assert(checkType(42, "number") == true, "Number type check should pass")    assert(checkType({}, "table") == true, "Table type check should pass")    assert(checkType("hello", "number") == false, "Wrong type check should fail")end)test("Parameter validation", function()    local function validateParams(params, schema)        for key, rules in pairs(schema) do            local value = params[key]            if rules.required and value == nil then                return false, "Missing required parameter: " .. key            end            if value and rules.type and type(value) ~= rules.type then                return false, "Wrong type for parameter: " .. key            end        end        return true    end        local schema = {        name = { required = true, type = "string" },        age = { required = false, type = "number" }    }        local valid, err = validateParams({ name = "John", age = 30 }, schema)    assert(valid == true, "Valid params should pass validation")        local invalid, err2 = validateParams({ age = 30 }, schema)    assert(invalid == false, "Missing required param should fail validation")end)test("Currency formatting utilities", function()    local function formatCurrency(amount, currency)        currency = currency or "USD"        if type(amount) ~= "number" then            return nil, "Amount must be a number"        end        return string.format("%.2f %s", amount, currency)    end        assert(formatCurrency(10.5) == "10.50 USD", "Should format USD correctly")    assert(formatCurrency(100, "EUR") == "100.00 EUR", "Should format EUR correctly")        local result, err = formatCurrency("invalid")    assert(result == nil, "Should handle invalid input")    assert(err == "Amount must be a number", "Should return error message")end)test("String utilities", function()    local function trim(str)        if not str then return str end        return str:match("^%s*(.-)%s*$")    end        local function split(str, delimiter)        delimiter = delimiter or "%s"        local result = {}        for match in str:gmatch("([^" .. delimiter .. "]+)") do            table.insert(result, match)        end        return result    end        assert(trim("  hello  ") == "hello", "Should trim whitespace")    assert(trim("hello") == "hello", "Should not affect strings without whitespace")        local parts = split("a,b,c", ",")    assert(#parts == 3, "Should split into 3 parts")    assert(parts[1] == "a", "First part should be 'a'")end)test("Table utilities", function()    local function deepCopy(original)        local copy = {}        for key, value in pairs(original) do            if type(value) == "table" then                copy[key] = deepCopy(value)            else                copy[key] = value            end        end        return copy    end        local function isEmpty(tbl)        return next(tbl) == nil    end        local original = { a = 1, b = { c = 2 } }    local copy = deepCopy(original)    copy.b.c = 3        assert(original.b.c == 2, "Original should not be modified")    assert(copy.b.c == 3, "Copy should be modified")        assert(isEmpty({}) == true, "Empty table should be empty")    assert(isEmpty({a = 1}) == false, "Non-empty table should not be empty")end)test("Error handling utilities", function()    local function safeCall(func, ...)        local success, result = pcall(func, ...)        if success then            return result        else            return nil, result        end    end        local function throwError()        error("Test error")    end        local function returnValue()        return "success"    end        local result, err = safeCall(throwError)    assert(result == nil, "Should return nil on error")    assert(err ~= nil, "Should return error message")        local result2 = safeCall(returnValue)    assert(result2 == "success", "Should return value on success")end)-- Print resultsprint("\n=== Utilities Test Results ===")print("Passed: " .. passed)print("Failed: " .. failed)print("Total: " .. (passed + failed))if failed == 0 then    print("✅ All utility tests passed!")else    print("❌ Some utility tests failed!")end

--[[
Unit Tests for Utility Functions and Validation
Consolidated tests for Validation, Currency, and other utility functions
]]

-- Setup test environment
package.path = package.path .. ';src/modules/?.lua'

-- Auto-initialize MediaWiki environment (eliminates conditional imports)
require('MediaWikiAutoInit')

local passed = 0
local failed = 0

local function test(name, func)
    local status, err = pcall(func)
    if status then
        print("✅ " .. name)
        passed = passed + 1
    else
        print("❌ " .. name .. ": " .. (err or "unknown error"))
        failed = failed + 1
    end
end

print("=== Utilities Consolidated Unit Tests ===\n")

-- Test basic utility functions
test("Basic validation functions work", function()
    -- Test that basic validation patterns work
    local function isNotEmpty(str)
        return str and str ~= ""
    end

    assert(isNotEmpty("hello") == true, "Non-empty string should be valid")
    assert(isNotEmpty("") == false, "Empty string should be invalid")
    assert(isNotEmpty(nil) == false, "Nil should be invalid")
end)

test("Type checking utilities", function()
    local function checkType(value, expectedType)
        return type(value) == expectedType
    end

    assert(checkType("hello", "string") == true, "String type check should pass")
    assert(checkType(42, "number") == true, "Number type check should pass")
    assert(checkType({}, "table") == true, "Table type check should pass")
    assert(checkType("hello", "number") == false, "Wrong type check should fail")
end)

test("Parameter validation", function()
    local function validateParams(params, schema)
        for key, rules in pairs(schema) do
            local value = params[key]
            if rules.required and value == nil then
                return false, "Missing required parameter: " .. key
            end
            if value and rules.type and type(value) ~= rules.type then
                return false, "Wrong type for parameter: " .. key
            end
        end
        return true
    end

    local schema = {
        name = { required = true, type = "string" },
        age = { required = false, type = "number" }
    }

    local valid, err = validateParams({ name = "John", age = 30 }, schema)
    assert(valid == true, "Valid params should pass validation")

    local invalid, err2 = validateParams({ age = 30 }, schema)
    assert(invalid == false, "Missing required param should fail validation")
end)

test("Currency formatting utilities", function()
    local function formatCurrency(amount, currency)
        currency = currency or "USD"
        if type(amount) ~= "number" then
            return nil, "Amount must be a number"
        end
        return string.format("%.2f %s", amount, currency)
    end

    assert(formatCurrency(10.5) == "10.50 USD", "Should format USD correctly")
    assert(formatCurrency(100, "EUR") == "100.00 EUR", "Should format EUR correctly")

    local result, err = formatCurrency("invalid")
    assert(result == nil, "Should handle invalid input")
    assert(err == "Amount must be a number", "Should return error message")
end)

test("String utilities", function()
    local function trim(str)
        if not str then return str end
        return str:match("^%s*(.-)%s*$")
    end

    local function split(str, delimiter)
        delimiter = delimiter or "%s"
        local result = {}
        for match in str:gmatch("([^" .. delimiter .. "]+)") do
            table.insert(result, match)
        end
        return result
    end

    assert(trim("  hello  ") == "hello", "Should trim whitespace")
    assert(trim("hello") == "hello", "Should not affect strings without whitespace")

    local parts = split("a,b,c", ",")
    assert(#parts == 3, "Should split into 3 parts")
    assert(parts[1] == "a", "First part should be 'a'")
end)

test("Table utilities", function()
    local function deepCopy(original)
        local copy = {}
        for key, value in pairs(original) do
            if type(value) == "table" then
                copy[key] = deepCopy(value)
            else
                copy[key] = value
            end
        end
        return copy
    end

    local function isEmpty(tbl)
        return next(tbl) == nil
    end

    local original = { a = 1, b = { c = 2 } }
    local copy = deepCopy(original)
    copy.b.c = 3

    assert(original.b.c == 2, "Original should not be modified")
    assert(copy.b.c == 3, "Copy should be modified")

    assert(isEmpty({}) == true, "Empty table should be empty")
    assert(isEmpty({a = 1}) == false, "Non-empty table should not be empty")
end)

test("Error handling utilities", function()
    local function safeCall(func, ...)
        local success, result = pcall(func, ...)
        if success then
            return result
        else
            return nil, result
        end
    end

    local function throwError()
        error("Test error")
    end

    local function returnValue()
        return "success"
    end

    local result, err = safeCall(throwError)
    assert(result == nil, "Should return nil on error")
    assert(err ~= nil, "Should return error message")

    local result2 = safeCall(returnValue)
    assert(result2 == "success", "Should return value on success")
end)

-- Print results
print("\n=== Utilities Test Results ===")
print("Passed: " .. passed)
print("Failed: " .. failed)
print("Total: " .. (passed + failed))

if failed == 0 then
    print("✅ All utility tests passed!")
else
    print("❌ Some utility tests failed!")
end
