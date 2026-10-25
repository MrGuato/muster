-- Strategy toggles. A bot runs two sets of strategies: "co" while in combat
-- and "nc" out of combat. "co +avoid aoe" turns one on, "co -avoid aoe" off,
-- and "co ?" makes the bot whisper back "Strategies: a, b, c".
Muster = Muster or {}
local M = Muster
local C = M.Commands

local S = { state = {}, pending = {} }
M.Strategies = S

-- The toggles the panel offers, with what each one does. Names must match
-- mod-playerbots' strategy names exactly.
S.LIST = {
    co = {
        { name = "avoid aoe", tip = "Step out of ground effects such as fire and poison clouds." },
        { name = "threat", tip = "Damage dealers hold back when they are close to pulling aggro." },
        { name = "behind", tip = "Melee fight from behind the target." },
        { name = "save mana", tip = "Spend mana carefully: cheaper heals, fewer big spells." },
        { name = "potions", tip = "Drink health and mana potions when low." },
        { name = "racials", tip = "Use racial abilities in combat." },
        { name = "focus heal targets", tip = "Healers focus the targets you set with the focus heal command." },
        { name = "passive", tip = "Don't fight back at all. Useful for escorting or running past packs." },
        { name = "aggressive", tip = "Attack anything hostile nearby, not just what you fight." },
    },
    nc = {
        { name = "follow", tip = "Follow you around." },
        { name = "stay", tip = "Stay where they are." },
        { name = "loot", tip = "Loot corpses after a fight." },
        { name = "gather", tip = "Gather herbs, ore and other nodes they can use." },
        { name = "food", tip = "Eat and drink after a fight." },
        { name = "mount", tip = "Mount up when you do." },
        { name = "grind", tip = "Hunt nearby monsters on their own." },
        { name = "quest", tip = "Work on their quests." },
        { name = "rpg", tip = "Wander, talk to NPCs and act like players when you leave them alone." },
    },
}

-- "Strategies: avoid aoe, dps, threat" -> { ["avoid aoe"]=true, dps=true, threat=true }, else nil.
function S.Parse(msg)
    if type(msg) ~= "string" then return nil end
    local body = msg:match("^Strategies:%s*(.*)$")
    if not body then return nil end
    local set = {}
    for name in body:gmatch("[^,]+") do
        name = M.Trim(name)
        if name ~= "" then set[name] = true end
    end
    return set
end

-- Ask a bot for both strategy sets: "co ?" first, then "nc ?" once the
-- combat answer is in, so each reply is matched to the question it answers.
-- A question nobody answers within QUERY_TIMEOUT seconds is dropped.
local QUERY_TIMEOUT = 3

function S:Query(bot)
    local p = self.pending[bot]
    if p and GetTime() - p.at < QUERY_TIMEOUT then return false end -- already asking
    self.pending[bot] = { expect = "co", at = GetTime() }
    M:Whisper(bot, C.StrategyQuery("co"))
    return true
end

function S:OnWhisper(sender, msg)
    if not sender then return false end
    sender = sender:match("^[^-]+") or sender -- drop a "-Realm" suffix if one is there
    local p = self.pending[sender]
    if not p then return false end
    if GetTime() - p.at > QUERY_TIMEOUT then
        self.pending[sender] = nil
        return false
    end
    local set = S.Parse(msg)
    if not set then return false end
    self.state[sender] = self.state[sender] or {}
    self.state[sender][p.expect] = set
    if p.expect == "co" then
        p.expect, p.at = "nc", GetTime()
        M:Whisper(sender, C.StrategyQuery("nc"))
    else
        self.pending[sender] = nil
    end
    M:Fire("STRATEGIES", sender)
    return true
end

function S:Get(bot, which)
    return self.state[bot] and self.state[bot][which]
end

-- Turn a strategy on or off for whoever the Orders tab is set to: the
-- selected bot, everyone, or one role.
function S:SetForTarget(which, name, on)
    local target = M.db.orderTarget or "all"
    if target == "selected" then
        local bot = M.Roster:FocusBot()
        if not bot then
            M:Print(M.L.NO_BOT_SELECTED)
            return false
        end
        return self:Set(bot, which, name, on)
    end
    return M:TellGroup(C.Strategy(which, on, name), target)
end

-- Turn a strategy on or off for one bot, or for the whole group.
function S:Set(bot, which, name, on)
    local text = C.Strategy(which, on, name)
    if bot then
        M:Whisper(bot, text)
        self.state[bot] = self.state[bot] or {}
        self.state[bot][which] = self.state[bot][which] or {}
        self.state[bot][which][name] = on or nil
        M:Fire("STRATEGIES", bot)
        return true
    end
    return M:TellGroup(text)
end
