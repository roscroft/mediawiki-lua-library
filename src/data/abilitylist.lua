-- SMW queries for updates of a particular type, then serves the wikitext.

local arr = require('Module:Array')
local yesno = require('Module:Yesno')
local p = {}
require("Module:Mw.html extension")

local mems_icons = {
    [false] = "[[File:F2P icon.png|30px|center|link=Free-to-play|Free-to-play]]",
    [true]  = "[[File:P2P icon.png|30px|center|link=Members|Members]]"
}

local level_sort = function(a, b) return (tonumber(a.level) or 0) < (tonumber(b.level) or 0) end
local name_sort = function(a, b) return a.name < b.name end

local function get_abilities(ability_cat)
    return mw.smw.ask({
        '[[Category:' .. ability_cat .. ']]',
        '[[Ability JSON::+]]',
        '?=Page#',
        '?Ability JSON=JSON',
        limit = 10000
    })
end

local function parse_ability(smw)
    if type(smw["JSON"]) ~= "string" then smw["JSON"] = smw["JSON"][1] end
    local ability_data = mw.text.jsonDecode(mw.text.decode(smw["JSON"]))
    local ability = {
        page = smw["Page"],
        name = ability_data["name"],
        image = ability_data["image"],
        members = ability_data["members"],
        skill = ability_data["skill"],
        level = ability_data["level"],
        type = ability_data["type"],
        target = ability_data["target"],
        adrenaline = ability_data["adrenaline"],
        equipment = ability_data["equipment"],
        damage = ability_data["damage"],
        cooldown = ability_data["cooldown"],
        description = ability_data["description"],
        sfx = ability_data["sfx"],
        removal = ability_data["removal"]
    }
    if ability.removal then return nil end
    return ability
end

local function build_table(frame, abilities)
    local t = mw.html.create('table')
    t:addClass(
        'wikitable sortable align-right-1 align-left-2 align-center-3 align-left-4 align-center-5 align-left-6 align-center-7 align-center-8 align-left-9 align-left-10')
    t:tr()
        :th { "Ability", attr = { colspan = 2 } }
        :th("Level")
        :th("Type")
        :th("Adrenaline")
        :th("Target")
        :th(
            'Damage<sup class="hover-text noprint" style="border: 0;" title="Average ability damage without any modifiers against a single target">[?]</sup>')
        :th("Cooldown")
        :th("Equipment")
        :th("Description")
        :th("Members")

    for _, ability in ipairs(abilities) do
        local members = yesno(ability.members, nil)
        t:tr()
            :td(frame:expandTemplate { title = "Clean image", args = { file = ability.image, width = 30, height = 30 } })
            :td(string.format("[[%s|%s]]", ability.page, ability.name))
            :td(ability.level)
            :td(ability.type)
            :td(ability.adrenaline)
            :td(ability.target)
            :IF(ability.damage and (ability.damage ~= "None"))
            :td(ability.damage)
            :ELSE()
            :na()
            :END()
            :td(ability.cooldown)
            :td(ability.equipment)
            :tdl(ability.description)
            :td(members ~= nil and mems_icons[members] or 'Unknown')
    end
    return t:allDone()
end

function p.main(frame)
    local args = frame:getParent().args
    local ability_cat = args[1] .. " abilities"
    --local ability_type = args.type or ""
    local abilities = arr.filter(arr.map(get_abilities(ability_cat), parse_ability),
        function(ability) return ability end)
    --abilities = arr.filter(abilities, function (ability) return (ability_type == "") or (ability.type:lower() == ability_type:lower()) end)
    table.sort(abilities, level_sort)
    return build_table(frame, abilities)
end

function p.all_table(frame)
    local ability_cat =
    "Agility abilities||Attack abilities||Strength abilities||Constitution abilities||Defence abilities||Magic abilities||Ranged abilities||Necromancy abilities"
    local abilities = arr.filter(arr.map(get_abilities(ability_cat), parse_ability),
        function(ability) return ability end)
    table.sort(abilities, level_sort)
    return build_table(frame, abilities)
end

return p
