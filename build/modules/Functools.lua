--[[ Functools
Provides purely functional programming utilities, combinators, and function composition tools.
--]]
local arr = require('Module:Array')
local checkType = require( 'libraryUtil' ).checkType

local func = {}

-- ======================
-- CURRYING UTILITIES
-- ======================

-- Curry f with 1 arg (this is just function application)
function func.c1(f) return function(x) return f(x) end end	
-- Curry with 2 args
function func.c2(f) return function(x) return function(y) return f(x,y) end end end
-- Curry with 3 args
function func.c3(f) return function(x) return function(y) return function(z) return f(x,y,z) end end end end
-- Curry with 4 args
function func.c4(f) return function(x) return function(y) return function(z) return function(a) return f(x,y,z,a) end end end end end

-- ======================
-- COMBINATORS - Pure Functional Programming
-- ======================

-- Identity. I combinator. a -> a
function func.id(x) return x end
-- Constant. K combinator. a -> b -> a
function func.const(x) return function (y) return x end end
-- Apply. A combinator. (a -> b) -> a -> b
function func.apply(f) return function (x) return f(x) end end
-- Thrush. T combinator. a -> (a -> b) -> b
function func.thrush(x) return function (f) return f(x) end end
-- Duplication. W combinator. (a → a → b) → a → b
function func.join(f) return function (x) return func.c2(f)(x)(x) end end
-- Flips. C combinator. (a → b → c) → b → a → c
function func.flip(f) return function (y) return function (x) return func.c2(f)(x)(y) end end end
-- Compose. B combinator. (b → c) → (a → b) → a → c
function func.comp(f) return function (g) return function (x) return f(g(x)) end end end
-- Substitute. S combinator. (a → b → c) → (a → b) → a → c
function func.ap(f) return function (g) return function (x) return func.c2(f)(x)(g(x)) end end end
-- Chain. S_ combinator. (a → b → c) → (b → a) → b → c
function func.chain(f) return function (g) return function (x) return func.c2(f)(g(x))(x) end end end
-- Converge (liftA2/liftM2). S2 combinator. (b → c → d) → (a → b) → (a → c) → a → d
function func.lift2(f) return function (g) return function (h) return function (x) return func.c2(f)(g(x))(h(x)) end end end end
-- Psi. P combinator. (b → b → c) → (a → b) → a → a → c
function func.on(f) return function (g) return function (x) return function (y) return func.c2(f)(g(x))(g(y)) end end end end

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

-- Pack arguments into a table. Native in Lua 5.2+, but keeping for backward compatibility
function func.pack(...) return { n = select("#", ...), ... } end

-- Generic compose with varargs.
function func.compose(...)
    local args = func.pack(...)
    for i=1,args.n do checkType('compose', i, args[i], 'function') end
    local fnchain = { ... }
    local function recurse(i, ...)
      if i == 1 then return fnchain[i](...) end
      return recurse(i - 1, fnchain[i](...))
    end
    return function(...) return recurse(#fnchain, ...) end
end

-- Fold left with varargs
function func.foldl(f, init, ...)
    local acc = init
    local n = select("#", ...)  -- Get the number of varargs
    for i = 1, n do
        acc = f(acc)(select(i, ...)) 
    end
    return acc
end

-- Function composition in left-to-right (pipe) order
function func.pipe(...)
    local fns = {...}
    return function(x)
        local result = x
        for i = 1, #fns do
            result = fns[i](result)
        end
        return result
    end
end

-- ======================
-- PAIR & TUPLE UTILITIES
-- ======================

-- Returns the first element of a pair.
function func.fst(a, b) return func.const(a)(b) end
-- Returns the second element of a pair.
function func.snd(a, b) return func.flip(func.const)(a)(b) end
-- Swaps the order of two arguments.
function func.swap(a) return function (b) return b, a end end

-- More sophisticated pair manipulations
local pair = {}
func.pair = pair
-- Curry these by default. These, importantly, are based on tables, unlike fst and snd above.
function pair.send_left(left_f) return function(pair) return {left_f(pair[1]), pair[2]} end end
function pair.send_right(right_f) return function(pair) return {pair[1], right_f(pair[2])} end end
function pair.bimap(left_f, right_f) return func.compose(pair.send_left(left_f), pair.send_right(right_f)) end
function pair.first(p) return p[1] end
function pair.second(p) return p[2] end
pair.dbl = func.join(func.to_table)
function pair.make_pair(a,b) return func.to_table(a,b) end
-- bool -> Pair(a) -> a
function pair.choose(pred, p) if pred then return pair.first(p) else return pair.second(p) end end
-- Pair(a) -> bool -> a
function pair.pchoose(p) return function (pred) return pair.choose(pred, p) end end

-- ======================
-- TABLE MANIPULATION
-- ======================

-- Creates and returns a new table with all of the named args from table 1 and table 2. Overwrites in table 1.
local function merge_pairs(t1)
	return function (t2)
		local result = {}
	    for key, value in pairs(t1) do result[key] = value end
	    for key, value in pairs(t2) do result[key] = value end
	    return result
	end
end

-- General case with a specified accumulator
function func.merge_to(acc, ...)
	local n_args = select("#", ...)
	if n_args == 0 then return acc
	else return func.foldl(merge_pairs, acc, ...) 
	end
end

-- Immutable-merges any number of tables. Overwrites cascade from the right side.
function func.merge(...)
	return func.merge_to({}, ...)
end

function func.to_table(...) return {...} end

-- ======================
-- HIGHER-ORDER FUNCTIONS
-- ======================

-- Assumes curried predicate and action
function func.reducer(action, predicate)
    return function (elem, acc)
        if predicate(elem)(acc) then return action(elem)(acc) end
        return acc
    end
end

-- Concatenation reduce pattern
function func.concatter(predicate)
    return func.reducer(func.flip(arr.insert), predicate)
end

-- Selection reduce pattern
function func.selector(predicate)
    return func.reducer(func.const, predicate)
end

-- Flip + curry for maps, anys, finds, etc
function func.flip_and_curry(across_fn) 
    return function (send_fn) 
        return function (array) 
            return func.flip(func.c2(across_fn))(send_fn)(array) 
        end 
    end 
end

-- ======================
-- OPERATORS & ARITHMETICS
-- ======================

-- Operators
local ops = {}
func.ops = ops
function ops.div(a, b) return a/b end
function ops.mult(a, b) return a*b end
function ops._or(a, b) return a or b end
function ops.append(a, b) return tostring(a) .. tostring(b) end

function func.fold_op(p_operator, init) 
    return function(q) 
        return func.foldl(p_operator, init, table.unpack(q)) 
    end 
end

function func.fold_div(q) return ops.div(table.unpack(q)) end
ops.pmult = func.c2(ops.mult)
func.fold_mult = func.fold_op(ops.pmult, 1)
ops.por = func.c2(ops._or)
func.fold_or = func.fold_op(ops.por, false)
ops.pappend = func.c2(ops.append)
func.fold_append = func.fold_op(ops.pappend, "")

-- ======================
-- ARRAY FUNCTIONS
-- ======================

-- Map and partialed map
function func.map(f, list) return arr.map(list, f) end
func.pmap = func.c2(func.map)
-- Filter and partialed filter
function func.filter(f, list) return arr.filter(list, f) end
func.pfilter = func.c2(func.filter)
-- Get and partialed get. For use in filters + finds (point-free; expects an object)
function func.get(attr, obj) return obj[attr] end
func.pget = func.c2(func.get)
-- Table concat and partially applied form
function func.concat(concat_str, tbl) return table.concat(tbl, concat_str) end
func.pconcat = func.c2(func.concat)

-- ======================
-- SAFE FUNCTION UTILITIES
-- ======================

-- Safe function call wrapper
function func.safe_call(fn, operation_name, args)
    local success, result = pcall(function()
        if type(args) == 'table' then
            return fn(table.unpack(args))
        else
            return fn(args)
        end
    end)

    if not success then
        return success, ("Error in " .. operation_name .. ": " .. tostring(result))
    end

    return success, result
end

-- Chain functions with error handling
function func.maybe_call(fn, name, args, default)
    local success, result = func.safe_call(fn, name, args)
    return success and result or default
end

-- Chain multiple transformations, handling nil/error cases
function func.chain_safe(...)
    local fns = {...}
    return function(value)
        return arr.reduce(fns, value, function(result, fn)
            if not result then return result end
            return fn(result)
        end)
    end
end

-- ======================
-- VALIDATION UTILITIES - Pure Functional
-- ======================

-- Import paramtest utilities
local paramtest = require('Module:Paramtest')

-- Validation utilities
local validation = {}
func.validation = validation

---Validate a single value against rules
---@param value any Value to validate
---@param rules table Rules to validate against
---@return boolean valid Whether validation passed
---@return string|nil error Error message if validation failed
function validation.validate_value(value, rules)
    -- Create validation chain
    local validations = {}

    -- Required check
    if rules.required then
        table.insert(validations, function(val)
            -- For strings, check if they have content using paramtest
            if type(val) == "string" then
                if not paramtest.has_content(val) then
                    return false, string.format("Field %s is required and must not be empty", rules.name or "unknown")
                end
            -- For tables, check if they have content
            elseif type(val) == "table" then
                if not paramtest.table_has_content(val) then
                    return false, string.format("Field %s is required and must not be empty", rules.name or "unknown")
                end
            -- For other types, just check if nil
            elseif val == nil then
                return false, string.format("Field %s is required", rules.name or "unknown")
            end
            return true
        end)
    end

    -- Skip remaining checks if value is nil
    if value == nil then return true end

    -- Type check
    if rules.type then
        table.insert(validations, function(val)
            local value_type = type(val)
            if value_type ~= rules.type then
                return false, string.format(
                    "Invalid type for %s: expected %s, got %s",
                    rules.name or "unknown",
                    rules.type,
                    value_type
                )
            end
            return true
        end)
    end

    -- Run all validations
    for _, validate in ipairs(validations) do
        local valid, err = validate(value)
        if not valid then
            return false, err
        end
    end

    return true
end

---Validate a table of options against rules
---@param options table Table of options to validate
---@param rules table Table of validation rules
---@return string|nil error Error message if validation fails
function validation.validate_options(options, rules)
    for field, rules in pairs(rules) do
        -- Allow string shorthand for required type checking
        if type(rules) == "string" then
            rules = {type = rules, required = true}
        end

        -- Add field name to rules
        rules.name = rules.name or field

        -- Validate value
        local valid, err = validation.validate_value(options[field], rules)
        if not valid then
            return err
        end
    end

    return nil
end

---Default value helper utilizing paramtest
---@param value any Value to check
---@param default any Default value to use if value is empty/nil
---@return any The value or default
function validation.default_value(value, default)
    if type(value) == "string" then
        return paramtest.default_to(value, default)
    elseif type(value) == "table" then
        return paramtest.table_has_content(value) and value or default
    else
        return value ~= nil and value or default
    end
end

return func
