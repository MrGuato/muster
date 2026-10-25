-- Everything Muster says to the server goes through this file.
--
-- mod-playerbots listens in two places:
--   * the ".playerbot bot ..." chat command, for logging bots in and out
--     (answers arrive as system messages);
--   * plain words whispered to a bot or said in party/raid chat, for orders
--     and strategies. A party/raid message can start with a filter such as
--     "@tank" so only matching bots react.
-- The builders below are pure string functions so the tests can check them.
Muster = Muster or {}
local M = Muster
local L = M.L

local C = {}
M.Commands = C

-- Class names the server's addclass command accepts, by WoW class token.
C.CLASS_BY_TOKEN = {
    WARRIOR = "warrior", PALADIN = "paladin", HUNTER = "hunter", ROGUE = "rogue",
    PRIEST = "priest", SHAMAN = "shaman", MAGE = "mage", WARLOCK = "warlock",
    DRUID = "druid", DEATHKNIGHT = "dk",
}
C.CLASS_ARGS = { "warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid", "dk" }

local ALIASES = { deathknight = "dk", ["death knight"] = "dk", pally = "paladin", lock = "warlock", sham = "shaman" }

-- "Mage", "death knight", "DK" -> the server's class word, or nil.
function C.ClassArg(text)
    text = M.Trim((text or "")):lower()
    text = ALIASES[text] or text
    for _, arg in ipairs(C.CLASS_ARGS) do
        if arg == text then return arg end
    end
    return nil
end

-- "Death Knight", "DeathKnight", "DEATHKNIGHT" -> "DEATHKNIGHT" (RAID_CLASS_COLORS key).
function C.ClassToken(name)
    return ((name or ""):gsub("%s+", ""):upper())
end

local function nameList(names)
    if type(names) == "table" then return table.concat(names, ",") end
    return (M.Trim(names):gsub("%s*,%s*", ","):gsub("%s+", ","))
end

function C.Bot(sub, arg)
    if arg and arg ~= "" then return ".playerbot bot " .. sub .. " " .. arg end
    return ".playerbot bot " .. sub
end

function C.List() return C.Bot("list") end
function C.Add(names) return C.Bot("add", nameList(names)) end
function C.Remove(names) return C.Bot("remove", nameList(names)) end
function C.AddClass(classArg) return C.Bot("addclass", classArg) end

-- Who an order goes to. "" means every bot in the group.
C.FILTERS = {
    all = "", tank = "@tank", heal = "@heal", dps = "@dps", melee = "@melee", ranged = "@ranged",
}
C.FILTER_ORDER = { "all", "tank", "heal", "dps", "melee", "ranged" }
C.FILTER_LABEL = {
    all = L.TARGET_ALL, tank = L.TARGET_TANKS, heal = L.TARGET_HEALERS,
    dps = L.TARGET_DPS, melee = L.TARGET_MELEE, ranged = L.TARGET_RANGED,
}
local FILTER_ALIASES = { tanks = "tank", healer = "heal", healers = "heal", damage = "dps" }

function C.Filtered(filter, text)
    filter = FILTER_ALIASES[filter] or filter
    local prefix = C.FILTERS[filter or "all"] or ""
    if prefix == "" then return text end
    return prefix .. " " .. text
end

-- Orders, in panel order. `text` is exactly what the bots listen for.
C.ORDERS = {
    { key = "follow",  text = "follow",      label = "Follow",     tip = "Follow you." },
    { key = "stay",    text = "stay",        label = "Stay",       tip = "Hold position where they stand." },
    { key = "attack",  text = "attack",      label = "Attack",     tip = "Attack your current target." },
    { key = "tank",    text = "tank attack", label = "Tank in",
      tip = "Tanks engage your target first; the rest follow their usual rules." },
    { key = "pull",    text = "pull",        label = "Pull",       tip = "The tank pulls your target back to the group." },
    { key = "flee",    text = "flee",        label = "Flee",       tip = "Stop fighting and run back to you." },
    { key = "summon",  text = "summon",      label = "Summon",     tip = "Teleport to you (bots that are allowed to)." },
    { key = "release", text = "release",     label = "Release",    tip = "Dead bots release their spirit." },
    { key = "revive",  text = "revive",      label = "Revive",     tip = "Dead bots revive at a spirit healer." },
    { key = "rebuff",  text = "rebuff",      label = "Rebuff",     tip = "Cast buffs again." },
    { key = "drink",   text = "drink",       label = "Eat/Drink",  tip = "Sit down and restore health and mana." },
    { key = "maxdps",  text = "max dps",     label = "Max DPS",    tip = "Go all out: cooldowns and best damage." },
    { key = "savemana", text = "save mana",  label = "Save mana",  tip = "Healers and casters spend mana carefully." },
    { key = "grind",   text = "grind",       label = "Grind",      tip = "Fight nearby monsters on their own." },
}
C.ORDER_BY_KEY = {}
for _, o in ipairs(C.ORDERS) do C.ORDER_BY_KEY[o.key] = o end

-- "co +avoid aoe" / "nc -loot". state is "co" (in combat) or "nc" (out of combat).
function C.Strategy(state, on, name)
    return state .. " " .. (on and "+" or "-") .. name
end

function C.StrategyQuery(state) return state .. " ?" end

-- Pick one of the server's premade specs, e.g. "prot pve".
function C.SpecPick(spec) return "talents spec " .. spec end

---------------------------------------------------------------------------
-- Senders
---------------------------------------------------------------------------

-- Chat starting with "." is taken by the server as a command, not said aloud.
function M:SendServerCommand(text)
    SendChatMessage(text, "SAY")
end

function M:Whisper(name, text)
    SendChatMessage(text, "WHISPER", nil, name)
end

function M:GroupChannel()
    if GetNumRaidMembers() > 0 then return "RAID" end
    if GetNumPartyMembers() > 0 then return "PARTY" end
    return nil
end

-- Say `text` to the whole group, optionally filtered to a role.
function M:TellGroup(text, filter)
    local channel = M:GroupChannel()
    if not channel then
        M:Print(L.NOT_IN_GROUP)
        return false
    end
    SendChatMessage(C.Filtered(filter, text), channel)
    return true
end

-- Give an order. With `botName` it is whispered to that bot alone.
function M:Order(key, filter, botName)
    local order = C.ORDER_BY_KEY[key]
    if not order then return false end
    if botName then
        M:Whisper(botName, order.text)
        return true
    end
    return M:TellGroup(order.text, filter)
end
