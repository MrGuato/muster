-- The bot roster: every character the server lets you log in as a bot, from
-- the reply to ".playerbot bot list", plus who is in your group right now.
Muster = Muster or {}
local M = Muster
local C = M.Commands

local R = { bots = {}, selected = {}, awaiting = false }
M.Roster = R

local PREFIX = "Bot roster: "

-- "Bot roster: +Aldric Warrior, -Mira Priest, +Vol DeathKnight"
-- -> { {name="Aldric", class="WARRIOR", online=true}, ... } sorted by name, or nil
-- when the message is something else.
function R.Parse(msg)
    if type(msg) ~= "string" or msg:sub(1, #PREFIX) ~= PREFIX then return nil end
    local list, seen = {}, {}
    for entry in msg:sub(#PREFIX + 1):gmatch("[^,]+") do
        local flag, name, class = M.Trim(entry):match("^([+-])(%S+)%s*(.*)$")
        if name and not seen[name] then
            seen[name] = true
            table.insert(list, { name = name, class = C.ClassToken(class), online = flag == "+" })
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

function R:Refresh()
    self.awaiting = true
    self.token = (self.token or 0) + 1
    local token = self.token
    M:SendServerCommand(C.List())
    -- Stop hiding roster messages if the server never answers this request.
    M:After(5, function()
        if self.token == token then self.awaiting = false end
    end)
end

function R:OnSystemMessage(msg)
    local list = R.Parse(msg)
    if not list then return false end
    self.bots = list
    -- The chat frames filter this same message after (or before) us, so keep
    -- hiding until the next frame.
    M:After(0, function() self.awaiting = false end)
    local online = 0
    for _, b in ipairs(list) do if b.online then online = online + 1 end end
    M:Fire("ROSTER", #list, online)
    if self.dismissWaiting then
        self.dismissWaiting = false
        self:RemoveGroupBots()
    end
    return true
end

-- Log out every group member the roster lists as one of your online bots.
-- Real players are never in that list, so they are left alone.
function R:RemoveGroupBots()
    local names = {}
    for _, m in ipairs(R.GroupMembers()) do
        local bot = self:Find(m.name)
        if bot and bot.online then table.insert(names, m.name) end
    end
    if #names > 0 then
        M:RemoveBots(names)
    else
        M:Print(M.L.NO_GROUP_BOTS)
    end
end

-- Refresh first, so bots that joined since the last refresh are included.
function R:DismissGroupBots()
    self.dismissWaiting = true
    self:Refresh()
end

-- Hide the raw roster line from chat when Muster asked for it. 3.3.5 calls
-- filters as (chatFrame, event, msg, ...); accept (event, msg, ...) too.
function R.ChatFilter(a, b, c)
    local msg = c
    if type(a) == "string" and a:find("^CHAT_MSG") then msg = b end
    if R.awaiting and M.db and M.db.hideRosterMessage and type(msg) == "string"
        and msg:sub(1, #PREFIX) == PREFIX then
        return true
    end
    return false
end
if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", R.ChatFilter)
end

function R:Find(name)
    for _, b in ipairs(self.bots) do
        if b.name == name then return b end
    end
    return nil
end

-- Selection, for the Roster buttons and the Strategies tab.
function R:Select(name, additive)
    if not additive then self.selected = {} end
    if name then
        if additive and self.selected[name] then
            self.selected[name] = nil
        else
            self.selected[name] = true
        end
    end
    M:Fire("SELECTION")
end

function R:SelectedNames()
    local out = {}
    for name in pairs(self.selected) do table.insert(out, name) end
    table.sort(out)
    return out
end

-- The one bot the Strategies tab works on: a single selection, else your target.
function R:FocusBot()
    local names = self:SelectedNames()
    if #names == 1 then return names[1] end
    if UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target", "player") then
        return (UnitName("target"))
    end
    return nil
end

-- Members of your group other than you, with class tokens.
function R.GroupMembers()
    local out = {}
    local raid = GetNumRaidMembers()
    if raid > 0 then
        for i = 1, raid do
            local unit = "raid" .. i
            if UnitExists(unit) and not UnitIsUnit(unit, "player") then
                local _, token = UnitClass(unit)
                table.insert(out, { name = (UnitName(unit)), class = token })
            end
        end
    else
        for i = 1, GetNumPartyMembers() do
            local unit = "party" .. i
            if UnitExists(unit) then
                local _, token = UnitClass(unit)
                table.insert(out, { name = (UnitName(unit)), class = token })
            end
        end
    end
    return out
end
