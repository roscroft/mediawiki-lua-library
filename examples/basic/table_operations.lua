-- Basic Table Operations Example
-- Demonstrates core table functionality from the wiki-lua library

-- Load the library
local Tables = require('src.modules.Tables')

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
local personCopy = Tables.deepcopy(person)
print("Original person name:", person.name)
print("Copy person name:", personCopy.name)

-- Modify copy to show independence
personCopy.name = "Jane Doe"
print("After modifying copy:")
print("Original person name:", person.name)
print("Copy person name:", personCopy.name)

print("\n2. Table Merging:")
local merged = Tables.merge(person, updates)
print("Merged age:", merged.age)
print("Merged country:", merged.country)
print("Merged skills count:", #merged.skills)

print("\n3. Table Key Operations:")
local keys = Tables.keys(person)
print("Person keys:", table.concat(keys, ", "))

local values = Tables.values({ a = 1, b = 2, c = 3 })
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
local transformed = Tables.map(person, function(key, value)
    if type(value) == "string" then
        return key, string.upper(value)
    end
    return key, value
end)

print("Transformed name:", transformed.name)
print("Transformed city:", transformed.city)

print("\n=== Example Complete ===")
