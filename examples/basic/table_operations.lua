-- Basic Table Operations Example
-- Demonstrates core table functionality from the wiki-lua library

-- Setup module path (run from project root: lua examples/basic/table_operations.lua)
package.path = package.path .. ';src/modules/?.lua'

-- Auto-initialize MediaWiki environment (eliminates conditional imports)
require('MediaWikiAutoInit')

-- Load the libraries
local TableTools = require('TableTools')
local Functools = require('Functools')
local Array = require('Array')

print("=== Basic Table Operations Example ===")

-- Sample data
local person = {
    name = "John Doe",
    age = 30,
    city = "New York",
    skills = { "lua", "javascript", "python" }
}

local updates = {
    age = 31,
    country = "USA",
    skills = { "lua", "javascript", "python", "go" }
}

print("\n1. Table Deep Copy:")
local personCopy = TableTools.deepCopy(person)
print("Original person name:", person.name)
print("Copy person name:", personCopy.name)

-- Modify copy to show independence
personCopy.name = "Jane Doe"
print("After modifying copy:")
print("Original person name:", person.name)
print("Copy person name:", personCopy.name)

print("\n2. Table Merging:")
-- Simple table merge function since Functools.merge isn't accessible
local function merge_tables(t1, t2)
    local result = TableTools.deepCopy(t1)
    for k, v in pairs(t2) do
        result[k] = v
    end
    return result
end

local merged = merge_tables(person, updates)
print("Merged age:", merged.age)
print("Merged country:", merged.country)
print("Merged skills count:", #merged.skills)

print("\n3. Table Key Operations:")
local keys = TableTools.keys(person)
print("Person keys:", table.concat(keys, ", "))

local values = TableTools.values({ a = 1, b = 2, c = 3 })
print("Sample values:", table.concat(values, ", "))

print("\n4. Table Validation:")
local function validatePerson(tbl)
    local required = { "name", "age", "city" }
    for _, key in ipairs(required) do
        if not tbl[key] then
            return false, "Missing required field: " .. key
        end
    end
    return true, "Valid person object"
end

local isValid, message = validatePerson(person)
print("Person validation:", isValid, "-", message)

print("\n5. Table Transformation:")
-- Create a simple transformation example using manual iteration
local transformed = {}
for key, value in pairs(person) do
    if type(value) == "string" then
        transformed[key] = string.upper(value)
    else
        transformed[key] = value
    end
end

print("Transformed name:", transformed.name)
print("Transformed city:", transformed.city)

print("\n=== Example Complete ===")
