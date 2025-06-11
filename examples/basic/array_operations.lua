-- Basic Array Operations Example
-- Demonstrates core array functionality from the wiki-lua library

-- Setup module path (run from project root: lua examples/basic/array_operations.lua)
package.path = package.path .. ';src/modules/?.lua'

-- Auto-initialize MediaWiki environment (eliminates conditional imports)
require('MediaWikiAutoInit')

-- Load the library
local Array = require('Array')

print("=== Basic Array Operations Example ===")

-- Create arrays
local numbers = Array.new({ 1, 2, 3, 4, 5 })
local words = Array.new({ 'hello', 'world', 'lua', 'programming' })

print("\n1. Basic Array Creation:")
print("Numbers:", table.concat(numbers, ", "))
print("Words:", table.concat(words, ", "))

-- Transform operations
print("\n2. Transform Operations:")
local doubled = numbers:map(function(n) return n * 2 end)
print("Doubled numbers:", table.concat(doubled, ", "))

local uppercased = words:map(function(w) return string.upper(w) end)
print("Uppercased words:", table.concat(uppercased, ", "))

-- Filter operations
print("\n3. Filter Operations:")
local evens = numbers:filter(function(n) return n % 2 == 0 end)
print("Even numbers:", table.concat(evens, ", "))

local longWords = words:filter(function(w) return #w > 4 end)
print("Long words:", table.concat(longWords, ", "))

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

print("Sum of squares > 2:", result)

-- Array utilities
print("\n6. Array Utilities:")
print("Numbers length:", #numbers)
print("Contains 3:", Array.contains(numbers, 3))
print("First element:", numbers[1])
print("Last element:", numbers[#numbers])

print("\n=== Example Complete ===")
