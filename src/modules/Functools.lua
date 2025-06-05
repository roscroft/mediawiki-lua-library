--[[ Functools - Enhanced MediaWiki Functional Programming Library
Provides purely functional programming utilities, combinators, and function composition tools.
## Key Features:
- **Currying**: Transform multi-argument functions into single-argument chains
- **Combinators**: Classic functional programming combinators (SKI, B, C, etc.)
- **Function Composition**: Pipe and compose operations for function chaining
- **Maybe Monad**: Safe computation handling with Maybe type
- **Array Operations**: Map, filter, fold operations with functional style
- **Maybe Monad**: Safe computation handling with Maybe type
- **Array Operations**: Map, filter, fold operations with functional style
- **Type Safety**: Comprehensive type annotations for development tooling

## Usage Examples:
```lua
local func = require('Module:Functools')

-- Currying example
local add = func.c2(function(x, y) return x + y end)
local add5 = add(5)
print(add5(3)) --> 8

-- Composition example
local double = function(x) return x * 2 end
local increment = function(x) return x + 1 end
local doubleAndIncrement = func.compose(increment, double)
print(doubleAndIncrement(5)) --> 11

-- Maybe monad example
local safe_divide = function(x, y)
    if y == 0 then return func.Maybe.nothing
    else return func.Maybe.just(x / y) end
end
local result = func.Maybe.map(function(x) return x * 2 end)(safe_divide(10, 2))
-- result.value == 10
```

@module Functools
@author Wiki Lua Team
@license MIT
@version 2.0.0
@since 1.0.0
--]]

-- ======================
-- MODULE IMPORTS & SETUP
-- ======================

local libraryUtil = require('libraryUtil')
local checkType = libraryUtil.checkType

-- Compatibility layer for different Lua versions
---@diagnostic disable-next-line: deprecated
local unpack = unpack or table.unpack -- Use the global unpack in Lua 5.1, table.unpack in 5.2+

---@class Functools
local func = {}

-- ======================
-- CORE COMBINATORS - Pure Functional Programming Building Blocks
-- ======================

---Identity function. I combinator. a -> a
---@generic T
---@param x T Value to return
---@return T x The original value
function func.id(x) return x end

---Constant function. K combinator. a -> b -> a
---@generic T, U
---@param x T Constant value to return
---@return fun(y: U): T Function that always returns x
function func.const(x) return function(y) return x end end

---Apply function. A combinator. (a -> b) -> a -> b
---@generic A, B
---@param f fun(x: A): B Function to apply
---@return fun(x: A): B Function that applies f to its argument
function func.apply(f) return function(x) return f(x) end end

---Thrush combinator. T combinator. a -> (a -> b) -> b
---@generic A, B
---@param x A Value to pass to function
---@return fun(f: fun(x: A): B): B Function that passes x to its argument
function func.thrush(x) return function(f) return f(x) end end

---Duplication function. W combinator. (a → a → b) → a → b
---@generic A, B
---@param f fun(x: A): fun(y: A): B Function to apply to duplicated argument
---@return fun(x: A): B Function that passes x twice to f
function func.join(f) return function(x) return func.c2(f)(x)(x) end end

---Flip arguments. C combinator. (a → b → c) → b → a → c
---@generic A, B, C
---@param f fun(x: A): fun(y: B): C Function whose arguments to flip
---@return fun(y: B): fun(x: A): C Function with flipped arguments
function func.flip(f) return function(y) return function(x) return func.c2(f)(x)(y) end end end

---Function composition. B combinator. (b → c) → (a → b) → a → c
---@generic A, B, C
---@param f fun(x: B): C Outer function
---@return fun(g: fun(x: A): B): fun(x: A): C Function that composes f with g
function func.comp(f) return function(g) return function(x) return f(g(x)) end end end

---Substitute combinator. S combinator. (a → b → c) → (a → b) → a → c
---@generic A, B, C
---@param f fun(x: A): fun(y: B): C Function to apply
---@return fun(g: fun(x: A): B): fun(x: A): C Function that applies f(x)(g(x))
function func.ap(f) return function(g) return function(x) return func.c2(f)(x)(g(x)) end end end

---Chain combinator. S_ combinator. (a → b → c) → (b → a) → b → c
---@generic A, B, C
---@param f fun(x: A): fun(y: B): C Function to chain
---@return fun(g: fun(y: B): A): fun(y: B): C Function that applies f(g(x))(x)
function func.chain(f) return function(g) return function(x) return func.c2(f)(g(x))(x) end end end

---Converge function. S2 combinator. (b → c → d) → (a → b) → (a → c) → a → d
---@generic A, B, C, D
---@param f fun(x: B): fun(y: C): D Function to apply to results
---@return fun(g: fun(x: A): B): fun(h: fun(x: A): C): fun(x: A): D Function that applies f(g(x))(h(x))
function func.lift2(f) return function(g) return function(h) return function(x) return func.c2(f)(g(x))(h(x)) end end end end

---Psi combinator. P combinator. (b → b → c) → (a → b) → a → a → c
---@generic A, B, C
---@param f fun(x: B): fun(y: B): C Function to apply to transformed values
---@return fun(g: fun(x: A): B): fun(x: A): fun(y: A): C Function that applies f(g(x))(g(y))
function func.on(f) return function(g) return function(x) return function(y) return func.c2(f)(g(x))(g(y)) end end end end

---@class Combinators
---@field id function Identity function
---@field const function Constant function
---@field apply function Apply function
---@field thrush function Thrush combinator
---@field join function Duplication function
---@field flip function Flip arguments
---@field comp function Function composition
---@field ap function Substitute combinator
---@field chain function Chain combinator
---@field lift2 function Converge function
---@field on function Psi combinator

-- Expose combinators at top level for easy access
func.combinators = {
    id = func.id,
    const = func.const,
    apply = func.apply,
    thrush = func.thrush,
    join = func.join,
    flip = func.flip,
    comp = func.comp,
    ap = func.ap,
    chain = func.chain,
    lift2 = func.lift2,
    on = func.on
}

-- ======================
-- CURRYING UTILITIES - Transform multi-argument functions into single-argument chains
-- ======================

---Curry a function with 1 argument (this is just function application)
---
---## Example:
---```lua
---local identity = func.c1(function(x) return x end)
---print(identity(42)) --> 42
---```
---@generic A, R
---@param f fun(x: A): R Function to curry
---@return fun(x: A): R Curried function
function func.c1(f) return function(x) return f(x) end end

---Curry a function with 2 arguments
---
---Transforms a function `f(x, y)` into `f(x)(y)` for partial application.
---
---## Example:
---```lua
---local add = func.c2(function(x, y) return x + y end)
---local add5 = add(5)
---print(add5(3)) --> 8
---print(add5(7)) --> 12
---```
---@generic A, B, R
---@param f fun(x: A, y: B): R Function to curry
---@return fun(x: A): fun(y: B): R Curried function
function func.c2(f) return function(x) return function(y) return f(x, y) end end end

---Curry a function with 3 arguments
---@generic A, B, C, R
---@param f fun(x: A, y: B, z: C): R Function to curry
---@return fun(x: A): fun(y: B): fun(z: C): R Curried function
function func.c3(f) return function(x) return function(y) return function(z) return f(x, y, z) end end end end

---Curry a function with 4 arguments
---@generic A, B, C, D, R
---@param f fun(x: A, y: B, z: C, a: D): R Function to curry
---@return fun(x: A): fun(y: B): fun(z: C): fun(a: D): R Curried function
function func.c4(f) return function(x) return function(y) return function(z) return function(a) return f(x, y, z, a) end end end end end

-- ======================
-- FUNCTION COMPOSITION & TRANSFORMATION
-- ======================

---Pack arguments into a table
---@vararg any Arguments to pack
---@return table Table containing the arguments and n field with count
function func.pack(...) return { n = select("#", ...), ... } end

---Generic compose with varargs
---@vararg function Functions to compose, rightmost is applied first
---@return function Composed function
function func.compose(...)
    -- Basic validation
    local args = func.pack(...)
    for i = 1, args.n do
        if type(args[i]) ~= 'function' then
            error("compose: argument #" .. i .. " is not a function", 2)
        end
    end

    local fnchain = { ... }

    -- Create the composed function
    local function recurse(i, ...)
        if i == 1 then return fnchain[i](...) end
        return recurse(i - 1, fnchain[i](...))
    end

    return function(...)
        return recurse(#fnchain, ...)
    end
end

---Safe function composition that catches errors at each step
---@vararg function Functions to compose safely
---@return function Composed function that returns Maybe<result>
function func.safe_compose(...)
    local fns = { ... }
    return function(x)
        local current = func.Maybe.just(x)
        for i = #fns, 1, -1 do
            current = func.Maybe.bind(function(val)
                return func.maybe_call(fns[i], val)
            end)(current)
        end
        return current
    end
end

---Compose with early termination on nil/false
---@vararg function Functions to compose with null checking
---@return function Composed function that stops on nil/false
function func.null_compose(...)
    local fns = { ... }
    return function(x)
        local current = x
        for i = #fns, 1, -1 do
            if current == nil or current == false then
                return current
            end
            current = fns[i](current)
        end
        return current
    end
end

---Fold left with varargs
---@generic A, B
---@param f fun(acc: A): fun(x: B): A Function to fold with
---@param init A Initial accumulator value
---@vararg B Values to fold over
---@return A Accumulated result
function func.foldl(f, init, ...)
    local acc = init
    local n = select("#", ...)
    for i = 1, n do
        acc = f(acc)(select(i, ...))
    end
    return acc
end

---Function composition in left-to-right (pipe) order
---@generic T, U
---@param ... fun(x: any): any[] Functions to pipe, leftmost is applied first
---@return fun(x: T): U Piped function
function func.pipe(...)
    local fns = { ... }
    return function(x)
        -- Use foldl to apply each function in sequence to the result
        return func.foldl(function(acc)
            return function(fn)
                return fn(acc)
            end
        end, x, unpack(fns))
    end
end

-- ======================
-- ARRAY OPERATIONS - Core functional array manipulations
-- ======================

---Map function over array elements
---@generic T, U
---@param f fun(x: T): U Function to apply to each element
---@param xs T[] Array to map over
---@return U[] Mapped array
function func.map(f, xs)
    checkType('Module:Functools.map', 1, f, 'function')
    checkType('Module:Functools.map', 2, xs, 'table')
    local result = {}
    for i, x in ipairs(xs) do
        result[i] = f(x)
    end
    return result
end

---Filter array elements based on predicate
---@generic T
---@param predicate fun(x: T): boolean Predicate function
---@param xs T[] Array to filter
---@return T[] Filtered array
function func.filter(predicate, xs)
    checkType('Module:Functools.filter', 1, predicate, 'function')
    checkType('Module:Functools.filter', 2, xs, 'table')
    local result = {}
    for _, x in ipairs(xs) do
        if predicate(x) then
            table.insert(result, x)
        end
    end
    return result
end

---Reduce array to single value (fold left)
---@generic T, U
---@param f fun(acc: U, x: T): U Reduction function
---@param init U Initial accumulator value
---@param xs T[] Array to reduce
---@return U Reduced value
function func.reduce(f, init, xs)
    checkType('Module:Functools.reduce', 1, f, 'function')
    checkType('Module:Functools.reduce', 3, xs, 'table')
    local acc = init
    for _, x in ipairs(xs) do
        acc = f(acc, x)
    end
    return acc
end

---Create table from two values
---@generic A, B
---@param a A First value
---@param b B Second value
---@return table<1, A, 2, B> Table containing both values
function func.to_table(a, b)
    return { a, b }
end

---Merge two tables (shallow copy)
---@generic T
---@param t1 T First table
---@param t2? table Second table (optional)
---@return T Merged table
function func.merge(t1, t2)
    checkType('Module:Functools.merge', 1, t1, 'table', true)
    checkType('Module:Functools.merge', 2, t2, 'table', true)
    local result = {}
    if t1 then
        for k, v in pairs(t1) do
            result[k] = v
        end
    end
    if t2 then
        for k, v in pairs(t2) do
            result[k] = v
        end
    end
    return result
end

-- ======================
-- SEQUENCE OPERATIONS - Working with sequences and collections
-- ======================

---Generate a range of numbers from start to stop
---@param start integer Starting number
---@param stop integer Ending number
---@return integer[] Array of numbers from start to stop
function func.range(start, stop)
    local result = {}
    for i = start, stop do
        result[i - start + 1] = i
    end
    return result
end

---Take n elements from sequence using purely functional approach
---@generic T
---@param n integer Number of elements to take
---@return fun(xs: T[]): T[] Function that returns first n elements of sequence
function func.take(n)
    return function(xs)
        -- Use functional approach: create range and map to elements
        local limit = math.min(n, #xs)
        if limit <= 0 then return {} end
        local indices = func.range(1, limit)
        return func.map(function(i) return xs[i] end, indices)
    end
end

---Drop n elements from sequence using purely functional approach
---@generic T
---@param n integer Number of elements to drop
---@return fun(xs: T[]): T[] Function that returns sequence without first n elements
function func.drop(n)
    return function(xs)
        -- Use functional approach: create range and map to elements
        if n >= #xs then return {} end
        local indices = func.range(n + 1, #xs)
        return func.map(function(i) return xs[i] end, indices)
    end
end

---@alias Pair<A,B> {[1]: A, [2]: B}
---@alias ArrayLike<T> {[integer]: T}

---Zip two arrays together into pairs
---@generic T, U
---@param xs ArrayLike<T> First array
---@param ys ArrayLike<U> Second array
---@return Pair<T,U>[] Array of pairs
function func.zip(xs, ys)
    local limit = math.min(#xs, #ys)
    if limit == 0 then return {} end

    -- Use range and map for pure functional approach
    local indices = func.range(1, limit)
    return func.map(function(i)
        return func.to_table(xs[i], ys[i])
    end, indices)
end

---Unzip an array of pairs into two arrays
---@generic T, U
---@param pairs table<integer, table<1, T, 2, U>> Array of pairs
---@return T[], U[] Two separate arrays
function func.unzip(pairs)
    local firsts, seconds = {}, {}
    for i, pair in ipairs(pairs) do
        firsts[i] = pair[1]
        seconds[i] = pair[2]
    end
    return firsts, seconds
end

---Create a function that partitions array based on predicate
---@generic T
---@param predicate fun(x: T): boolean Predicate function
---@return fun(xs: T[]): T[], T[] Function that returns true and false arrays
function func.partition(predicate)
    return function(xs)
        return func.filter(predicate, xs), func.filter(func.complement(predicate), xs)
    end
end

---Find first element matching predicate (functional search)
---@generic T
---@param predicate fun(x: T): boolean Predicate function
---@return fun(xs: T[]): T|nil Function that finds first matching element
function func.find(predicate)
    return function(xs)
        for _, x in ipairs(xs) do
            if predicate(x) then
                return x
            end
        end
        return nil
    end
end

---Apply function to each element for side effects (functional forEach)
---@generic T
---@param f fun(x: T): any Function to apply
---@return fun(xs: T[]): T[] Function that applies f to each element and returns original array
function func.each(f)
    return function(xs)
        for _, x in ipairs(xs) do
            f(x)
        end
        return xs -- Return original array for chaining
    end
end

---Reverse an array using functional approach
---@generic T
---@param xs T[] Array to reverse
---@return T[] Reversed array
function func.reverse(xs)
    local len = #xs
    if len <= 1 then return xs end
    local indices = func.range(len, 1) -- Create descending range
    return func.map(function(i) return xs[i] end, indices)
end

---Flatten nested arrays into a single array (one level deep)
---@generic T
---@param nested_array T[][]|T[] Array that may contain nested arrays
---@return T[] Flattened array
function func.flatten(nested_array)
    return func.foldl(function(acc)
        return function(item)
            if type(item) == "table" and type(item[1]) ~= nil then
                -- It's an array, concatenate its elements
                for i = 1, #item do
                    acc[#acc + 1] = item[i]
                end
            else
                -- It's a single element
                acc[#acc + 1] = item
            end
            return acc
        end
    end, {}, unpack(nested_array))
end

---Deep flatten nested arrays recursively
---@generic T
---@param nested_array any[] Array that may contain deeply nested arrays
---@return T[] Deeply flattened array
function func.deep_flatten(nested_array)
    local function is_array(item)
        return type(item) == "table" and (#item > 0 or next(item) == nil)
    end

    return func.foldl(function(acc)
        return function(item)
            if is_array(item) then
                -- Recursively flatten and append
                local flattened = func.deep_flatten(item)
                for i = 1, #flattened do
                    acc[#acc + 1] = flattened[i]
                end
            else
                acc[#acc + 1] = item
            end
            return acc
        end
    end, {}, unpack(nested_array))
end

-- ======================
-- PAIR & TUPLE UTILITIES - Working with paired data structures
-- ======================

---Returns the first element of a pair
---@generic A, B
---@param a A First element
---@param b B Second element
---@return A First element
function func.fst(a, b) return func.const(a)(b) end

---Returns the second element of a pair
---@generic A, B
---@param a A First element
---@param b B Second element
---@return B Second element
function func.snd(a, b) return func.flip(func.const)(a)(b) end

---Swaps the order of two arguments
---@generic A, B
---@param a A First element
---@return fun(b: B): {[1]: B, [2]: A} Function that returns swapped pair
function func.swap(a) return function(b) return b, a end end

---@class PairModule
---@field send_left function Apply function to left element of pair
---@field send_right function Apply function to right element of pair
---@field bimap function Apply functions to both elements of pair
---@field first function Get first element of pair
---@field second function Get second element of pair
---@field dbl function Create pair with same element twice
---@field make_pair function Create pair from two elements
---@field choose function Choose element from pair based on predicate
---@field pchoose function Curried choose function

-- More sophisticated pair manipulations
local pair = {}
func.pair = pair

---Apply function to left element of pair
---@generic A, B, C
---@param left_f fun(x: A): C Function to apply to left element
---@return fun(p: table): table Function that transforms pair
function pair.send_left(left_f) return function(pair) return func.to_table(left_f(pair[1]), pair[2]) end end

---Apply function to right element of pair
---@generic A, B, C
---@param right_f fun(x: B): C Function to apply to right element
---@return fun(p: table): table Function that transforms pair
function pair.send_right(right_f) return function(pair) return func.to_table(pair[1], right_f(pair[2])) end end

---Apply functions to both elements of pair
---@generic A, B, C, D
---@param left_f fun(x: A): C Function to apply to left element
---@param right_f fun(x: B): D Function to apply to right element
---@return fun(p: table): table Function that transforms both elements
function pair.bimap(left_f, right_f) return func.compose(pair.send_left(left_f), pair.send_right(right_f)) end

---Get first element of pair
---@generic A, B
---@param p table<1, A, 2, B> Pair as table
---@return A First element
function pair.first(p) return p[1] end

---Get second element of pair
---@generic A, B
---@param p table<1, A, 2, B> Pair as table
---@return B Second element
function pair.second(p) return p[2] end

---Create pair with same element twice
---@generic T
---@return table<1, T, 2, T> Pair with duplicated value
pair.dbl = func.join(func.to_table)

---Create pair from two elements
---@generic A, B
---@param a A First element
---@param b B Second element
---@return table<1, A, 2, B> Pair as table
function pair.make_pair(a, b) return func.to_table(a, b) end

---Choose element from pair based on predicate
---@generic T
---@param pred boolean Predicate to determine which element to choose
---@param p table<1, T, 2, T> Pair of elements
---@return T Chosen element
function pair.choose(pred, p) if pred then return pair.first(p) else return pair.second(p) end end

---Curried choose function
---@generic T
---@param p table<1, T, 2, T> Pair of elements
---@return fun(pred: boolean): T Function that chooses element based on predicate
function pair.pchoose(p) return function(pred) return pair.choose(pred, p) end end

-- ======================
-- MAYBE MONAD - Safe computation handling
-- ======================

---@class Maybe<any>
---@field value any|nil The contained value
---@field isNothing boolean Whether this Maybe is Nothing

-- Initialize Maybe namespace
func.Maybe = {}

---Create a Maybe containing a value (Just)
---@generic T
---@param value T Value to wrap
---@return Maybe<T> Maybe containing the value
function func.Maybe.just(value)
    return {
        value = value,
        isNothing = false
    }
end

---Create an empty Maybe (Nothing)
---@generic T
---@return Maybe<T> Empty Maybe
func.Maybe.nothing = {
    value = nil,
    isNothing = true
}

---Check if Maybe contains a value
---@generic T
---@param maybe Maybe<T> Maybe to check
---@return boolean hasValue Whether Maybe contains a value
function func.Maybe.isJust(maybe)
    return maybe and not maybe.isNothing and maybe.value ~= nil
end

---Check if Maybe is Nothing
---@generic T
---@param maybe Maybe<T> Maybe to check
---@return boolean isEmpty Whether Maybe is Nothing
function func.Maybe.isNothing(maybe)
    return not maybe or maybe.isNothing or maybe.value == nil
end

-- Improve function signatures to better specify Maybe types
---@generic T, U
---@param f fun(x: T): U Function to map
---@return fun(m: Maybe<T>): Maybe<U> Function that maps over Maybe
function func.Maybe.map(f)
    return function(m)
        if func.Maybe.isJust(m) then
            return func.Maybe.just(f(m.value))
        else
            return func.Maybe.nothing
        end
    end
end

---Monadic bind operation for Maybe (flatMap)
---@generic T, U
---@param f fun(x: T): Maybe<U> Function that returns a Maybe
---@return fun(m: Maybe<T>): Maybe<U> Function that binds over Maybe
function func.Maybe.bind(f)
    return function(m)
        if func.Maybe.isJust(m) then
            return f(m.value)
        else
            return func.Maybe.nothing
        end
    end
end

---Apply a function inside Maybe to a value inside Maybe (applicative)
---@generic T, U
---@param mf Maybe<fun(x: T): U> Maybe containing a function
---@return fun(mx: Maybe<T>): Maybe<U> Function that applies Maybe function to Maybe value
function func.Maybe.ap(mf)
    return function(mx)
        return func.Maybe.bind(function(f)
            return func.Maybe.map(f)(mx)
        end)(mf)
    end
end

---Lift a binary function to work with Maybe values
---@generic T, U, V
---@param f fun(x: T): fun(y: U): V Binary function to lift
---@return fun(mx: Maybe<T>): fun(my: Maybe<U>): Maybe<V> Lifted function
function func.Maybe.lift2(f)
    return function(mx)
        return function(my)
            return func.Maybe.ap(func.Maybe.map(f)(mx))(my)
        end
    end
end

---Get value from Maybe with default
---@generic T
---@param default T Default value to use if Maybe is Nothing
---@return fun(m: Maybe<T>): T Function that extracts value or returns default
function func.Maybe.fromMaybe(default)
    return function(m)
        if func.Maybe.isJust(m) then
            return m.value
        else
            return default
        end
    end
end

-- Short aliases for common operations
func.getOrElse = func.Maybe.fromMaybe
-- ======================
-- MATHEMATICAL OPERATIONS - Numeric and comparison operation
-- ======================

---@class Operations
func.ops = {}

--Addition operation
---@param a number First number
---@param b number Second number
---@return number Sum
function func.ops.add(a, b)
    return a + b
end

---Multiplication operation
---@param a number First number
---@param b number Second number
---@return number Product
function func.ops.mul(a, b)
    return a * b
end

---Subtraction operation
---@param a number First number
---@param b number Second number
---@return number Difference
function func.ops.sub(a, b)
    return a - b
end

---Division operation
---@param a number First number
---@param b number Second number
---@return number Quotient
function func.ops.div(a, b)
    if b == 0 then
        error("Division by zero", 2)
    end
    return a / b
end

---Modulo operation
---@param a number First number
---@param b number Second number
---@return number Remainder
function func.ops.mod(a, b)
    return a % b
end

---Power operation
---@param a number Base
---@param b number Exponent
---@return number Result
function func.ops.pow(a, b)
    return a ^ b
end

---Equality comparison
---@param a any First value
---@param b any Second value
---@return boolean Equal
function func.ops.eq(a, b)
    return a == b
end

---Less than comparison
---@param a any First value
---@param b any Second value
---@return boolean Less than
function func.ops.lt(a, b)
    return a < b
end

---Greater than comparison
---@param a any First value
---@param b any Second value
---@return boolean Greater than
function func.ops.gt(a, b)
    return a > b
end

-- ======================
-- MEMOIZATION & RECURSION - Performance optimization and recursive utilities
-- ======================

---Memoize a function for single argument
---@generic A, B
---@param f fun(x: A): B Function to memoize
---@return fun(x: A): B Memoized function
function func.memoize(f)
    local cache = {}
    return function(x)
        local key = tostring(x)
        if cache[key] == nil then
            cache[key] = f(x)
        end
        return cache[key]
    end
end

---Add trampolining for stack safety in recursive calls with functional improvements
---@generic A, R
---@param f fun(...: A): R|function Function that may return another function for trampolining
---@return fun(...: A): R Function with trampolining applied
function func.trampoline(f)
    return function(...)
        -- Use a functional approach to repeatedly apply until we get a non-function result
        local result = f(...)
        local continue = function(r) return type(r) == "function" end

        while continue(result) do
            result = result()
        end
        return result
    end
end

---Functional until combinator - repeatedly apply function until predicate is true
---@generic T
---@param predicate fun(x: T): boolean Predicate to test
---@param transform fun(x: T): T Function to apply
---@return fun(x: T): T Function that applies transform until predicate is true
function func.until_fn(predicate, transform)
    return function(initial)
        local current = initial
        while not predicate(current) do
            current = transform(current)
        end
        return current
    end
end

---Functional while combinator - repeatedly apply function while predicate is true
---@generic T
---@param predicate fun(x: T): boolean Predicate to test
---@param transform fun(x: T): T Function to apply
---@return fun(x: T): T Function that applies transform while predicate is true
function func.while_fn(predicate, transform)
    return func.until_fn(func.complement(predicate), transform)
end

---Fixed-point combinator (Y combinator approximation)
---@generic T, R
---@param f fun(rec: fun(x: T): R): fun(x: T): R Function that takes its own recursive call
---@return fun(x: T): R Recursive function
function func.fix(f)
    checkType('Module:Functools.fix', 1, f, 'function')
    local function rec(...)
        return f(rec)(...)
    end
    return rec
end

-- ======================
-- UTILITY FUNCTIONS & PREDICATES - General purpose utilities and type checks
-- ======================

---Check if value is empty (nil, empty string, or empty table)
---@param value any Value to check
---@return boolean True if empty
function func.is_empty(value)
    if value == nil or value == "" then
        return true
    end
    if type(value) == "table" then
        return next(value) == nil
    end
    return false
end

---Deep clone a table
---@generic T
---@param obj T Table to clone
---@return T Cloned table
function func.deep_clone(obj)
    return func.fix(function(self)
        return function(x)
            if type(x) ~= "table" then return x end
            local result = {}
            for k, v in pairs(x) do
                result[self(k)] = self(v)
            end
            return setmetatable(result, getmetatable(x))
        end
    end)(obj)
end

---Complement a predicate function
---@generic T
---@param predicate fun(x: T): boolean Predicate to complement
---@return fun(x: T): boolean Complemented predicate
function func.complement(predicate)
    return function(x)
        return not predicate(x)
    end
end

---Create a predicate that checks if value is in list
---@generic T
---@param list T[] List of values to check against
---@return fun(x: T): boolean Predicate function
function func.contains_in(list)
    local lookup = {}
    for _, v in ipairs(list) do
        lookup[v] = true
    end
    return function(x)
        return lookup[x] == true
    end
end

---Check if input has specific type
---@param type_name string Type name to check
---@return fun(value: any): boolean Predicate that checks if value is of specified type
function func.is_type(type_name)
    return function(value)
        return type(value) == type_name
    end
end

-- Create common type predicates
func.is_function = func.is_type("function")
func.is_table = func.is_type("table")
func.is_string = func.is_type("string")
func.is_number = func.is_type("number")
func.is_boolean = func.is_type("boolean")

-- ======================
-- ADVANCED UTILITIES - Lenses and Transducers
-- ======================

---Create a lens for functional data access and modification
---@generic S, A
---@param getter fun(s: S): A Function to get value from structure
---@param setter fun(a: A): fun(s: S): S Function to set value in structure
---@return table<string, function> Lens object with get, set, and modify operations
function func.lens(getter, setter)
    return {
        get = getter,
        set = setter,
        modify = function(f)
            return function(s)
                return setter(f(getter(s)))(s)
            end
        end
    }
end

---Focus on a specific key in a table (lens for table access)
---@generic K, V
---@param key K Key to focus on
---@return table<string, function> Lens for table access
function func.prop_lens(key)
    return func.lens(
        function(obj) return obj[key] end,
        function(value)
            return function(obj)
                local result = func.merge(obj) -- Copy the object
                result[key] = value
                return result
            end
        end
    )
end

---Curried lens get operation
---@generic S, A
---@param lens table<string, function> Lens object
---@return fun(s: S): A Function that gets value using lens
function func.view(lens)
    return lens.get
end

---Curried lens set operation
---@generic S, A
---@param lens table<string, function> Lens object
---@param value A Value to set
---@return fun(s: S): S Function that sets value using lens
function func.set(lens, value)
    return lens.set(value)
end

---Curried lens modify operation
---@generic S, A
---@param lens table<string, function> Lens object
---@param f fun(a: A): A Function to modify value
---@return fun(s: S): S Function that modifies value using lens
function func.over(lens, f)
    return lens.modify(f)
end

---@alias Reducer<A,B> fun(acc: A, input: B): A
---@alias Transducer<A,B,C> fun(reducer: Reducer<A,B>): Reducer<A,C>

---Create a transducer for efficient composition of map/filter operations
---@generic A, B, C
---@param xform fun(reducer: Reducer<A,B>): Reducer<A,C> Transformation function
---@return Transducer<A,B,C> Transducer function
function func.transducer(xform)
    return function(reducer)
        return xform(reducer)
    end
end

---Map transducer
---@generic T, U
---@param f fun(x: T): U Mapping function
---@return function Map transducer
function func.map_t(f)
    return func.transducer(function(reducer)
        return function(acc, input)
            return reducer(acc, f(input))
        end
    end)
end

---Filter transducer
---@generic T
---@param predicate fun(x: T): boolean Predicate function
---@return function Filter transducer
function func.filter_t(predicate)
    return func.transducer(function(reducer)
        return function(acc, input)
            if predicate(input) then
                return reducer(acc, input)
            else
                return acc
            end
        end
    end)
end

---Compose transducers for efficient pipeline processing
---@vararg function Transducers to compose
---@return function Composed transducer
function func.compose_t(...)
    local transducers = { ... }
    return function(reducer)
        -- Apply transducers right to left (like function composition)
        local composed_reducer = reducer
        for i = #transducers, 1, -1 do
            composed_reducer = transducers[i](composed_reducer)
        end
        return composed_reducer
    end
end

-- ======================
-- SAFE OPERATIONS & ERROR HANDLING - Defensive programming utilities
-- ======================

---Safe function call with error handling
---@generic T
---@param f function Function to call safely
---@param ... any Arguments to pass
---@return boolean, T Success flag and result/error
function func.safe_call(f, ...)
    return pcall(f, ...)
end

---Maybe-style safe call
---@generic T
---@param f function Function to call
---@param ... any Arguments
---@return Maybe<T> Result wrapped in Maybe
function func.maybe_call(f, ...)
    local success, result = pcall(f, ...)
    if success then
        return func.Maybe.just(result)
    else
        return func.Maybe.nothing
    end
end

---Chain safe operations
---@generic T
---@param operations function[] Array of functions to chain
---@return function Chained safe operation
function func.chain_safe(operations)
    checkType('Module:Functools.chain_safe', 1, operations, 'table')
    return function(initial_value)
        return func.foldl(function(acc)
            return function(op)
                return func.Maybe.bind(op)(acc)
            end
        end, func.Maybe.just(initial_value), unpack(operations))
    end
end

-- ======================
-- VALIDATION MODULE - Input validation and type checking
-- ======================

---@class Validation
func.validation = {}

---Validate a value against rules
---@param value any Value to validate
---@param rules table Validation rules
---@return boolean|string True if valid, error message if invalid
function func.validation.validate_value(value, rules)
    if rules.required and (value == nil or value == "") then
        return "Value is required"
    end
    if rules.type and type(value) ~= rules.type then
        return string.format("Expected %s, got %s", rules.type, type(value))
    end
    if rules.min and type(value) == "number" and value < rules.min then
        return string.format("Value must be at least %s", rules.min)
    end
    if rules.max and type(value) == "number" and value > rules.max then
        return string.format("Value must be at most %s", rules.max)
    end
    return true
end

---Validate options against rule set
---@param options table Options to validate
---@param rules table Rule set
---@return string|nil Error message or nil if valid
function func.validation.validate_options(options, rules)
    for key, rule in pairs(rules) do
        local value = options[key]
        local result = func.validation.validate_value(value, rule)
        if result ~= true then
            return string.format("%s: %s", key, result)
        end
    end
    return nil
end

---Return default value if input is nil/empty
---@generic T
---@param value T|nil Input value
---@param default T Default value
---@return T Value or default
function func.validation.default_value(value, default)
    if value == nil or value == "" then
        return default
    end
    return value
end

-- ======================
-- CURRIED CONVENIENCE FUNCTIONS - Easy-to-use curried versions
-- ======================

-- Curried versions with 'p' prefix (partial application)
func.pmap = func.c2(func.map)
func.pfilter = func.c2(func.filter)
func.preduce = func.c3(func.reduce)

-- Curried operations
func.add = func.c2(func.ops.add)
func.mul = func.c2(func.ops.mul)
func.sub = func.c2(func.ops.sub)
func.div = func.c2(func.ops.div)
func.mod = func.c2(func.ops.mod)
func.pow = func.c2(func.ops.pow)
func.eq = func.c2(func.ops.eq)
func.lt = func.c2(func.ops.lt)
func.gt = func.c2(func.ops.gt)

-- Using thrush combinator for flip application
func.tap = func.flip(func.apply)

-- Using flip and composition for property access
func.prop = func.flip(func.comp(func.id))

-- Using currying for simplified versions
func.add1 = func.add(1)
func.sub1 = func.flip(func.sub)(1)
func.double = func.mul(2)
func.negate = func.mul(-1)

func.not_empty = func.complement(func.is_empty)
func.is_nil = function(x) return x == nil end
func.not_nil = func.complement(func.is_nil)
func.is_array = function(x) return type(x) == "table" and #x > 0 end

-- Curried sequence operations
func.pzip = func.c2(func.zip)

-- ======================
-- MODULE EXPORT
-- ======================

return func
