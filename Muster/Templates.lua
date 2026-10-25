-- Group templates: "raise" a whole dungeon or raid group in one click.
--
-- Raising walks a template's slots and asks the server for one bot of each
-- slot's class (".playerbot bot addclass <class>"), a little apart so the
-- server keeps up. New bots join your group by themselves; the server turns
-- the party into a raid at the sixth member. When a bot of a slot's class
-- joins, Muster whispers it the slot's spec ("talents spec prot pve"), so a
-- tank slot gets a tank and not whatever spec the bot rolled.
Muster = Muster or {}
local M = Muster
local L = M.L
local C = M.Commands

local T = { job = nil, pendingSpecs = {}, known = {} }
M.Templates = T

local SPEC_WAIT = 60 -- seconds a spec waits for a bot of its class to join
local SPEC_DELAY = 3 -- seconds after joining before the bot is told its spec

local function rep(slots, n, class, spec, role)
    for _ = 1, n do table.insert(slots, { class = class, spec = spec, role = role }) end
end

local function build(spec)
    local slots = {}
    for _, s in ipairs(spec) do rep(slots, s[1], s[2], s[3], s[4]) end
    return slots
end

-- Spec names are mod-playerbots' default premade specs (Playerbots.PremadeSpecName.*).
T.BUILTIN = {
    {
        id = "dungeon", name = L["Dungeon (you deal damage)"],
        slots = build({
            { 1, "warrior", "prot pve", "tank" }, { 1, "priest", "holy pve", "heal" },
            { 1, "mage", "frost pve", "dps" }, { 1, "rogue", "combat pve", "dps" },
        }),
    },
    {
        id = "dungeon-tank", name = L["Dungeon (you tank)"],
        slots = build({
            { 1, "priest", "holy pve", "heal" }, { 1, "mage", "frost pve", "dps" },
            { 1, "rogue", "combat pve", "dps" }, { 1, "hunter", "mm pve", "dps" },
        }),
    },
    {
        id = "dungeon-heal", name = L["Dungeon (you heal)"],
        slots = build({
            { 1, "warrior", "prot pve", "tank" }, { 1, "mage", "frost pve", "dps" },
            { 1, "rogue", "combat pve", "dps" }, { 1, "hunter", "mm pve", "dps" },
        }),
    },
    {
        id = "raid10", name = L["Raid, 10 players"],
        slots = build({
            { 1, "warrior", "prot pve", "tank" }, { 1, "paladin", "prot pve", "tank" },
            { 1, "priest", "holy pve", "heal" }, { 1, "shaman", "resto pve", "heal" }, { 1, "druid", "resto pve", "heal" },
            { 1, "mage", "frost pve", "dps" }, { 1, "rogue", "combat pve", "dps" },
            { 1, "hunter", "mm pve", "dps" }, { 1, "warlock", "destro pve", "dps" },
        }),
    },
    {
        id = "raid25", name = L["Raid, 25 players"],
        slots = build({
            { 2, "warrior", "prot pve", "tank" }, { 1, "paladin", "prot pve", "tank" },
            { 2, "priest", "holy pve", "heal" }, { 2, "shaman", "resto pve", "heal" },
            { 1, "druid", "resto pve", "heal" }, { 1, "paladin", "holy pve", "heal" },
            { 2, "warrior", "fury pve", "dps" }, { 2, "rogue", "combat pve", "dps" }, { 3, "mage", "frost pve", "dps" },
            { 3, "warlock", "destro pve", "dps" }, { 3, "hunter", "mm pve", "dps" },
            { 1, "shaman", "ele pve", "dps" }, { 1, "priest", "shadow pve", "dps" },
        }),
    },
    {
        id = "raid40", name = L["Raid, 40 players (classic)"],
        slots = build({
            { 3, "warrior", "prot pve", "tank" },
            { 5, "priest", "holy pve", "heal" }, { 3, "paladin", "holy pve", "heal" },
            { 2, "druid", "resto pve", "heal" }, { 1, "shaman", "resto pve", "heal" },
            { 4, "warrior", "fury pve", "dps" }, { 5, "rogue", "combat pve", "dps" }, { 5, "mage", "frost pve", "dps" },
            { 4, "warlock", "destro pve", "dps" }, { 4, "hunter", "mm pve", "dps" },
            { 1, "shaman", "ele pve", "dps" }, { 1, "priest", "shadow pve", "dps" }, { 1, "paladin", "ret pve", "dps" },
        }),
    },
}

function T:All() return T.BUILTIN end

function T:Get(id)
    for _, tpl in ipairs(T.BUILTIN) do
        if tpl.id == id then return tpl end
    end
    return nil
end

function T:IdList()
    local ids = {}
    for _, tpl in ipairs(T.BUILTIN) do table.insert(ids, tpl.id) end
    return table.concat(ids, ", ")
end

-- Count slots by role: total, tanks, healers, damage.
function T.Summary(tpl)
    local n = { tank = 0, heal = 0, dps = 0 }
    for _, s in ipairs(tpl.slots) do n[s.role] = (n[s.role] or 0) + 1 end
    return #tpl.slots, n.tank, n.heal, n.dps
end

-- The slots still to fill, given how many bots of each class (server class
-- word) are already in the group. Members already there are counted against
-- damage slots first, then healers, then tanks: we can't see their spec, and
-- a missing tank or healer hurts more than a missing damage dealer. The slots
-- left keep their template order. Pure, so the tests can check it.
local ROLE_FILL_ORDER = { "dps", "heal", "tank" }

function T.Plan(slots, have)
    local left = {}
    for k, v in pairs(have or {}) do left[k] = v end
    local filled = {}
    for _, role in ipairs(ROLE_FILL_ORDER) do
        for i, s in ipairs(slots) do
            if s.role == role and (left[s.class] or 0) > 0 then
                left[s.class] = left[s.class] - 1
                filled[i] = true
            end
        end
    end
    local todo = {}
    for i, s in ipairs(slots) do
        if not filled[i] then table.insert(todo, s) end
    end
    return todo
end

local function groupClassCounts()
    local have = {}
    for _, m in ipairs(M.Roster.GroupMembers()) do
        local arg = C.CLASS_BY_TOKEN[m.class or ""]
        if arg then have[arg] = (have[arg] or 0) + 1 end
    end
    return have
end

local function snapshotGroup()
    local known = {}
    for _, m in ipairs(M.Roster.GroupMembers()) do known[m.name] = true end
    return known
end

function T:Raise(tpl)
    if self.job then self:Stop(true) end
    local todo = T.Plan(tpl.slots, M.db.fillMissing and groupClassCounts() or {})
    if #todo == 0 then
        M:Print(L.RAISE_NOTHING, tpl.name)
        return
    end
    self.known = snapshotGroup()
    self.pendingSpecs = {}
    self.job = { tpl = tpl, todo = todo, index = 0, total = #todo }
    self:Step()
end

function T:Step()
    local job = self.job
    if not job then return end
    job.index = job.index + 1
    local slot = job.todo[job.index]
    if not slot then
        M:Print(L.RAISE_DONE, job.tpl.name, job.total)
        self.job = nil
        M:Fire("RAISE")
        -- Load the new bots into the roster, so "Dismiss group bots" knows them.
        M:After(3, function() M.Roster:Refresh() end)
        return
    end
    if M.db.pickSpecs and slot.spec then
        table.insert(self.pendingSpecs, { class = slot.class, spec = slot.spec, at = GetTime() })
    end
    M:SendServerCommand(C.AddClass(slot.class))
    M:Fire("RAISE", job.index, job.total, job.tpl.name)
    M:After(M.db.addDelay, function()
        if self.job == job then self:Step() end
    end)
end

function T:Stop(quiet)
    local job = self.job
    if not job then return end
    self.job = nil
    if not quiet then M:Print(L.RAISE_STOPPED, job.index, job.total) end
    M:Fire("RAISE")
end

function T:IsRaising() return self.job ~= nil end

-- Server replies that mean no more bots are coming.
T.FAILURES = {
    "^Add class failed",
    "^Failure:",
    "do not have permission to create bot",
    "level is too low to summon",
    "^ERROR:",
}

function T:OnSystemMessage(msg)
    local job = self.job
    if not job or type(msg) ~= "string" then return end
    for _, pattern in ipairs(T.FAILURES) do
        if msg:find(pattern) then
            M:Print(L.RAISE_FAILED, msg)
            -- The refused bot never comes, so its spec must not go to the next one.
            if M.db.pickSpecs and job.todo[job.index] and job.todo[job.index].spec then
                table.remove(self.pendingSpecs)
            end
            self:Stop(true)
            -- The slot that failed was job.index, so one fewer got through.
            M:Print(L.RAISE_STOPPED, job.index - 1, job.total)
            return
        end
    end
end

-- A new group member whose class has a waiting spec gets told that spec.
-- Right after a bot joins, the client may not know its name or class yet
-- (UnitName says "Unknown", UnitClass nil). Such a member is left out of
-- `known` so it counts as new again on the next check, and while specs are
-- waiting Muster checks again every second.
function T:OnGroupChanged()
    local now = GetTime()
    -- Drop specs whose bot never came.
    for i = #self.pendingSpecs, 1, -1 do
        if now - self.pendingSpecs[i].at > SPEC_WAIT then table.remove(self.pendingSpecs, i) end
    end
    local unknownName = UNKNOWNOBJECT or "Unknown"
    local current = {}
    for _, m in ipairs(M.Roster.GroupMembers()) do
        local arg = C.CLASS_BY_TOKEN[m.class or ""]
        if m.name and m.name ~= unknownName and arg then
            current[m.name] = true
            if not self.known[m.name] then
                for i, p in ipairs(self.pendingSpecs) do
                    if p.class == arg then
                        table.remove(self.pendingSpecs, i)
                        local name, spec = m.name, p.spec
                        M:After(SPEC_DELAY, function() M:Whisper(name, C.SpecPick(spec)) end)
                        break
                    end
                end
            end
        end
    end
    self.known = current
    if #self.pendingSpecs > 0 and not self.recheck then
        self.recheck = true
        M:After(1, function()
            self.recheck = false
            self:OnGroupChanged()
        end)
    end
end
