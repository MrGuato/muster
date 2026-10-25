-- Muster core: saved settings, a small timer, events, the message bus the
-- panels listen on, and the /muster slash command.
Muster = Muster or {}
local M = Muster
local L = M.L

M.VERSION = "0.2.0"

-- 148 degrees: clear of the minimap buttons other bot addons start at.
M.MINIMAP_ANGLE = 148

M.DEFAULTS = {
    minimap = { angle = M.MINIMAP_ANGLE or 148, hide = false },
    bar = { hide = false },
    frame = {},
    hideRosterMessage = true, -- keep "Bot roster: ..." out of the chat frame when Muster asked for it
    addDelay = 1.2,           -- seconds between bot logins while raising a template
    fillMissing = true,
    pickSpecs = true,
    orderTarget = "all",
}

-- Fill missing keys of `dst` from `src`, recursing into tables.
function M.CopyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            M.CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

function M.Trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M:Print(msg, ...)
    if select("#", ...) > 0 then msg = msg:format(...) end
    DEFAULT_CHAT_FRAME:AddMessage("|cffd1a246Muster|r: " .. msg)
end

---------------------------------------------------------------------------
-- Message bus: panels call M:On("ROSTER", fn) and redraw when it fires.
---------------------------------------------------------------------------
local listeners = {}

function M:On(message, fn)
    listeners[message] = listeners[message] or {}
    table.insert(listeners[message], fn)
end

function M:Fire(message, ...)
    for _, fn in ipairs(listeners[message] or {}) do fn(...) end
end

---------------------------------------------------------------------------
-- Timer. 3.3.5 has no C_Timer, so one hidden frame runs every pending call.
---------------------------------------------------------------------------
local timers = {}
local clock = 0
local driver = CreateFrame("Frame")
driver:Hide()
driver:SetScript("OnUpdate", function(self, elapsed)
    clock = clock + elapsed
    local i = 1
    while i <= #timers do
        local t = timers[i]
        if clock >= t.at then
            table.remove(timers, i)
            t.fn()
        else
            i = i + 1
        end
    end
    if #timers == 0 then self:Hide() end
end)

function M:After(seconds, fn)
    table.insert(timers, { at = clock + seconds, fn = fn })
    driver:Show()
end

-- Exposed for the tests, which drive the clock by hand.
M._timerDriver = driver

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
M.eventFrame = events

events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... == "Muster" then
            MusterDB = M.CopyDefaults(M.DEFAULTS, MusterDB or {})
            M.db = MusterDB
            -- Not in DEFAULTS: CopyDefaults would refill pins the player removed.
            if M.db.pinned == nil then
                M.db.pinned = { "order:follow", "order:stay", "order:attack", "order:flee" }
            end
            events:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        if M.CreateUI then M:CreateUI() end
        M:Print(L.LOADED, M.VERSION)
    elseif event == "CHAT_MSG_SYSTEM" then
        M.Roster:OnSystemMessage(...)
        M.Templates:OnSystemMessage(...)
    elseif event == "CHAT_MSG_WHISPER" then
        local msg, sender = ...
        M.Strategies:OnWhisper(sender, msg)
    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        M.Templates:OnGroupChanged()
        M:Fire("GROUP")
    end
end)

for _, e in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "CHAT_MSG_SYSTEM", "CHAT_MSG_WHISPER",
                     "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE" }) do
    events:RegisterEvent(e)
end

---------------------------------------------------------------------------
-- Slash command
---------------------------------------------------------------------------
local function keysOf(t)
    local out = {}
    for k in pairs(t) do table.insert(out, k) end
    table.sort(out)
    return table.concat(out, ", ")
end

function M:HandleSlash(input)
    input = M.Trim(input or "")
    local cmd, rest = input:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()

    if cmd == "" or cmd == "show" or cmd == "toggle" then
        M:Toggle()
    elseif cmd == "help" then
        for _, line in ipairs(L.HELP) do M:Print(line) end
    elseif cmd == "list" or cmd == "roster" then
        M.Roster:Refresh()
    elseif cmd == "add" and rest ~= "" then
        M:SendServerCommand(M.Commands.Add(rest))
    elseif (cmd == "remove" or cmd == "rm") and rest ~= "" then
        M:SendServerCommand(M.Commands.Remove(rest))
    elseif cmd == "class" or cmd == "addclass" then
        local token = M.Commands.ClassArg(rest)
        if token then
            M:SendServerCommand(M.Commands.AddClass(token))
        else
            M:Print(L.UNKNOWN_CLASS, rest, table.concat(M.Commands.CLASS_ARGS, ", "))
        end
    elseif cmd == "raise" then
        local tpl = M.Templates:Get(rest:lower())
        if tpl then
            M.Templates:Raise(tpl)
        else
            M:Print(L.UNKNOWN_TEMPLATE, rest, M.Templates:IdList())
        end
    elseif cmd == "stop" then
        M.Templates:Stop()
    elseif cmd == "order" then
        local key, filter = rest:lower():match("^(%S+)%s*(%S*)$")
        if key and M.Commands.ORDER_BY_KEY[key] then
            if filter ~= "" then M:Order(key, filter) else M:GiveOrder(key) end
        else
            M:Print(L.UNKNOWN_ORDER, key or "", keysOf(M.Commands.ORDER_BY_KEY))
        end
    elseif cmd == "minimap" then
        if rest:lower() == "reset" then
            M.db.minimap.angle = M.MINIMAP_ANGLE
            M.db.minimap.hide = false
            if M.PlaceMinimapButton then M:PlaceMinimapButton() end
        else
            M.db.minimap.hide = not M.db.minimap.hide
        end
        if M.UpdateMinimapButton then M:UpdateMinimapButton() end
    elseif cmd == "bar" then
        if M.ToggleBar then M:ToggleBar() end
    else
        M:Print(L.UNKNOWN_COMMAND, input)
    end
end

-- The panel module replaces this once the UI exists.
function M:Toggle() end

SLASH_MUSTER1 = "/muster"
SLASH_MUSTER2 = "/mu"
SlashCmdList.MUSTER = function(input) M:HandleSlash(input) end
