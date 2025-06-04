-- Basic Array Operations Example
-- Demonstrates core array functionality from the wiki-lua library

-- Load the library (adjust path as needed)
local Array = require('src.modules.Array')

print("=== Basic Array Operations Example ===")

-- Create arrays
local numbers = Array.new({ 1, 2, 3, 4, 5 })
local words = Array.new({ 'hello', 'world', 'lua', 'programming' })

print("\n1. Basic Array Creation:")
print("Numbers:", table.concat(numbers:toTable(), ", "))
print("Words:", table.concat(words:toTable(), ", "))

-- Map operations
print("\n2. Map Operations:")
local doubled = numbers:map(function(n) return n * 2 end)
print("Doubled numbers:", table.concat(doubled:toTable(), ", "))

local uppercased = words:map(function(w) return string.upper(w) end)
print("Uppercased words:", table.concat(uppercased:toTable(), ", "))

-- Filter operations
print("\n3. Filter Operations:")
local evens = numbers:filter(function(n) return n % 2 == 0 end)
print("Even numbers:", table.concat(evens:toTable(), ", "))

local longWords = words:filter(function(w) return #w > 4 end)
print("Long words:", table.concat(longWords:toTable(), ", "))

-- Reduce operations
print("\n4. Reduce Operations:")
local sum = numbers:reduce(function(acc, n) return acc + n end, 0)
print("Sum of numbers:", sum)

local concatenated = words:reduce(function(acc, w) return acc .. " " .. w end, "")
print("Concatenated words:", concatenated)

-- Chaining operations
print("\n5. Chaining Operations:")
local result = numbers
    :filter(function(n) return n > 2 end)
    :map(function(n) return n * n end)
    :reduce(function(acc, n) return acc + n end, 0)
print("Sum of squares of numbers > 2:", result)

print("\n=== Example Complete ===")
