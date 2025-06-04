--[[ Functools - Enhanced MediaWiki Functional Programming Library
Provides purely functional programming utilities, combinators, and function composition tools.

## Key Features:
- **Currying**: Transform multi-argument functions into single-argument chains
- **Combinators**: Classic functional programming combinators (SKI, B, C, etc.)
- **Function Composition**: Pipe and compose operations for function chaining
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
]]

local arr = require('Array')
local checkType = libraryUtil.checkType

-- Compatibility layer for different Lua versions
---@diagnostic disable-next-line: deprecated
local unpack = unpack or table.unpack  -- Use the global unpack in Lua 5.1, table.unpack in 5.2+

---@class Functools
local func = {}

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
function func.c2(f) return function(x) return function(y) return f(x,y) end end end

---Curry a function with 3 arguments
---@generic A, B, C, R
---@param f fun(x: A, y: B, z: C): R Function to curry
---@return fun(x: A): fun(y: B): fun(z: C): R Curried function
function func.c3(f) return function(x) return function(y) return function(z) return f(x,y,z) end end end end

---Curry a function with 4 arguments
---@generic A, B, C, D, R
---@param f fun(x: A, y: B, z: C, a: D): R Function to curry
---@return fun(x: A): fun(y: B): fun(z: C): fun(a: D): R Curried function
function func.c4(f) return function(x) return function(y) return function(z) return function(a) return f(x,y,z,a) end end end end end

-- ======================
-- COMBINATORS - Pure Functional Programming
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
function func.const(x) return function (y) return x end end

---Apply function. A combinator. (a -> b) -> a -> b
---@generic A, B
---@param f fun(x: A): B Function to apply
---@return fun(x: A): B Function that applies f to its argument
function func.apply(f) return function (x) return f(x) end end

---Thrush combinator. T combinator. a -> (a -> b) -> b
---@generic A, B
---@param x A Value to pass to function
---@return fun(f: fun(x: A): B): B Function that passes x to its argument
function func.thrush(x) return function (f) return f(x) end end

---Duplication function. W combinator. (a → a → b) → a → b
---@generic A, B
---@param f fun(x: A): fun(y: A): B Function to apply to duplicated argument
---@return fun(x: A): B Function that passes x twice to f
function func.join(f) return function (x) return func.c2(f)(x)(x) end end

---Flip arguments. C combinator. (a → b → c) → b → a → c
---@generic A, B, C
---@param f fun(x: A): fun(y: B): C Function whose arguments to flip
---@return fun(y: B): fun(x: A): C Function with flipped arguments
function func.flip(f) return function (y) return function (x) return func.c2(f)(x)(y) end end end

---Function composition. B combinator. (b → c) → (a → b) → a → c
---@generic A, B, C
---@param f fun(x: B): C Outer function
---@return fun(g: fun(x: A): B): fun(x: A): C Function that composes f with g
function func.comp(f) return function (g) return function (x) return f(g(x)) end end end

---Substitute combinator. S combinator. (a → b → c) → (a → b) → a → c
---@generic A, B, C
---@param f fun(x: A): fun(y: B): C Function to apply
---@return fun(g: fun(x: A): B): fun(x: A): C Function that applies f(x)(g(x))
function func.ap(f) return function (g) return function (x) return func.c2(f)(x)(g(x)) end end end

---Chain combinator. S_ combinator. (a → b → c) → (b → a) → b → c
---@generic A, B, C
---@param f fun(x: A): fun(y: B): C Function to chain
---@return fun(g: fun(y: B): A): fun(y: B): C Function that applies f(g(x))(x)
function func.chain(f) return function (g) return function (x) return func.c2(f)(g(x))(x) end end end

---Converge function. S2 combinator. (b → c → d) → (a → b) → (a → c) → a → d
---@generic A, B, C, D
---@param f fun(x: B): fun(y: C): D Function to apply to results
---@return fun(g: fun(x: A): B): fun(h: fun(x: A): C): fun(x: A): D Function that applies f(g(x))(h(x))
function func.lift2(f) return function (g) return function (h) return function (x) return func.c2(f)(g(x))(h(x)) end end end end

---Psi combinator. P combinator. (b → b → c) → (a → b) → a → a → c
---@generic A, B, C
---@param f fun(x: B): fun(y: B): C Function to apply to transformed values
---@return fun(g: fun(x: A): B): fun(x: A): fun(y: A): C Function that applies f(g(x))(g(y))
function func.on(f) return function (g) return function (x) return function (y) return func.c2(f)(g(x))(g(y)) end end end end

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
    for i=1, args.n do
        if type(args[i]) ~= 'function' then
            error("compose: argument #" .. i .. " is not a function", 2)
        end
    end

    local fnchain = { ... }

    -- Performance measurement can be added here if needed
    local startTime = os.clock()

    -- Create the composed function
    local function recurse(i, ...)
        if i == 1 then return fnchain[i](...) end
        return recurse(i - 1, fnchain[i](...))
    end

    return function(...)
        return recurse(#fnchain, ...)
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
---@vararg function Functions to pipe, leftmost is applied first
---@return function Piped function
function func.pipe(...)
    local fns = {...}
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
-- PAIR & TUPLE UTILITIES
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
function func.swap(a) return function (b) return b, a end end

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
function pair.make_pair(a,b) return func.to_table(a,b) end

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
function pair.pchoose(p) return function (pred) return pair.choose(pred, p) end end

-- ======================
-- SEQUENCE OPERATIONS
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
---@return fun(xs: T[]): T[] Function we've athat returns sequence without first n elements
function func.drop(n)
    return function(xs)
        -- Use functional approach: create range and map to elements
        if n >= #xs then return {} end
        local indices = func.range(n + 1, #xs)
        return func.map(function(i) return xs[i] end, indices)
    end
end

-- ======================
-- MEMOIZATION & RECURSION
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
    return func.until_fn(func.compose(function(x) return not x end, predicate), transform)
end

---Zip two arrays together into pairs
---@generic T, U
---@param xs T[] First array
---@param ys U[] Second array
---@return table<integer, table<1, T, 2, U>> Array of pairs
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
        local truthy, falsy = {}, {}
        func.foldl(function(acc)
            return function(x)
                if predicate(x) then
                    table.insert(truthy, x)
                else
                    table.insert(falsy, x)
                end
                return acc
            end
        end, nil, unpack(xs))
        return truthy, falsy
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
        return xs  -- Return original array for chaining
    end
end

---Reverse an array using functional approach
---@generic T
---@param xs T[] Array to reverse
---@return T[] Reversed array
function func.reverse(xs)
    local len = #xs
    if len <= 1 then return xs end
    local indices = func.range(len, 1)  -- Create descending range
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
-- ENHANCED MAYBE MONAD
-- ======================

---@class Maybe<T>
---@field value T|nil The contained value
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

---Map a function over Maybe value
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
        if func.Maybe.isJust(mf) and func.Maybe.isJust(mx) then
            return func.Maybe.just(mf.value(mx.value))
        else
            return func.Maybe.nothing
        end
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

-- ======================
-- ADVANCED COMBINATORS & UTILITIES
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

---Fixed-point combinator (Y combinator approximation)
---@generic T, R
---@param f fun(rec: fun(x: T): R): fun(x: T): R Function that takes its own recursive call
---@return fun(x: T): R Recursive function
function func.fix(f)
    local function rec(...)
        return f(rec)(...)
    end
    return rec
end

---Create a transducer for efficient composition of map/filter operations
---@generic T, U
---@param xform fun(reducer: function): function Transformation function
---@return function Transducer function
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
    local transducers = {...}
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
-- CURRIED VERSIONS OF REMAINING OPERATIONS
-- ======================

---Curried zip function
---@generic T, U
---@param xs T[] First array
---@return fun(ys: U[]): table<integer, table<1, T, 2, U>> Function that zips with second array
func.pzip = func.c2(func.zip)

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

-- ======================
-- MODULE EXPORT
-- ======================

return func