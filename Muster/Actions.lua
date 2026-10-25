-- Every command the command bar offers, grouped into categories. Each action
-- has a stable id (pins are saved by id), a game icon, a title, a tooltip,
-- the line it sends, and a run(shift) function. Icons are the client's own
-- and are checked against the 3.3.5 icon list by the tests.
Muster = Muster or {}
local M = Muster
local L = M.L
local C = M.Commands

local A = { list = {}, byId = {}, categories = {} }
M.Actions = A

local function icon(name) return "Interface\\Icons\\" .. name end

local function add(cat, action)
    action.cat = cat
    table.insert(A.list, action)
    A.byId[action.id] = action
    table.insert(A.categories[cat].actions, action)
end

local function category(id, title, iconName)
    A.categories[id] = { id = id, title = title, icon = icon(iconName), actions = {} }
    table.insert(A.categories, A.categories[id])
end

-- Who orders and group-wide strategy changes go to: the Orders tab's choice.
function M:TargetLabel()
    local target = M.db and M.db.orderTarget or "all"
    if target == "selected" then return M.Roster:FocusBot() or L.NO_BOT_SELECTED end
    return C.FILTER_LABEL[target] or L.TARGET_ALL
end

---------------------------------------------------------------------------
category("orders", L.CAT_ORDERS, "ability_warrior_rallyingcry")

local ORDER_ICONS = {
    follow = "spell_nature_swiftness", stay = "spell_nature_timestop", attack = "ability_dualwield",
    tank = "ability_warrior_defensivestance", pull = "ability_hunter_snipershot", flee = "ability_rogue_sprint",
    summon = "spell_shadow_twilight", release = "spell_holy_guardianspirit", revive = "spell_holy_resurrection",
    rebuff = "spell_holy_wordfortitude", drink = "inv_drink_07", maxdps = "ability_warrior_innerrage",
    savemana = "inv_potion_76", grind = "ability_hunter_pet_wolf",
}
for _, order in ipairs(C.ORDERS) do
    add("orders", {
        id = "order:" .. order.key, icon = icon(ORDER_ICONS[order.key]),
        title = order.label, tip = order.tip, send = order.text, targeted = true,
        run = function() return M:GiveOrder(order.key) end,
    })
end

---------------------------------------------------------------------------
category("bots", L.CAT_BOTS, "inv_misc_groupneedmore")

add("bots", {
    id = "bots:refresh", icon = icon("inv_misc_book_09"),
    title = L.REFRESH, tip = L.TIP_REFRESH, send = C.List(),
    run = function() M.Roster:Refresh() end,
})
add("bots", {
    id = "bots:dismiss", icon = icon("ability_vanish"),
    title = L.DISMISS_ALL, tip = L.TIP_DISMISS, send = C.Remove("<your group bots>"),
    run = function() M.Roster:DismissGroupBots() end,
})
local CLASS_SHEET = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
for _, token in ipairs({ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "DEATHKNIGHT" }) do
    local arg = C.CLASS_BY_TOKEN[token]
    add("bots", {
        id = "bots:add:" .. arg, icon = CLASS_SHEET, classToken = token,
        title = L.ADD_CLASS_TITLE:format(arg), tip = L.ADD_BY_CLASS, send = C.AddClass(arg),
        run = function() M:SendServerCommand(C.AddClass(arg)) end,
    })
end

---------------------------------------------------------------------------
category("raise", L.CAT_RAISE, "inv_banner_03")

local TEMPLATE_ICONS = {
    dungeon = "ability_warrior_charge", ["dungeon-tank"] = "ability_warrior_shieldwall",
    ["dungeon-heal"] = "spell_holy_flashheal", raid10 = "inv_banner_02", raid25 = "ability_warrior_battleshout",
    raid40 = "achievement_dungeon_gloryoftheraider",
}
for _, tpl in ipairs(M.Templates:All()) do
    local total, tanks, heals, dps = M.Templates.Summary(tpl)
    add("raise", {
        id = "raise:" .. tpl.id, icon = icon(TEMPLATE_ICONS[tpl.id]),
        title = tpl.name, tip = M.Templates.SummaryText(total, tanks, heals, dps),
        send = C.AddClass("<class>") .. " x" .. total,
        run = function() M.Templates:Raise(tpl) end,
    })
end
add("raise", {
    id = "raise:stop", icon = icon("ability_rogue_kidneyshot"),
    title = L.STOP, tip = L.TIP_STOP, send = nil,
    run = function() M.Templates:Stop() end,
})

---------------------------------------------------------------------------
local STRATEGY_ICONS = {
    co = {
        ["avoid aoe"] = "spell_fire_fire", threat = "ability_warrior_punishingblow", behind = "ability_rogue_ambush",
        ["save mana"] = "spell_holy_sealofwisdom", potions = "inv_potion_54", racials = "racial_troll_berserk",
        ["focus heal targets"] = "spell_holy_prayerofhealing02", passive = "spell_nature_tranquility",
        aggressive = "ability_warrior_warcry",
    },
    nc = {
        follow = "ability_tracking", stay = "spell_nature_timestop", loot = "inv_misc_bag_10",
        gather = "inv_misc_herb_07", food = "inv_misc_food_15", mount = "ability_mount_ridinghorse",
        grind = "ability_hunter_pet_wolf", quest = "inv_scroll_03", rpg = "inv_misc_map_01",
    },
}
category("co", L.CAT_COMBAT, "ability_warrior_challange")
category("nc", L.CAT_NONCOMBAT, "ability_eyeoftheowl")
for _, which in ipairs({ "co", "nc" }) do
    for _, entry in ipairs(M.Strategies.LIST[which]) do
        add(which, {
            id = "strategy:" .. which .. ":" .. entry.name, icon = icon(STRATEGY_ICONS[which][entry.name]),
            title = entry.name, tip = entry.tip, toggle = true, targeted = true,
            send = C.Strategy(which, true, entry.name) .. " / " .. C.Strategy(which, false, entry.name),
            run = function(off) return M.Strategies:SetForTarget(which, entry.name, not off) end,
        })
    end
end

---------------------------------------------------------------------------
-- Pins: action ids shown on the bar itself, in order.
A.MAX_PINS = 10

function A:Pins()
    M.db.pinned = M.db.pinned or {}
    return M.db.pinned
end

function A:IsPinned(id)
    for i, pinned in ipairs(self:Pins()) do
        if pinned == id then return i end
    end
    return nil
end

-- Pin an action, or unpin it if it is already pinned. Returns true when the
-- pins changed.
function A:TogglePin(id)
    if not A.byId[id] then return false end
    local pins = self:Pins()
    local at = self:IsPinned(id)
    if at then
        table.remove(pins, at)
    elseif #pins < A.MAX_PINS then
        table.insert(pins, id)
    else
        M:Print(L.PINS_FULL, A.MAX_PINS)
        return false
    end
    M:Fire("PINS")
    return true
end
