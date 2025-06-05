local getArgs = require("Arguments").getArgs;
local coins = require('Currency')._amount
local parseTemplateParams = require("TemplateUtil").parseTemplateParams;

local p = {}

function p.main(frame)
    local args = getArgs(frame);
    local item = args['item'] or args[1]
    local img = false
    if args['image'] or args[2] then
        img = true
    end

    if args['set'] then
        local ret = p._set(args['set'])
        return
    end

    return p._get(item, img)
end

local expr = mw.ext.ParserFunctions.expr;
local function parseMultiplier(multi)
    do
        local result = tonumber(multi);
        if (result ~= nil) then
            return result;
        end
    end

    -- indicated someone is trying to pass an equation as a mulitplier
    -- known use cases are fractions, but pass it to #expr to make sure
    -- it's handled correctly
    if (multi ~= nil and mw.ustring.find(multi, "[/*+-]")) then
        return tonumber(expr(multi));
    end

    return nil;
end

function p.price(frame)
    local args = getArgs(frame);
    local item = args[1];
    local multi = parseMultiplier(args[2]) or 1;

    return p._get(item, false, multi);
end

function p._get(item, img, multi)
    local calcval
    do
        local subsmw = mw.smw.ask {
            ('[[Item name::%s]]'):format(item),
            '?Calculated value#-',
            limit = 1
        }
        if subsmw and subsmw[1] then
            calcval = subsmw[1]['Calculated value']
        end
    end
    if not calcval then
        local res = mw.smw.ask({
            '[[' .. item .. ']]',
            '?Calculated value#-'
        })
        if res and res[1] then
            calcval = res[1]['Calculated value']
        end
    end
    if not calcval then
        error('No calculated value could be found for: ' .. item)
    end

    local price
    if tonumber(calcval) then
        price = tonumber(calcval)
    else
        local x = calcval
            :gsub('{{[Cc]alcvalue%|([^}]+)}}', p._get)
            :gsub("{{[Cc]VP%|([^}]+)}}", function(template)
                return p.price(parseTemplateParams(template));
            end)
            :gsub("{{[Cc]VTotal%|([^}]+)}}", function(template)
                return require("Module:CVTotal").simple(parseTemplateParams(template));
            end)
        price = mw.getCurrentFrame():preprocess("{{#expr: " .. x .. " }}")
        if tonumber(price) then
            price = math.floor(price * 100 + 0.5) / 100
        else
            mw.logObject(
                { calcval = calcval, x = x, price = price },
                "[[Module:Calcvalue]]._get:"
            );
            error('Error preprocessing calculated value: ' .. calcval)
        end
    end

    if type(multi) == "number" then
        price = multi * price;
    end

    if img then
        return coins(price, 'coins')
    end
    return price
end

function p._set(val)
    local ret
    if tonumber(val) then
        ret = val
        mw.log('Fixed value: ' .. ret)
    else
        local str = string.gsub(string.gsub(val, '{', '{{'), '}', '}}')
        ret = string.gsub(str, '¦', '|')
        mw.log('Wikitext: ' .. ret)
        mw.log('Resulting value: ' .. mw.getCurrentFrame():preprocess(ret))
    end

    local res = mw.smw.set({ ['Calculated value'] = ret })
    if res == true then
        -- everything ok
    else
        -- error message to be found in result.error
        error(res.error)
    end

    return true
end

return p
