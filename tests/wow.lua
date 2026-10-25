-- A small stand-in for the WoW 3.3.5 API: enough to load Muster from its
-- .toc, fire events, run its timer, and click its buttons. Every chat line
-- the addon sends lands in wow.sent; every chat-frame print in wow.printed.
local wow = { sent = {}, printed = {}, clock = 0, group = { kind = nil, members = {} } }

unpack = unpack or table.unpack -- luacheck: ignore

---------------------------------------------------------------------------
-- Frames
---------------------------------------------------------------------------
local Frame = {}
local function noop() end
local FrameMT = {
    __index = function(_, key)
        local method = Frame[key]
        if method then return method end
        -- Widget methods are CamelCase; any the tests don't care about do nothing.
        -- Anything else is an unset field, which a real frame reads as nil.
        if type(key) == "string" and key:find("^%u") then return noop end
        return nil
    end,
}

local function newFrame(kind, name, parent)
    local f = setmetatable({ _kind = kind, _name = name, _parent = parent, _shown = true,
                             _scripts = {}, _events = {}, _text = "" }, FrameMT)
    if name then _G[name] = f end
    return f
end

function Frame:Show() self._shown = true; if self._scripts.OnShow then self._scripts.OnShow(self) end end
function Frame:Hide() self._shown = false end
function Frame:IsShown() return self._shown end
function Frame:IsVisible()
    if not self._shown then return false end
    if self._parent and self._parent.IsVisible then return self._parent:IsVisible() end
    return true
end
function Frame:SetScript(event, fn) self._scripts[event] = fn end
function Frame:GetScript(event) return self._scripts[event] end
function Frame:RegisterEvent(event) self._events[event] = true end
function Frame:UnregisterEvent(event) self._events[event] = nil end
function Frame:CreateTexture() return newFrame("Texture", nil, self) end
function Frame:CreateFontString() return newFrame("FontString", nil, self) end
function Frame:SetText(text) self._text = text end
function Frame:GetText() return self._text end
function Frame:SetChecked(on) self._checked = on and 1 or nil end
function Frame:GetChecked() return self._checked end -- 3.3.5 returns 1 or nil
function Frame:SetPoint(...) self._point = { ... } end
function Frame:GetPoint() return unpack(self._point or { "CENTER", nil, "CENTER", 0, 0 }) end
function Frame:GetCenter() return 0, 0 end
function Frame:GetEffectiveScale() return 1 end
function Frame:Click(button)
    local fn = self._scripts.OnClick
    assert(fn, "clicked a frame with no OnClick")
    fn(self, button or "LeftButton")
end

function wow.CreateFrame(kind, name, parent)
    local f = newFrame(kind, name, parent)
    wow.frames = wow.frames or {}
    table.insert(wow.frames, f)
    return f
end

---------------------------------------------------------------------------
-- Globals the addon uses
---------------------------------------------------------------------------
function wow.install()
    CreateFrame = wow.CreateFrame
    UIParent = newFrame("Frame", "UIParent")
    Minimap = newFrame("Minimap", "Minimap")
    GameTooltip = newFrame("GameTooltip", "GameTooltip")
    UISpecialFrames = {}
    SlashCmdList = {}
    DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) table.insert(wow.printed, msg) end }
    SendChatMessage = function(msg, channel, _, target)
        table.insert(wow.sent, { msg = msg, channel = channel, target = target })
    end
    ChatFrame_AddMessageEventFilter = function(event, fn)
        wow.chatFilters = wow.chatFilters or {}
        wow.chatFilters[event] = fn
    end
    GetTime = function() return wow.clock end
    GetCursorPosition = function() return 0, 0 end
    IsShiftKeyDown = function() return false end
    GetNumRaidMembers = function() return wow.group.kind == "raid" and #wow.group.members + 1 or 0 end
    GetNumPartyMembers = function() return wow.group.kind and #wow.group.members or 0 end
    local function member(unit)
        if unit == "player" then return { name = "Guato", class = "WARRIOR" } end
        local i = tonumber(unit:match("^party(%d+)$") or unit:match("^raid(%d+)$") or "")
        if not i then return nil end
        if unit:find("^raid") then
            if i == 1 then return { name = "Guato", class = "WARRIOR", isPlayer = true } end
            return wow.group.members[i - 1]
        end
        return wow.group.members[i]
    end
    UnitExists = function(unit)
        if unit == "target" then return wow.target ~= nil end
        return member(unit) ~= nil
    end
    UnitName = function(unit)
        if unit == "target" then return wow.target end
        local m = member(unit)
        return m and m.name
    end
    UnitClass = function(unit)
        local m = member(unit)
        if m then return m.class, m.class end
    end
    UnitIsUnit = function(a, b)
        if a == b then return true end
        local m = member(a)
        return b == "player" and m and m.name == "Guato" or false
    end
    UnitIsPlayer = function() return true end
    FauxScrollFrame_Update = noop
    FauxScrollFrame_GetOffset = function() return 0 end
    FauxScrollFrame_OnVerticalScroll = function(_, _, _, fn) fn() end
    RAID_CLASS_COLORS = {
        WARRIOR = { r = 0.78, g = 0.61, b = 0.43 }, PRIEST = { r = 1, g = 1, b = 1 },
        MAGE = { r = 0.41, g = 0.8, b = 0.94 }, DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
    }
    CLASS_ICON_TCOORDS = setmetatable({}, { __index = function() return { 0, 0.25, 0, 0.25 } end })
end

---------------------------------------------------------------------------
-- Driving the addon
---------------------------------------------------------------------------
function wow.loadAddon(root)
    local toc = assert(io.open(root .. "/Muster.toc")):read("*a")
    wow.tocFiles = {}
    for line in toc:gmatch("[^\r\n]+") do
        if not line:find("^##") and line:find("%S") then
            local path = line:gsub("\\", "/"):gsub("%s+$", "")
            table.insert(wow.tocFiles, path)
            dofile(root .. "/" .. path)
        end
    end
end

function wow.fire(event, ...)
    local handler = Muster.eventFrame:GetScript("OnEvent")
    handler(Muster.eventFrame, event, ...)
end

-- Move the clock forward, running the addon's timer the way OnUpdate would.
function wow.advance(seconds)
    local step = 0.1
    local driver = Muster._timerDriver
    for _ = 1, math.floor(seconds / step + 0.5) do
        wow.clock = wow.clock + step
        if driver:IsShown() then driver:GetScript("OnUpdate")(driver, step) end
    end
end

function wow.reset()
    wow.sent, wow.printed = {}, {}
end

function wow.setGroup(kind, members)
    wow.group = { kind = kind, members = members or {} }
end

return wow
