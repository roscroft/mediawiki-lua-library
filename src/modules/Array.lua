--[[
====================================
MediaWiki Array Module - Enhanced
====================================

A comprehensive functional programming library for array operations in MediaWiki Lua modules.
This module provides immutable array operations with performance optimizations for various
array types including standard Lua arrays, proxy tables, and sparse arrays.

Features:
- Immutable array operations with copy-on-write semantics
- Smart optimization for different array types (standard vs proxy)
- Comprehensive functional programming utilities (map, filter, reduce, etc.)
- Performance-optimized iteration patterns
- Type-safe operations with comprehensive error checking
- Integration with MediaWiki's proxy table system

@module Array
@version 2.1.0
@author Multiple contributors
@since 2024
--]]

-- Use global libraryUtil from MediaWiki environment
local checkType = libraryUtil.checkType
local checkTypeMulti = libraryUtil.checkTypeMulti

-- Lua 5.1/5.2+ compatibility
---@diagnostic disable-next-line: deprecated
local unpack = unpack or table.unpack

---@class Array<T>: { [integer]: T }
---@operator call(any[]): Array
---@operator concat(any[]): Array
---@operator concat(number|string|function): string
---@operator unm: Array
---@operator add(number|number[]|Array): Array
---@operator sub(number|number[]|Array): Array
---@operator mul(number|number[]|Array): Array
---@operator div(number|number[]|Array): Array
---@operator pow(number|number[]|Array): Array

local Array = {
	pop = table.remove
}
Array.__index = Array

setmetatable(Array, {
	__index = table,
	__call = function(_, arr)
		return Array.new(arr)
	end
})

---Calculates the length of arrays including proxy arrays
---
---This function provides optimized length calculation for different array types:
---- Standard arrays: Uses native # operator (O(1))
---- Proxy arrays: Uses exponential search followed by binary search (O(log n))
---- Empty arrays: Quick detection and return (O(1))
---```
---local std_array = {1, 2, 3}  -- Standard array
---local proxy_array = setmetatable({[1] = 'a', [2] = 'b'}, proxy_mt)
---print(len(std_array))    -- 3 (O(1) operation)
---print(len(proxy_array))  -- 2 (O(log n) operation)
---print(len({}))           -- 0 (O(1) early detection)
---```
---@param arr Array<any> # Array to measure (can be standard array or proxy table)
---@return integer length The number of elements in the array
function Array.len(arr)
	local l = #arr
	if l == 0 then
		if arr[1] ~= nil then
			-- Exponential search to find length of proxy table
			local low = 1
			local high = 1
			local ceil = math.ceil
			while arr[high] ~= nil do
				high = high * 2
			end
			while low ~= high do
				local m = ceil((low + high) / 2)
				if arr[m] == nil then
					high = m - 1
				else
					low = m
				end
			end
			return low
		else
			return 0
		end
	else
		return l
	end
end

local len = Array.len

function Array.__concat(lhs, rhs)
	if type(lhs) == 'table' and type(rhs) == 'table' then
		local res = {}
		local l1 = len(lhs)
		local r1 = len(rhs)
		for i = 1, l1 do
			res[i] = lhs[i]
		end
		for i = 1, r1 do
			res[l1 + i] = rhs[i]
		end
		return setmetatable(res, getmetatable(lhs) or getmetatable(rhs))
	else
		return tostring(lhs) .. tostring(rhs)
	end
end

function Array.__unm(arr)
	return Array.map(arr, function(x) return -x end)
end

---@param lhs number|number[]|Array
---@param rhs number|number[]|Array
---@param funName string
---@param opName string
---@param fun fun(lhs: number, rhs: number): number
---@return Array<number>
local function mathTemplate(lhs, rhs, funName, opName, fun)
	checkTypeMulti('Module:Array.' .. funName, 1, lhs, { 'number', 'table' })
	checkTypeMulti('Module:Array.' .. funName, 2, rhs, { 'number', 'table' })
	local res = {}

	if type(lhs) == 'number' then
		local rhsArray = rhs --[[@as any[] ]]
		local rhsArray_len = len(rhsArray)
		for i = 1, rhsArray_len do
			res[i] = fun(lhs, rhsArray[i])
		end
	elseif type(rhs) == 'number' then
		local lhsArray = lhs --[[@as any[] ]]
		local lhsArray_len = len(lhsArray)
		for i = 1, lhsArray_len do
			res[i] = fun(lhsArray[i], rhs)
		end
	else
		local lhsArray = lhs --[[@as any[] ]]
		local rhsArray = rhs --[[@as any[] ]]
		local lhsArray_len = len(lhsArray)
		local rhsArray_len = len(rhsArray)
		assert(lhsArray_len == rhsArray_len,
			string.format('Elementwise %s failed because arrays have different sizes (left: %d, right: %d)', opName,
				lhsArray_len, rhsArray_len))
		for i = 1, lhsArray_len do
			res[i] = fun(lhsArray[i], rhsArray[i])
		end
	end

	return setmetatable(res, getmetatable(lhs) or getmetatable(rhs))
end

function Array.__add(lhs, rhs)
	return mathTemplate(lhs, rhs, '__add', 'addition', function(x, y) return x + y end)
end

function Array.__sub(lhs, rhs)
	return mathTemplate(lhs, rhs, '__sub', 'substraction', function(x, y) return x - y end)
end

function Array.__mul(lhs, rhs)
	return mathTemplate(lhs, rhs, '__mul', 'multiplication', function(x, y) return x * y end)
end

function Array.__div(lhs, rhs)
	return mathTemplate(lhs, rhs, '__div', 'division', function(x, y) return x / y end)
end

function Array.__pow(lhs, rhs)
	return mathTemplate(lhs, rhs, '__pow', 'exponentiation', function(x, y) return x ^ y end)
end

function Array.__eq(lhs, rhs)
	if len(lhs) ~= len(rhs) then
		return false
	end
	local array_len = len(lhs)
	for i = 1, array_len do
		if lhs[i] ~= rhs[i] then
			return false
		end
	end
	return true
end

---Checks if every value in an array satisfies a predicate or matches a value.
---Behaviour depends on the value of `check`:
---* `number` | `table` | `boolean` | `string` - Checks that all elements in `arr` are equal to this value.
---* `fun(elem: any, i?: integer): boolean` - Returns '''true''' if `fun` returns '''true''' for every element.
---* `nil` - Checks that the array doesn't contain any '''false''' elements.
---@generic T
---@param arr Array<`T`>
---@param check number | table | boolean | string | fun(elem: T, i?: integer): boolean | nil
---@return boolean
function Array.all(arr, check)
	checkType('Module:Array.all', 1, arr, 'table')
	checkTypeMulti('Module:Array.all', 2, check, { 'number', 'table', 'boolean', 'string', 'function', 'nil' })
	if check == nil then check = function(item) return item end end
	if type(check) ~= 'function' then
		local val = check
		check = function(item) return item == val end
	end
	local array_len = len(arr)
	for i = 1, array_len do
		if not check(arr[i], i) then
			return false
		end
	end
	return true
end

---Checks if at least one value in an array satisfies a predicate or matches a value.
---Behaviour depends on the value of `fn`:
---* `number` | `table` | `boolean` | `string` - Checks that `arr` contains this value.
---* `fun(elem: any, i?: integer): boolean` - Returns '''true''' if `fn` returns '''true''' for at least one element.
---* `nil` - Checks that the array contains at least one non '''false''' element.
---@generic T
---@param arr Array<`T`>
---@param check number | table | boolean | string | fun(elem: T, i?: integer): boolean | nil
---@return boolean
function Array.any(arr, check)
	checkType('Module:Array.any', 1, arr, 'table')
	checkTypeMulti('Module:Array.any', 2, check, { 'number', 'table', 'boolean', 'string', 'function', 'nil' })
	if check == nil then check = function(item) return item end end
	if type(check) ~= 'function' then
		local val = check
		check = function(item) return item == val end
	end
	local array_len = len(arr)
	for i = 1, array_len do
		if check(arr[i], i) then
			return true
		end
	end
	return false
end

---Recursively removes all metatables.
---@generic T
---@param arr Array<`T`>
---@return Array<T>
function Array.clean(arr)
	checkType('Module:Array.clean', 1, arr, 'table')
	local array_len = len(arr)
	for i = 1, array_len do
		if type(arr[i]) == 'table' then
			Array.clean(arr[i])
		end
	end
	setmetatable(arr, nil)
	return arr
end

---Make a copy of the input table. Preserves metatables.
---@generic T
---@param arr Array<`T`>
---@param deep? boolean # Recursively clone subtables if '''true'''.
---@return Array<T>
function Array.clone(arr, deep)
	checkType('Module:Array.clone', 1, arr, 'table')
	checkType('Module:Array.clone', 2, deep, 'boolean', true)
	local res = {}
	local array_len = len(arr)
	for i = 1, array_len do
		if deep == true and type(arr[i]) == 'table' then
			res[i] = Array.clone(arr[i], true)
		else
			res[i] = arr[i]
		end
	end
	return setmetatable(res, getmetatable(arr))
end

---Check if `arr` contains `val`.
---@generic T
---@param arr Array<T>
---@param val any
---@return boolean
function Array.contains(arr, val)
	checkType('Module:Array.contains', 1, arr, 'table')
	local array_len = len(arr)
	for i = 1, array_len do
		if arr[i] == val then
			return true
		end
	end
	return false
end

---Check if `arr` contains any of the values in the table `t`.
---@generic T
---@param arr Array<T>
---@param t any[]
---@return boolean
function Array.containsAny(arr, t)
	checkType('Module:Array.containsAny', 1, arr, 'table')
	checkType('Module:Array.containsAny', 2, t, 'table')
	local lookupTbl = {}
	for i = 1, len(t) do
		lookupTbl[t[i]] = true
	end
	for i = 1, len(arr) do
		if lookupTbl[arr[i]] then
			return true
		end
	end
	return false
end

---Check if `arr` contains all values in the table `t`.
---@generic T
---@param arr Array<T>
---@param t any[]
---@return boolean
function Array.containsAll(arr, t)
	checkType('Module:Array.containsAll', 1, arr, 'table')
	checkType('Module:Array.containsAll', 2, t, 'table')
	local lookupTbl = {}
	local trueCount = 0
	local l = len(t)
	for i = 1, l do
		lookupTbl[t[i]] = false
	end
	local array_len = len(arr)
	for i = 1, array_len do
		if lookupTbl[arr[i]] == false then
			lookupTbl[arr[i]] = true
			trueCount = trueCount + 1
		end
		if trueCount == l then
			return true
		end
	end
	return false
end

---Convolute two number arrays.
---@generic T: number
---@param x Array<T>
---@param y Array<T>
---@return Array<T>
function Array.convolve(x, y)
	checkType('Module:Array.convolve', 1, x, 'table')
	checkType('Module:Array.convolve', 2, y, 'table')
	local z = {}
	local xLen, yLen = len(x), len(y)
	for j = 1, (xLen + yLen - 1) do
		local sum = 0
		for k = math.max(1, j - yLen + 1), math.min(xLen, j) do
			sum = sum + x[k] * y[j - k + 1]
		end
		z[j] = sum
	end
	return setmetatable(z, getmetatable(x) or getmetatable(y))
end

---Remove '''nil''' values from `arr` while preserving order.
---@generic T
---@param arr Array<`T`>
---@return Array<T>
function Array.condenseSparse(arr)
	checkType('Module:Array.condenseSparse', 1, arr, 'table')
	local keys = {}
	local res = {}
	local l = 0
	for k in pairs(arr) do
		l = l + 1
		keys[l] = k
	end
	table.sort(keys)
	for i = 1, l do
		res[i] = arr[keys[i]]
	end
	return setmetatable(res, getmetatable(arr))
end

---Behaviour depends on the value of `check`:
---* `number` | `table` | `boolean` | `string` - Counts the number of times this value occurs in `arr`.
---* `fun(elem: any): boolean` - Count the number of times the function returs '''true''' when called on the elements of `arr`.
---* `nil` -  Counts the number of non '''false''' elements.
---@generic T
---@param arr Array<`T`>
---@param check number | table | boolean | string | fun(elem: T, i?: integer): boolean | nil
---@return integer
function Array.count(arr, check)
	checkType('Module:Array.count', 1, arr, 'table')
	if check == nil then check = function(item) return item end end
	if type(check) ~= 'function' then
		local _check = check
		check = function(item) return item == _check end
	end
	local count = 0
	for i = 1, len(arr) do
		if check(arr[i]) then
			count = count + 1
		end
	end
	return count
end

---Differentiate the array
---@generic T: number
---@param arr Array<`T`>
---@param order number? # Order of the differentiation. Default is 1.
---@return Array<T> # Length is `#arr - order`
function Array.diff(arr, order)
	checkType('Module:Array.diff', 1, arr, 'table')
	checkType('Module:Array.diff', 2, order, 'number', true)
	local res = {}
	for i = 1, len(arr) - 1 do
		res[i] = arr[i + 1] - arr[i]
	end
	if order and order > 1 then
		return Array.diff(res, order - 1)
	end
	return setmetatable(res, getmetatable(arr))
end

---Iterate over each element in the array
---
---Executes the provided function for every element in the array. This function is optimized based on array type for maximum performance:
---- Standard arrays: Uses `ipairs` for optimal performance (O(n))
---- Proxy/sparse arrays: Uses manual indexing with cached length (O(n))
---Examples:
---```
---local arr = {1, 2, 3, 4, 5}
---Array.each(arr, function(value, index)
---    print(string.format('arr[%d] = %s', index, value))
---end)
---```
---Works with proxy arrays too:
---```
---local proxy = setmetatable({[1] = 'a', [2] = 'b'}, proxy_mt)
---Array.each(proxy, function(value, index)
---    print(value) -- Automatically detects proxy and uses appropriate iteration
---end)
---```
---@generic T
---@param arr Array<`T`> # Array to iterate over
---@param fn fun(elem: T, i?: integer) # Function called for each element
function Array.each(arr, fn)
	checkType('Module:Array.each', 1, arr, 'table')
	checkType('Module:Array.each', 2, fn, 'function')
	-- Performance optimization: use ipairs for regular arrays, manual indexing for proxy arrays
	local array_len = len(arr)
	if array_len == #arr and arr[1] ~= nil then
		-- Standard array - use ipairs for better performance
		for i, v in ipairs(arr) do
			fn(v, i)
		end
	else
		-- Proxy array or sparse array - use manual indexing
		for i = 1, array_len do
			fn(arr[i], i)
		end
	end
end

---Filter array elements using a predicate function
---
---Creates a new array containing only elements for which the predicate function returns a truthy value. This operation is immutable - the original array is not modified. Performance is optimized with array length caching.
---
---Performance characteristics:
---- Time complexity: O(n) where n is the array length
---- Space complexity: O(k) where k is the number of matching elements
---- Uses cached array length for optimal iteration
---
---Examples:
---```
---local numbers = {1, 2, 3, 4, 5, 6}
---local evens = Array.filter(numbers, function(x)
---    return x % 2 == 0
---end)  -- {2, 4, 6}
---
---local people = {
---    {name = "Alice", age = 25},
---    {name = "Bob", age = 17},
---    {name = "Charlie", age = 30}
---}
---local adults = Array.filter(people, function(person)
---    return person.age >= 18
---end)  -- {{name = "Alice", age = 25}, {name = "Charlie", age = 30}}
---```
---With index parameter:
---```
---local firstHalf = Array.filter(numbers, function(value, index)
---    return index <= #numbers / 2
---end)  -- {1, 2, 3}
---```
---@generic T
---@param arr Array<`T`> # Array to filter
---@param fn fun(elem: T, i?: integer): boolean # Predicate function
---@return Array<T> # New array containing only elements that pass the test
function Array.filter(arr, fn)
	checkType('Module:Array.filter', 1, arr, 'table')
	checkType('Module:Array.filter', 2, fn, 'function')

	local r = {}
	local l = 0
	-- Performance optimization: cache array length
	local array_len = len(arr)
	for i = 1, array_len do
		if fn(arr[i], i) then
			l = l + 1
			r[l] = arr[i]
		end
	end
	return setmetatable(r, getmetatable(arr))
end

---Find the first element matching a condition or value.
---Behaviour depends on the value of `check`:
---* `number` | `table` | `boolean` | `string` - Value to search for in `arr`.
---* `fun(elem: T, i?: integer): boolean` - Predicate to search for (when '''true''') in `arr`.
---Searches through the array to find the first element that matches. Returns both the element and its index.
---Performance characteristics:
---- Direct value search: O(n) with optimized value comparison
---- Function search: O(n) with cached array length and early termination
---- Best case: O(1) if element is found early
---- Worst case: O(n) if element not found or is last
---Direct value search:
---```
---local numbers = {10, 20, 30, 40, 50}
---local value, index = Array.find(numbers, 30)
---print(value, index)  -- 30, 3
---
---local notFound, idx = Array.find(numbers, 99, "default")
---print(notFound, idx)  -- "default", nil
---```
---Function-based search:
---```
---local people = {
---    {name = "Alice", age = 25},
---    {name = "Bob", age = 17},
---    {name = "Charlie", age = 30}
---}
---
---local adult, pos = Array.find(people, function(person)
---    return person.age >= 18
---end)
---print(adult.name, pos)  -- "Alice", 1
---```
---Complex search with index parameter:
---```
---local firstInSecondHalf = Array.find(numbers, function(value, index)
---    return index > #numbers / 2
---end)
---print(firstInSecondHalf)  -- 40 (first element in second half)
---```
---@generic T
---@param arr Array<T> # Array to search through
---@param check number | table | boolean | string | fun(elem: T, i?: integer): boolean # Value to search for OR predicate function
---@param default? any # Value to return if no match found
---@return T? elem # The first element that passed the test (or default)
---@return integer? i # The index of the matching element (or nil)
function Array.find(arr, check, default)
	checkType('Module:Array.find', 1, arr, 'table')
	checkTypeMulti('Module:Array.find', 2, check, { 'number', 'table', 'boolean', 'string', 'function' })
	if type(check) ~= 'function' then
		local search_val = check
		-- Direct value search - optimized path
		local array_len = len(arr)
		for i = 1, array_len do
			if arr[i] == search_val then
				return arr[i], i
			end
		end
		return default, nil
	end
	-- Function search - original path with length caching
	local array_len = len(arr)
	for i = 1, array_len do
		if check(arr[i], i) then
			return arr[i], i
		end
	end
	return default, nil
end

---Find the index of `check` in `arr`, or the index of the function satisfying `check`.
---Behaviour depends on the value of `check`:
---* `number` | `table` | `boolean` | `string` - Value to search for in `arr`.
---* `fun(elem: T, i?: integer): boolean` - Predicate to search for (when '''true''') in `arr`.
---@generic T
---@param arr Array<T> # Array to search through
---@param check number | table | boolean | string | fun(elem: T, i?: integer): boolean # Value to search for OR predicate function
---@param default? any # Value to return if no match found
---@return integer? i # The index of the matching element (or nil)
function Array.find_index(arr, check, default)
	checkType('Module:Array.find_index', 1, arr, 'table')
	checkTypeMulti('Module:Array.find_index', 2, check, { 'number', 'table', 'boolean', 'string', 'function' })
	if type(check) ~= 'function' then
		local _val = check
		check = function(item) return item == _val end
	end
	local array_len = len(arr)
	for i = 1, array_len do
		if check(arr[i], i) then
			return i
		end
	end
	return default
end

---Extracts a subset of `arr`.
---@generic T
---@param arr Array<`T`>
---@param indices integer|integer[] # indices of the elements.
---@return T|Array<T>|nil
function Array.get(arr, indices)
	checkType('Module:Array.get', 1, arr, 'table')
	checkTypeMulti('Module:Array.get', 2, indices, { 'number', 'table' })
	assert((type(indices) == 'number') and (math.floor(indices) == indices) or (type(indices) == 'table'),
		"Module:Array.get: 'indices' must be an integer or table of integers")

	local single_index = type(indices) == 'number'
	if single_index then
		-- For single index, return the raw value directly
		local arrLength = len(arr)
		if indices >= 1 and indices <= arrLength then
			return arr[indices]
		else
			return nil
		end
	end

	-- For multiple indices, return Array object
	local indexArray = indices --[[@as integer[] ]]
	local res = {}
	local arrLength = len(arr)
	for i = 1, len(indexArray) do
		local idx = indexArray[i]
		if idx >= 1 and idx <= arrLength then
			res[i] = arr[idx]
		else
			res[i] = nil
		end
	end
	return setmetatable(res, getmetatable(arr))
end

---Integrates the array. Effectively does <math>\left\{\sum^{n}_{start}{arr[n]} \,\Bigg|\, n \in [start, stop]\right\}</math>.
---@generic T
---@param arr Array<`T`> # number
---@param start? integer # Index where to start the summation. Defaults to 1.
---@param stop? integer # Index where to stop the summation. Defaults to #arr.
---@return Array<T>
function Array.int(arr, start, stop)
	checkType('Module:Array.int', 1, arr, 'table')
	checkType('Module:Array.int', 2, start, 'number', true)
	checkType('Module:Array.int', 3, stop, 'number', true)
	local res = {}
	start = start or 1
	stop = stop or len(arr)
	res[1] = arr[start]
	for i = 1, stop - start do
		res[i + 1] = res[i] + arr[start + i]
	end
	return setmetatable(res, getmetatable(arr))
end

---Returns an array with elements that are present in both arrays.
---@generic T
---@param left Array<T>
---@param right Array<T>
---@return Array<T>
function Array.intersect(left, right)
	checkType('Module:Array.intersect', 1, left, 'table')
	checkType('Module:Array.intersect', 2, right, 'table')
	local arr2Elements = {}
	local res = {}
	local l = 0
	Array.each(right, function(item) arr2Elements[item] = true end)
	Array.each(left, function(item)
		if arr2Elements[item] then
			l = l + 1
			res[l] = item
		end
	end)
	return setmetatable(res, getmetatable(left) or getmetatable(right))
end

---Checks if the two arrays have at least one element in common.
---@generic T
---@param left Array<T>
---@param right Array<T>
---@return boolean
function Array.intersects(left, right)
	checkType('Module:Array.intersects', 1, left, 'table')
	checkType('Module:Array.intersects', 2, right, 'table')
	local small = {}
	local large
	if len(left) <= len(right) then
		Array.each(left, function(item) small[item] = true end)
		large = right
	else
		Array.each(right, function(item) small[item] = true end)
		large = left
	end
	return Array.any(large, function(item) return small[item] end)
end

---Inserts values into `arr`.
---@generic T
---@param arr Array<T>
---@param val T # If `val` is an array and `unpackVal` is '''true''' then the individual elements of `val` are inserted.
---@param index? integer # Location to start the insertion. Default is at the end of `arr`.
---@param unpackVal? boolean # Default is '''false'''.
---@return Array<T>
function Array.insert(arr, val, index, unpackVal)
	checkType('Module:Array.insert', 1, arr, 'table')
	checkTypeMulti('Module:Array.insert', 3, index, { 'number', 'boolean', 'nil' })
	checkType('Module:Array.insert', 4, unpackVal, 'boolean', true)
	if type(index) == 'boolean' then
		unpackVal, index = index, nil
	end
	local l = len(arr)
	index = index or (l + 1)
	local mt = getmetatable(arr)
	setmetatable(arr, nil)

	if unpackVal and type(val) == 'table' then
		local l2 = len(val)
		for i = 0, l - index do
			arr[l + l2 - i] = arr[l - i]
		end
		for i = 0, l2 - 1 do
			arr[index + i] = val[i + 1]
		end
	else
		table.insert(arr, index, val)
	end

	return setmetatable(arr, mt)
end

---Returns the last element of `arr`.
---@generic T
---@param arr Array<`T`>
---@param offset? integer # Offset from the end (default 0, -1 for second to last, etc.)
---@return T
function Array.last(arr, offset)
	checkType('Module:Array.last', 1, arr, 'table')
	checkType('Module:Array.last', 2, offset, 'number', true)
	local length = len(arr)
	if length == 0 then
		return nil
	end
	local index = length + (offset or 0)
	if index < 1 or index > length then
		return nil
	end
	return arr[index]
end

---Transform array elements using a mapping function
---
---Creates a new array by applying the transformation function to every element of the input array. This operation is immutable - the original array is not modified. Supports filtering during mapping by returning nil for unwanted elements.
---
---Performance characteristics:
---- Time complexity: O(n) where n is the array length
---- Space complexity: O(m) where m is the number of non-nil results
---- Uses cached array length and optimized result building
---- Automatically filters out nil results for sparse result arrays
---Examples:
---```
---local numbers = {1, 2, 3, 4, 5}
---local doubled = Array.map(numbers, function(x)
---    return x * 2
---end)  -- {2, 4, 6, 8, 10}
---
---local words = {"hello", "world", "test"}
---local lengths = Array.map(words, function(word)
---    return #word
---end)  -- {5, 5, 4}
---```
---Map with filtering (nil values are excluded):
---```
---local mixed = {1, 2, 3, 4, 5}
---local evenDoubled = Array.map(mixed, function(x)
---    if x % 2 == 0 then
---        return x * 2
---    else
---        return nil  -- This will be filtered out
---    end
---end)  -- {4, 8}
---```
---Using index parameter:
---```
---local indexed = Array.map(numbers, function(value, index)
---    return string.format('%d: %s', index, value)
---end)  -- {"1: 1", "2: 2", "3: 3", "4: 4", "5: 5"}
---```
---@generic T, U
---@param arr Array<`T`> # Array to transform
---@param fn fun(elem: T, i?: integer): `U` # Transformation function
---@return Array<U> # New array containing transformed elements
function Array.map(arr, fn)
	checkType('Module:Array.map', 1, arr, 'table')
	checkType('Module:Array.map', 2, fn, 'function')

	local l = 0
	local r = {}
	local array_len = len(arr)
	for i = 1, array_len do
		local tmp = fn(arr[i], i)
		if tmp ~= nil then
			l = l + 1
			r[l] = tmp
		end
	end
	return setmetatable(r, getmetatable(arr))
end

---Find the element for which `fn` returned the largest value.
---@generic T, U # U needs to be in the Eq class or its Lua equivalent
---@param arr Array<`T`>
---@param fn fun(elem: T): U # The returned value needs to be comparable using the `<` operator.
---@return T elem # The element with the largest `fn` value.
---@return U value # The largest `fn` value.
---@return integer i # The index of this element.
function Array.max_by(arr, fn)
	checkType('Module:Array.max_by', 1, arr, 'table')
	checkType('Module:Array.max_by', 2, fn, 'function')
	-- Commenting out check until we can review the correctness of max_by returning a value for an empty array
	--local length = len(arr)
	--if length == 0 then
	--	error("Module:Array.max_by: array cannot be empty")
	--end
	local result = Array.reduce(arr, function(new, old, i)
		local y = fn(new)
		return y > old[2] and { new, y, i } or old
	end, { nil, -math.huge, 0 })
	return result[1], result[2], result[3]
end

---Find the largest value in the array.
---@generic T: number # T needs to be in Eq or its Lua equivalent
---@param arr Array<`T`> # The values need to be comparable using the `<` operator.
---@return T elem
---@return integer i # The index of the largest value.
function Array.max(arr)
	checkType('Module:Array.max', 1, arr, 'table')
	if len(arr) == 0 then
		error("Module:Array.max: array cannot be empty")
	end
	local val, _, i = Array.max_by(arr, function(x) return x end)
	return val, i
end

---Find the smallest value in the array.
---@generic T: number # T needs to be in Eq or its Lua equivalent
---@param arr Array<`T`> # The values need to be comparable using the `<` operator.
---@return T elem
---@return integer i # The index of the largest value.
function Array.min(arr)
	checkType('Module:Array.min', 1, arr, 'table')
	if len(arr) == 0 then
		error("Module:Array.min: array cannot be empty")
	end
	local val, _, i = Array.max_by(arr, function(x) return -x end)
	return val, i
end

---Create a new Array.
---Converts a regular Lua table into an Array object that supports:
---- Method chaining with colon syntax (:map, :filter, :reduce, etc.)
---- Mathematical operators (+, -, *, /, ^, unary -)
---- Concatenation operators (..)
---- Equality comparison (==)
---- Optimized iteration for different array types
---
---Performance characteristics:
---- Construction: O(n) for shallow conversion, O(n*m) for deep nested arrays
---- Method calls: Optimized based on array type (standard vs proxy)
---- Memory: Minimal overhead with shared metatable
---Basic creation and method chaining:
---```
---local numbers = Array.new({1, 2, 3, 4, 5})
---local result = numbers
---    :filter(function(x) return x > 2 end)  -- {3, 4, 5}
---    :map(function(x) return x * x end)     -- {9, 16, 25}
---    :reduce(function(acc, x) return acc + x end, 0)  -- 50
---```
---Mathematical operations:
---```
---local x = Array.new({1, 2, 3})
---local y = Array.new({4, 5, 6})
---print(-x)      -- {-1, -2, -3}
---print(x + 2)   -- {3, 4, 5}
---print(x * y)   -- {4, 10, 18}
---print(x .. y)  -- {1, 2, 3, 4, 5, 6}
---```
---Alternative creation syntax:
---```
---local alt = Array({10, 20, 30}) -- Shorthand syntax
---```
---Empty array:
---```
---local empty = Array.new() -- Creates empty array ready for operations
---```
---@generic T
---@param arr? any[] # Optional input table (creates empty array if nil)
---@return Array<T> # RS Wiki Array
function Array.new(arr)
	local obj = arr or {}
	for _, v in pairs(obj) do
		if type(v) == 'table' then
			Array.new(v)
		end
	end

	if getmetatable(obj) == nil then
		setmetatable(obj, Array)
	end

	return obj
end

---@class Array.Incrementor
---@field val number # Current value that can be read/written
---@field step number # Step size that can be read/written

---Creates an object that returns a value that is `step` higher than the previous value each time it gets called.
---The stored value can be read without incrementing by reading the `val` field.
---A new stored value can be set through the `val` field.
---A new step size can be set through the `step` field.
---```
---local inc = arr.newIncrementor(10, 5)
---print( inc() ) -- 10
---print( inc() ) -- 15
---print( inc.val ) -- 15
---inc.val = 100
---inc.step = 20
---print( inc.val ) -- 100
---print( inc() ) -- 120
---```
---@param start? number # Default is 1.
---@param step? number # Default is 1.
---@return Array.Incrementor
function Array.newIncrementor(start, step)
	checkType('Module:Array.newIncrementor', 1, start, 'number', true)
	checkType('Module:Array.newIncrementor', 2, step, 'number', true)
	step = step or 1
	local n = (start or 1) - step
	local obj = {}
	return setmetatable(obj, {
		__call = function()
			n = n + step
			return n
		end,
		__tostring = function() return tostring(n) end,
		__index = function() return n end,
		__newindex = function(_, k, v)
			if k == 'step' and type(v) == 'number' then
				step = v
			elseif type(v) == 'number' then
				n = v
			end
		end,
		__concat = function(x, y) return tostring(x) .. tostring(y) end
	})
end

---Returns a table created by promoting a key.
---@generic T
---@generic U: number | table | boolean | string | fun(elem: any, i?: integer): boolean
---@param arr Array<`T`>
---@param attr `U`  # Value of common key to promote, or function that returns true for the value to promote
---@return Array<U>
function Array.promote(arr, attr)
	checkType('Module:Array.promote', 1, arr, 'table')
	checkTypeMulti('Module:Array.promote', 2, attr, { 'number', 'table', 'boolean', 'string', 'function' })
	local r = {}
	local array_len = len(arr)
	for i = 1, array_len do
		local record = arr[i]
		local attr_val
		if type(attr) == "function" then
			attr_val = attr(record)
		else
			attr_val = record[attr]
		end
		if attr_val then
			local record_without_attr = {}
			for key, value in pairs(record) do
				if key ~= attr then
					record_without_attr[key] = value
				end
			end
			r[tostring(attr_val)] = record_without_attr
		end
	end
	return r
end

---Returns a range of numbers.
---@generic T: number
---@param start T # Start value inclusive.
---@param stop? T # Stop value inclusive for integers, exclusive for floats.
---@param step? T # Default is 1.
---@overload fun(stop: number): Array
---@return Array<T>
function Array.range(start, stop, step)
	checkType('Module:Array.range', 1, start, 'integer')
	checkType('Module:Array.range', 2, stop, 'integer', true)
	checkType('Module:Array.range', 3, step, 'integer', true)

	local arr = {}
	local length = 0
	if not stop then
		stop = start
		start = 1
	end

	step = step or 1

	-- Prevent infinite loops
	if step == 0 then
		error("Module:Array.range: step cannot be 0")
	end
	if step > 0 and start > stop then
		error("Module:Array.range: start must be <= stop when step is positive")
	end
	if step < 0 and start < stop then
		error("Module:Array.range: start must be >= stop when step is negative")
	end

	for i = start, stop, step do
		length = length + 1
		-- Prevent excessive memory usage
		if length > 100000 then
			error("Module:Array.range: range too large (max 100000 elements)")
		end
		arr[length] = i
	end
	return setmetatable(arr, Array)
end

---Condenses the array into a single value.
---For each element `fn` is called with the current element, the current accumulator, and the current element index. The returned value of `fn` becomes the accumulator for the next element. If no `accumulator` value is given at the start then the first element off `arr` becomes the accumulator and the iteration starts from the second element.
---Examples:
---```
---local t = { 1, 2, 3, 4 }
---local sum = arr.reduce( t, function(elem, acc) return acc + elem end ) -- sum == 10
---```
---@generic T, U
---@param arr Array<`T`>
---@param fn fun(elem: T, acc: U, i?: integer): U # The result of this function becomes the `acc` for the next element.
---@param accumulator? U
---@return U
function Array.reduce(arr, fn, accumulator)
	checkType('Module:Array.reduce', 1, arr, 'table')
	checkType('Module:Array.reduce', 2, fn, 'function')
	local acc = accumulator
	local start = 1
	if acc == nil then
		acc = arr[1]
		start = 2
	end
	local array_len = len(arr)
	for i = start, array_len do
		acc = fn(arr[i], acc, i)
	end
	return acc
end

---Make a copy of `arr` with certain values removed.
---Behaviour for different values of `check`:
---* `number` | `boolean` | `string` - Remove values equal to this.
---* `table` - Remove values found in this table.
---* `fun(elem: any, i?: integer): boolean` - Remove elements for which the functions returns '''true'''.
---@generic T
---@param arr Array<`T`>
---@param check number | boolean | string | table | fun(elem: T, i?: integer): boolean
---@return Array<T>
function Array.reject(arr, check)
	checkType('Module:Array.reject', 1, arr, 'table')
	checkTypeMulti('Module:Array.reject', 2, check, { 'function', 'table', 'number', 'boolean', 'string' })

	-- Convert check to a rejection function
	local rejectFn
	if type(check) == 'function' then
		rejectFn = check
	else
		-- Convert single values to table for uniform handling
		local checkValues = type(check) == 'table' and check or { check }

		-- Create a lookup map for O(1) lookups
		local rejectMap = {}
		for i = 1, len(checkValues) do
			rejectMap[checkValues[i]] = true
		end

		rejectFn = function(elem) return rejectMap[elem] end
	end

	-- Build result array with values that don't match rejection criteria
	local r = {}
	local l = 0
	local array_len = len(arr)

	for i = 1, array_len do
		if not rejectFn(arr[i], i) then
			l = l + 1
			r[l] = arr[i]
		end
	end

	return setmetatable(r, getmetatable(arr))
end

---Returns an Array with `val` repeated `n` times.
---@generic T
---@param val `T`
---@param n integer
---@return Array<T>
function Array.rep(val, n)
	checkType('Module:Array.rep', 2, n, 'number')
	local r = {}
	for i = 1, n do
		r[i] = val
	end
	return setmetatable(r, Array)
end

---Condenses the array into a single value while saving every accumulator value.
---For each element `fn` is called with the current element, the current accumulator, and the current element index. The returned value of `fn` becomes the accumulator for the next element.
---If no `accumulator` value is given at the start then the first element off `arr` becomes the accumulator and the iteration starts from the second element.
---Examples:
---```
---local t = { 1, 2, 3, 4 }
---local x = arr.scan( t, function(elem, acc) return acc + elem end ) -- x = { 1, 3, 6, 10 }
---```
---@generic T, U
---@param arr Array<`T`>
---@param fn fun(elem: T, acc: `U`, i?: integer): U # Returned value becomes the accumulator for the next element.
---@param accumulator? U
---@return Array<U>
function Array.scan(arr, fn, accumulator)
	checkType('Module:Array.scan', 1, arr, 'table')
	checkType('Module:Array.scan', 2, fn, 'function')
	local acc = accumulator
	local r = {}
	for i = 1, len(arr) do
		if i == 1 and not accumulator then
			acc = arr[i]
		else
			acc = fn(arr[i], acc, i)
		end
		r[i] = acc
	end
	return setmetatable(r, getmetatable(arr))
end

---Update a range of index with a range of values.
---If only one value is given but multiple indices than that value is set for all those indices. If `values` is a table then it must of the same length as `indices`.
---@generic T, U
---@param arr Array<T>
---@param indices integer|integer[]
---@param values U|U[]
---@return Array<T|U>
function Array.set(arr, indices, values)
	checkType('Module:Array.set', 1, arr, 'table')
	checkTypeMulti('Module:Array.set', 2, indices, { 'table', 'number' })
	local mt = getmetatable(arr)
	setmetatable(arr, nil)
	if type(indices) == 'number' then
		indices = { indices }
	end
	local indexArray = indices --[[@as integer[] ]]
	if type(values) == 'table' then
		local valueArray = values --[[@as any[] ]]
		assert(len(indexArray) == len(valueArray),
			string.format(
				"Module:Array.set: 'indices' and 'values' arrays are not equal length (#indices = %d, #values = %d)",
				len(indexArray), len(valueArray)))
		for i = 1, len(indexArray) do
			arr[indexArray[i]] = valueArray[i]
		end
	else
		for i = 1, len(indexArray) do
			arr[indexArray[i]] = values
		end
	end
	return setmetatable(arr, mt)
end

---Extract a subtable from `arr`.
---@generic T
---@param arr Array<T>
---@param start integer # Start index. Use negative values to count form the end of the array.
---@param stop? integer # Stop index. Use negative values to count form the end of the array.
---@return Array<T>
function Array.slice(arr, start, stop)
	checkType('Module:Array.slice', 1, arr, 'table')
	checkType('Module:Array.slice', 2, start, 'number', true)
	checkType('Module:Array.slice', 3, stop, 'number', true)
	start = start or len(arr)
	if start < 0 then
		start = len(arr) + start
	end
	if stop == nil then
		stop = start
		start = 1
	end
	if stop < 0 then
		stop = len(arr) + stop
	end
	local r = {}
	local length = 0
	for i = start, stop do
		length = length + 1
		r[length] = arr[i]
	end
	return setmetatable(r, getmetatable(arr))
end

---Split `arr` into two arrays.
---@generic T
---@param arr Array<T>
---@param index integer # Index to split on.
---@return Array<T> fst # [1, index]
---@return Array<T> snd # [index + 1, #arr]
function Array.split(arr, index)
	checkType('Module:Array.split', 1, arr, 'table')
	checkType('Module:Array.split', 2, index, 'number')
	local fst = {}
	local snd = {}
	for i = 1, len(arr) do
		table.insert(i <= index and fst or snd, arr[i])
	end
	return setmetatable(fst, getmetatable(arr)), setmetatable(snd, getmetatable(arr))
end

---Returns the sum of all elements of `arr`.
---@generic T: number
---@param arr Array<T>
---@return number
function Array.sum(arr)
	checkType('Module:Array.sum', 1, arr, 'table')
	local res = 0
	for i = 1, len(arr) do
		res = res + arr[i]
	end
	return res
end

---Extract a subtable from `arr`.
---@generic T
---@param arr Array<T>
---@param count integer # Length of the subtable.
---@param start? integer # Start index. Default is 1.
---@return Array<T>
function Array.take(arr, count, start)
	checkType('Module:Array.take', 1, arr, 'table')
	checkType('Module:Array.take', 2, count, 'number')
	checkType('Module:Array.take', 3, start, 'number', true)
	assert(count == math.floor(count), "Module:Array.take: 'count' must be an integer")
	assert((start == nil) or (start == math.floor(start)), "Module:Array.take: 'start' must be nil or an integer")
	local x = {}
	start = start or 1
	return Array.slice(arr, start, start + count - 1)
end

---Extract a subtable from `arr`.
---Examples:
---```
---local t = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
---local x = arr.take_every( t, 2 )       -- x = { 1, 3, 5, 7, 9 }
---local x = arr.take_every( t, 2, 3 )    -- x = { 3, 5, 7, 9 }
---local x = arr.take_every( t, 2, 3, 2 ) -- x = { 3, 5 }
---```
---@generic T
---@param arr Array<T>
---@param n integer # Step size.
---@param start? integer # Start index.
---@param count? integer # Max amount of elements to get.
---@return Array<T>
function Array.take_every(arr, n, start, count)
	checkType('Module:Array.take_every', 1, arr, 'table')
	checkType('Module:Array.take_every', 2, n, 'number')
	checkType('Module:Array.take_every', 3, start, 'number', true)
	checkType('Module:Array.take_every', 4, count, 'number', true)
	count = count or len(arr)
	start = start or 1
	local stop = math.min(len(arr), start + n * (count - 1))
	local r = {}
	local l = 0
	for i = start, stop, n do
		l = l + 1
		r[l] = arr[i]
	end
	return setmetatable(r, getmetatable(arr))
end

---Return a new table with all duplicates removed.
---@generic T, U
---@param arr Array<`T`>
---@param fn? fun(elem: T): U # Function to generate an id for each element. The result will then contain elements that generated unique ids.
---@return Array<T>
function Array.unique(arr, fn)
	checkType('Module:Array.unique', 1, arr, 'table')
	checkType('Module:Array.unique', 2, fn, 'function', true)
	fn = fn or function(item) return item end
	local r = {}
	local l = 0
	local hash = {}
	for i = 1, len(arr) do
		local id = fn(arr[i])
		if not hash[id] then
			l = l + 1
			r[l] = arr[i]
			hash[id] = true
		end
	end
	return setmetatable(r, getmetatable(arr))
end

---Combine elements with the same index from multiple arrays.
---Examples:
---```
---local x = {1, 2, 3}
---local y = {4, 5, 6, 7}
---local z = arr.zip( x, y ) -- z = { { 1, 4 }, { 2, 5 }, { 3, 6 }, { 7 } }
---```
---@generic T
---@param ... Array<T>
---@return Array<Array<T>>
function Array.zip(...)
	local arrs = { ... }
	checkType('Module:Array.zip', 1, arrs[1], 'table')
	local r = {}
	local _, longest = Array.max_by(arrs, function(arr) return len(arr) end)
	for i = 1, longest do
		local q = {}
		for j = 1, len(arrs) do
			table.insert(q, arrs[j][i])
		end
		table.insert(r, setmetatable(q, Array))
	end
	return setmetatable(r, Array)
end

return Array
