require("strict")
require('Module:Mw.html extension')

local p = {}
local arr = require('Array')
local plink = require('Plink')._plink
local coins = require('Currency')._coins
local get_calcvalue = require('Calcvalue')._get
local round = require('Number')._round
local default = require('Paramtest').default_to
local ttools = require('TableTools')
local add_table = require('Tables')._table
local f = require('Functools')
local partial, compose = f.c2, f.compose
local map, pmap, pfilter, pget, pconcat = f.map, f.pmap, f.pfilter, f.prop, f.pconcat
local append, pmult = f.ops.ap, f.mul
local fold_div, fold_or, fold_append = f.fold_div, f.fold_or, f.fold_append
local first, second, bimap, send_right, dbl, ifThenElse, pifThenElse = f.pair.first, f.pair.second, f.pair.bimap,
    f.pair.send_right, f.pair.dbl, f.pair.choose, f.pair.pchoose
local id, thrush = f.combinators.id, f.combinators.thrush

local usage_data = require('Module:UsageCost/data')
local DIVINE_CHARGE_SLOTS = usage_data.DIVINE_CHARGE_SLOTS
local COMBAT_RATES = usage_data.COMBAT_RATES
local chargeDrainResearch, chargeDrainItemLvl = usage_data.chargeDrainResearch, usage_data.chargeDrainItemLvl

local lang = mw.getContentLanguage()
local fnum = function(num) return lang:formatNum(num) end
local GEPRICES = mw.loadJsonData('Module:GEPrices/data.json')
local geprice = function(item) return GEPRICES[item] end

local to_text = function(str) return { text = str } end
local to_coins = compose(to_text, coins)
local coins_with_sort = function(n) return string.format("data-sort-value=\"%d\" | %s", n, coins(n)) end

local consts = {
    nums = {
        max_methods = 6,
        max_items = 20,
        charges_per_charge = 3000,
        inv_cape_fac = 0.98,
        att_cape_fac = 0.98,
        drain_rate = 60
    },
    strs = {
        ref_group = "uc",
        smithing =
        "Cost at [[armour stand]] and [[Whetstone (device)|whetstone]] is reduced by 0.5% per [[Smithing]] level (Reductions of 50% at 99 Smithing, 55.5% at 110 Smithing).",
        calc_txt = "Item is not tradeable on the Grand Exchange. Using calculated value.",
        untr_txt = "Item is not tradeable on the Grand Exchange.",
        div_ref_str =
        "Can be reduced by [[Charge pack#Charge drain reduction|research]], [[equipment level]], [[Efficient]] and [[Enhanced Efficient]] perks, and the [[Invention cape]] perk."
    }
}

local drain = pmult(consts.nums.drain_rate)

local default_num = function(arg, n) return tonumber(default(arg, n or 0)) end
local default_from = function(def_fn, attr, def_val) return function(base) return def_fn(pget(attr)(base), def_val) end end
local defaults = {
    smithing = default_from(default_num, "smithing", 0),
    duration = default_from(default_num, "duration", 60),
    chargesperhour = default_from(default_num, "chargesperhour", drain(COMBAT_RATES[1].rate)),
    invlvl = default_from(default_num, "invlvl", 1),
    tier = default_from(default_num, "tier", 67),
    itemlvl = default_from(default_num, "itemlvl", 1),
    charges = default_from(default_num, "charges", 0),
    format_ = default_from(default, "format", "default"),
    op = compose(string.lower, default_from(default, "op", "min")),
    invcape = compose(pifThenElse({ consts.nums.inv_cape_fac, 1 }), default_from(default, "cape", false)),
    attcape = compose(pifThenElse({ consts.nums.att_cape_fac, 1 }), default_from(default, "cape", false)),
}

-- Adds a ref to the uc group
local function ref(txt, name)
    return mw.getCurrentFrame():extensionTag { name = 'ref', content = txt, args = { name = name, group = consts.strs.ref_group } }
end
local function safe_ref(txt, name)
    if not ((txt == "") and (name == "")) then
        return ref(txt, name)
    else
        return ""
    end
end
local function add_reflist()
    local div = mw.html.create('div')
    div:wikitext(mw.getCurrentFrame():extensionTag {
        name = "references",
        content = nil,
        args = { group = consts.strs.ref_group },
    });
    div:addClass('reflist')
    return tostring(div)
end

local calcvalue_cache = {}
local function calcvalue(item)
    if calcvalue_cache[item] ~= nil then
        return calcvalue_cache[item]
    end

    if GEPRICES[item] then
        return false
    end

    local result, value = pcall(get_calcvalue, item)

    if not result then
        calcvalue_cache[item] = false
        return false
    end

    calcvalue_cache[item] = value
    return value
end

-- Either type for error handling (to be extended)
local function mpcall(fn, arg)
    local worked, output = pcall(fn, arg)
    return ifThenElse(worked, { { output, nil }, { nil, output } })
end

local function num_match(str) return function(arg) return tonumber(arg:match(str)) end end
local function max_num(search_str) return compose(arr.max, pmap(num_match(search_str .. "(%d+)"))) end
local function max_idx(search_str, constant, args)
    return arr.range(math.min(consts.nums[constant], max_num(search_str)(ttools.keysToList(args))))
end

local function exists(fn)
    return function(elem, acc)
        return ifThenElse(fn(elem), { elem, acc })
    end
end

local price_ref_fns = {
    -- Untradeable. Default price 0. Untradeable ref
    function() return { 0, { consts.strs.untr_txt, "untradeable" } } end,
    -- Has a value from calcvalue. Calcvalue ref.
    function(item) return { first(mpcall(calcvalue, item)), { consts.strs.calc_txt, "calcvalue" } } end,
    -- GE-tradeable. No ref
    function(item) return { geprice(item), { "", "" } } end,
    -- Coins; price is 1. No ref
    function(item) return { ifThenElse(item:lower() == "coins", { 1, nil }), { "", "" } } end,
}

-- Go backwards and keep the last match
-- Apply the item name to the price functions, then map the resulting tables
-- into price_ref tables, then select the first one that has a valid price attribute with a curried get
local function get_item_qty_price_ref_from_method(args, mth)
    return function(item_idx)
        local item = args[mth .. "item" .. item_idx]
        local qty = default_num(args[mth .. "qty" .. item_idx], 1)
        local price_ref = arr.reduce(map(thrush(item), price_ref_fns), exists(first))
        return { item = item, qty = qty, price = first(price_ref), ref = second(price_ref) }
    end
end

local function clear_duplicated_ref_contents(iqprs)
    local cleaned_ref_iqprs = {}
    local seen_names = {}
    for _, iqpr in ipairs(iqprs) do
        local ref_txt, ref_name = iqpr.ref[1], iqpr.ref[2]
        if seen_names[ref_name] then
            ref_txt = nil
        else
            table.insert(seen_names, ref_name)
        end
        local built_ref = safe_ref(ref_txt, ref_name)
        table.insert(cleaned_ref_iqprs, { item = iqpr.item, qty = iqpr.qty, price = iqpr.price, ref = built_ref })
    end
    return cleaned_ref_iqprs
end

local function build_method(args, mth)
    local method = {
        iqprs = clear_duplicated_ref_contents(map(get_item_qty_price_ref_from_method(args, mth),
            max_idx(mth .. "item", "max_items", args))),
        description = args[mth .. "desc"],
        is_smithing = args[mth .. "smithing"] or false,
        duration = default_num(default(args.duration, args[mth .. "duration"]), 0) / 60
    }
    return method
end

local function table_class(sort)
    local sort_str = " align-right-2 autosort=2,d"
    return append("wikitable sortable", ifThenElse(sort or false, { sort_str, "" }))
end

local function init_table(sort)
    return mw.html.create("table"):addClass(table_class(sort))
end

local function bottom_aligned(txt) return { text = txt, attr = { ["style"] = "vertical-align: bottom;" } } end
local function colspan(txt, n) return { text = txt, attr = { ["colspan"] = n } } end
local function na() return { tag = "td", text = "<small>N/A</small>", attr = { ["data-sort-value"] = 0, ["class"] = "table-na" } } end

local function get_header_and_rows(header, rows)
    local header_text = default(header.text, header)
    local header_attr = ifThenElse(header.attr, { header.attr, {} })
    local rows_tbl = rows
    if not rows_tbl then rows_tbl = { false } end
    return arr.insert({ { tag = "th", text = header_text, attr = header_attr } }, rows_tbl, nil, true)
end

local function get_descriptions_table(methods)
    -- If the descriptions are all nil, don't show them or the header
    local all_nil_desc = arr.any(methods, pget("description"))
    local description_fn = function(method) return ifThenElse(method.description, { to_text(method.description), na() }) end
    local rows_tbl = get_header_and_rows("Method", map(description_fn, methods))
    return ifThenElse(all_nil_desc, { rows_tbl, { false } })
end

local function time_to_str(total_minutes)
    local hours, minute_dec = math.modf(total_minutes)
    local minutes = round(minute_dec * 60)
    local times = { { time = "hour", val = hours }, { time = "minute", val = minutes } }
    local time_str = function(elem)
        return ifThenElse(elem.val > 0,
            { elem.val .. " " .. elem.time .. ifThenElse(elem.val == 0 or elem.val > 1, { "s", "" }) .. " ", " " })
    end
    return compose(pconcat(""), pmap(time_str))(times)
end

local function get_durations_table(methods)
    -- If the durations are all the same, make them one colspanned cell. Show the header regardless
    local all_same_duration = arr.all(methods, function(method) return method.duration == methods[1].duration end)
    local options = {
        { colspan(time_to_str(methods[1].duration), #methods) },
        map(compose(to_text, time_to_str, pget("duration")), methods)
    }
    return get_header_and_rows("Duration", ifThenElse(all_same_duration, options))
end

local function combat_rate_data(costs, charges)
    return function(combat_rate, i)
        local rate_name, rate = combat_rate.name, combat_rate.rate
        local header = rate_name .. " rate" .. ref(fnum(drain(rate)) .. " charges per hour.", "rate" .. i)
        local data = map(compose(coins, round, pmult(drain(rate) / charges)), costs)
        return get_header_and_rows(header, map(to_text, data))
    end
end

local function get_combat_rates(costs, charges)
    return map(compose(combat_rate_data(costs, charges), function(rate) return COMBAT_RATES[rate], rate end),
        arr.range(3))
end

local function get_total_cost(iqprs)
    return arr.reduce(iqprs, function(iqpr, acc) return iqpr.qty * iqpr.price + acc end, 0)
end

local function format_as_wikitext(iqpr)
    local wikitext = tostring(fnum(round(iqpr.qty, 2)) .. " x " .. plink(iqpr.item)) .. iqpr.ref
    return wikitext
end

local function if_smithing(is_smithing)
    if is_smithing then
        return safe_ref(consts.strs.smithing, "smithing")
    else
        return ""
    end
end

local build_methods_pipe = function(args)
    return compose(
        partial(build_method)(args),
        partial(append)("method")
    )
end
local method_to_items_pipe = compose(
    bottom_aligned,
    fold_append,
    bimap(
        compose(pconcat('<br>'), pmap(format_as_wikitext), pget("iqprs")),
        compose(if_smithing, pget("is_smithing"))),
    dbl)
local method_to_costs_pipe = compose(
    get_total_cost,
    pget("iqprs"))
local method_to_has_refs_pipe = compose(
    fold_or,
    bimap(
        compose(arr.any, pmap(pget("ref")), pget("iqprs")),
        pget("is_smithing")
    ),
    dbl)

function p._common(frame, base_refs)
    local args = frame:getParent().args
    local methods = map(build_methods_pipe(args), max_idx("method", "max_methods", args))
    if #methods == 0 then error("No methods defined") end
    local items = map(method_to_items_pipe, methods)
    local costs = map(method_to_costs_pipe, methods)
    local needs_ref_group = base_refs or arr.any(map(method_to_has_refs_pipe, methods), id)
    return args, methods, items, costs, needs_ref_group
end

local function add_table_ret(arg_tbl, html_tbl)
    local return_tbl = ttools.deepCopy(html_tbl)
    add_table(return_tbl, arg_tbl)
    return return_tbl
end

local function recursive_build(table_pipeline, sort)
    local beginning, last = arr.split(table_pipeline, #table_pipeline - 1)
    if #last == 0 then
        return add_table_ret(beginning, init_table(sort or false))
    else
        return add_table_ret(last, recursive_build(beginning, sort))
    end
end

function p._write_smw_augmented(is_augmented)
    local result = mw.smw.set({ ["is_augmented"] = is_augmented })
    if not result then error(result.error) end
    return nil
end

function p._write(args, enc_table)
    local json_to_write = { ["Usage Cost JSON"] = mw.text.unstrip(mw.text.jsonEncode(enc_table)) }
    -- Expected to break if args.smw is yesno'd anywhere!!!!!!!!!
    local result = ifThenElse(args.smw ~= false, { mw.smw.set(json_to_write), true })
    if not result then error(result.error) end
    return nil
end

function p._table(fn_args_list, needs_ref_group)
    local tbl = recursive_build(fn_args_list)
    if needs_ref_group then
        tbl = append(tbl, add_reflist())
    end
    return tbl
end

function p.fixedDuration(frame)
    local args, methods, items, item_costs, needs_ref_group = p._common(frame, false)
    local coin_amounts = map(compose(to_text, coins, round, fold_div),
        arr.zip(item_costs, map(pget("duration"), methods)))
    local enc_table = { type = "FixedDuration", methods = methods }
    local table_pipeline = {
        get_descriptions_table(methods),
        get_durations_table(methods),
        get_header_and_rows("Item(s) consumed", items),
        get_header_and_rows("Item(s) GE price", map(to_coins, item_costs)),
        get_header_and_rows(colspan("Per hour", #methods + 1)),
        get_header_and_rows("Cost", coin_amounts),
    }
    p._write_smw_augmented(tostring(false))
    p._write(args, enc_table)
    return p._table(table_pipeline, needs_ref_group)
end

function p.combatCharge(frame)
    local args, methods, items, item_costs, needs_ref_group = p._common(frame, false)
    local charges = defaults.charges(args)
    local enc_table = { type = "CombatCharge", charges = charges, methods = methods }

    local fn_args_list = {
        get_header_and_rows("[[Equipment degradation|Combat charges]]", { colspan(fnum(charges), #methods) }),
        get_descriptions_table(methods),
        get_header_and_rows("Item(s) consumed", items),
        get_header_and_rows("Total GE price", map(to_coins, item_costs)),
        get_header_and_rows(colspan("Per hour", #methods + 1)),
        unpack(get_combat_rates(item_costs, charges))
    }
    local is_d2d_augmented = arr.any(items, function(item) return item.text:match("Divine charge") or false end)
    p._write_smw_augmented(tostring(is_d2d_augmented))
    p._write(args, enc_table)
    return p._table(fn_args_list, needs_ref_group)
end

function p.nonStandardDegrade(frame)
    local args, methods, items, item_costs, needs_ref_group = p._common(frame, false)

    local charges = defaults.charges(args)
    local degradeText = args.degradetext

    local enc_table = { type = "NonStandardDegrade", charges = charges, methods = methods }
    local fn_args_list = {
        get_header_and_rows("[[Equipment degradation|Combat charges]]", { colspan(fnum(charges), #methods) }),
        get_descriptions_table(methods),
        get_header_and_rows("Item(s) consumed", items),
        get_header_and_rows("Total GE price", map(to_coins, item_costs)),
        get_header_and_rows("Degrade mechanics", { colspan(degradeText, #methods + 1) }),
    }
    p._write_smw_augmented(tostring(false))
    p._write(args, enc_table)
    return p._table(fn_args_list, needs_ref_group)
end

local function divineChargeCalc(tier, chargeDrainMult)
    -- Yeah I know this is weird, what about tier 68 stuff? the world will never know
    return (ifThenElse(tier < 70, { 67, tier }) - 60) / 8 * (chargeDrainMult * 60 * 60)
end

function p.divineCharge(frame)
    local args = frame:getParent().args
    local needs_ref_group = true

    local tier = defaults.tier(args)
    local slot = args.slot:lower()
    local slotName = DIVINE_CHARGE_SLOTS[slot]["name"]
    if slotName == nil then error("Invalid slot: " .. slot) end
    local chargesPerHour = divineChargeCalc(tier, DIVINE_CHARGE_SLOTS[slot]["chargeDrainMult"])
    local coins_per_hour = coins(geprice("Divine charge") * chargesPerHour / consts.nums.charges_per_charge)
    local divine_ref = fnum(chargesPerHour) .. ref(consts.strs.div_ref_str, "divine charge")
    local enc_table = { type = "DivineCharge", ["tier"] = tier, ["slot"] = slot }
    local fn_args_list = {
        get_header_and_rows("Tier", { to_text(fnum(tier)) }),
        get_header_and_rows("Slot", { to_text(slotName) }),
        get_header_and_rows(colspan("Per hour", 2)),
        get_header_and_rows("Charges", { to_text(divine_ref) }),
        get_header_and_rows("Cost", { to_text(coins_per_hour) }),
    }
    p._write_smw_augmented(tostring(true))
    p._write(args, enc_table)
    return p._table(fn_args_list, needs_ref_group)
end

local function usage_cost_ask(item)
    local smw = mw.smw.ask({
        '[[' .. item .. ']]',
        '?Usage Cost JSON#-' })
    -- If properties not found
    local error_message = "Usage cost not found for " .. item
    if smw == nil or smw[1]["Usage Cost JSON"] == nil then
        error(error_message)
    else
        return smw
    end
end

local function usage_table_ask()
    local smws = mw.smw.ask({
        '[[Usage Cost JSON::+]]',
        '?Usage Cost JSON#-',
        "?#-=pageName",
        limit = 5000
    })
    if smws == nil then
        error("Usage costs not found.")
    else
        return smws
    end
end

local format_table = { coins = coins, coinssort = coins_with_sort, default = id }
local function format_(args)
    return format_table[defaults.format_(args)]
end

-- Make the methods json look like normal function args
local function json_method_flatten(json, idx)
    local mth = "method" .. idx
    local attrs = { "item", "qty" }
    local json_args = {}
    for key, value in pairs(json) do
        if key ~= "iqprs" then
            json_args[mth .. key] = value
        else
            for item_idx, iqpr in ipairs(value) do
                for _, attr in ipairs(attrs) do
                    json_args[mth .. attr .. item_idx] = iqpr[attr]
                end
            end
        end
    end
    return json_args
end

local function get_methods(json_method, idx) return build_method(json_method_flatten(json_method, idx), "method" .. idx) end

local function cost_per_hour(args, ucJSON, kind)
    if kind == "div" then
        local invlvl, invcape, itemlvl = defaults.invlvl(args), defaults.invcape(args), defaults.itemlvl(args)
        local tier = defaults.tier(ucJSON)
        local researchFactor = chargeDrainResearch(invlvl)
        local slotMult = DIVINE_CHARGE_SLOTS[ucJSON["slot"]:lower()]["chargeDrainMult"]
        local chargesPerHour = divineChargeCalc(tier, slotMult) * researchFactor * invcape * chargeDrainItemLvl(itemlvl)
        return map(compose(pmult(geprice("Divine charge")), pmult(1 / consts.nums.charges_per_charge)),
            { chargesPerHour })
    end
    local methods = map(get_methods, ucJSON.methods)
    local durations = map(pget("duration"), methods)
    local item_costs = map(method_to_costs_pipe, methods)
    if kind == "fixed" then -- to_text, coins, round,
        return map(compose(pmult(1 / 60), fold_div), arr.zip(item_costs, durations))
    elseif kind == "combat" then
        local chargesperhour, attcape = defaults.chargesperhour(args), defaults.attcape(args)
        local charges = ucJSON.charges
        return map(compose(pmult(attcape), pmult(chargesperhour / charges)), item_costs)
    elseif kind == "nonstandard" then
        return map(pmult(1), item_costs)
    end
end

local function cost_type(args)
    return function(json)
        local cost_table = {
            fixedduration = "fixed",
            combatcharge = "combat",
            divinecharge = "div",
            nonstandarddegrade =
            "nonstandard"
        }
        local type_ = json["type"]:lower()
        if not cost_table[type_] then error(type_) end
        return cost_per_hour(args, json, cost_table[type_])
    end
end

-- Unweighted simple average
local avg = function(lst) return arr.sum(lst) / arr.len(lst) end
local op_table = { avg = avg, highest = arr.max, max = arr.max, min = arr.min }
-- Set op_table to be the function to call based on what op is. Note op defaults to min
local function cost_metric(args) return compose(round, op_table[defaults.op(args)]) end

-- There are a couple pages, like Aspect of Evasion, that have multiple Usage Cost JSONs
local function double_decode(json_string)
    return mw.text.jsonDecode(mw.text.decode(json_string))
end

local function smw_decode(smw)
    return double_decode(smw[1]["Usage Cost JSON"])
end

-- Expects a table (in practice I think it's mostly exactly one) of items.
-- Finds and formats the sum of their usage costs
function p.getUsageCost(frame)
    local args = frame:getParent().args
    local usage_cost_pipeline = compose(
        format_(args),
        arr.sum,
        pmap(
            compose(cost_metric(args), cost_type(args), smw_decode, usage_cost_ask)),
        ttools.compressSparseArray
    )
    return usage_cost_pipeline(args)
end

local page_cell = to_text
local function cost_cell(cost) return { text = coins(cost), attr = { ["data-sort-value"] = cost } } end
local function right_is_string(pair) return type(pair[2]) == "string" end
local function right_has_type(pair) return pget("type")(pair[2]) end
local function isnt_nonstandard(pair) return pair[2].type ~= "NonStandardDegrade" end
-- Expects a table of items.
-- Returns formatted pagename, data pairs for use in add_table.
function p.getMultiUsageCosts()
    local args = { is_smithing = false, smithing_level = 1 }
    local usage_cost_table_pipeline = compose(
        pmap(bimap(
            page_cell,
            cost_cell)),
        pmap(send_right(compose(cost_metric(args), cost_type(args)))),
        pfilter(isnt_nonstandard),
        pfilter(right_has_type),
        pmap(send_right(double_decode)),
        pfilter(right_is_string),
        pmap(bimap(
            compose(plink, pget("pageName")),
            pget("Usage Cost JSON"))),
        pmap(dbl)
    )
    return usage_cost_table_pipeline(usage_table_ask())
end

function p.getUsageCostTable()
    local multi_usage_costs = p.getMultiUsageCosts()

    local t = init_table(true)
    add_table(t, { { { tag = "th", text = "Item" }, { tag = "th", text = "Hourly usage cost" } } })
    add_table(t, multi_usage_costs)
    return append(t, add_reflist())
end

return p
