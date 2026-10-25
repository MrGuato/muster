-- Strategies tab: read a bot's strategies and switch them on or off.
Muster = Muster or {}
local M = Muster
local L = M.L
local W = M.Widgets
local R = M.Roster
local S = M.Strategies

local P = { label = L.TAB_STRATEGIES, wholeGroup = false }
M.Panels = M.Panels or {}
M.Panels.strategies = P

function P:Create(panel)
    self.panel = panel
    self.boxes = { co = {}, nc = {} }

    self.title = W.Label(panel, "", "GameFontNormal")
    self.title:SetPoint("TOPLEFT", 2, -4)
    self.title:SetWidth(220)

    local read = W.Button(panel, L.READ_STRATEGIES, 120)
    read:SetPoint("TOPRIGHT", 0, 0)
    read:SetScript("OnClick", function()
        local bot = R:FocusBot()
        if bot then S:Query(bot) else M:Print(L.NO_BOT_SELECTED) end
    end)

    local group = W.Check(panel, L.WHOLE_GROUP, L.WHOLE_GROUP_TIP)
    group:SetPoint("TOPLEFT", 0, -24)
    group:SetScript("OnClick", function(c)
        P.wholeGroup = c:GetChecked() and true or false
        P:Refresh()
    end)
    self.group = group

    self.hint = W.Label(panel, L.STRATEGIES_UNKNOWN, "GameFontDisableSmall")
    self.hint:SetPoint("TOPLEFT", 2, -52)
    self.hint:SetWidth(340)

    local columns = { { "co", L.COMBAT, 0 }, { "nc", L.NONCOMBAT, 176 } }
    for _, col in ipairs(columns) do
        local which, heading, x = col[1], col[2], col[3]
        local head = W.Label(panel, heading, "GameFontNormalSmall")
        head:SetPoint("TOPLEFT", x + 2, -72)
        for i, entry in ipairs(S.LIST[which]) do
            local c = W.Check(panel, entry.name, entry.tip)
            c:SetPoint("TOPLEFT", x, -86 - (i - 1) * 24)
            c:SetScript("OnClick", function(box)
                local on = box:GetChecked() and true or false
                if P.wholeGroup then
                    S:Set(nil, which, entry.name, on)
                else
                    local bot = R:FocusBot()
                    if not bot then
                        M:Print(L.NO_BOT_SELECTED)
                        box:SetChecked(not on)
                        return
                    end
                    S:Set(bot, which, entry.name, on)
                end
            end)
            self.boxes[which][entry.name] = c
        end
    end

    M:On("STRATEGIES", function() P:Refresh() end)
    M:On("SELECTION", function() P:Refresh() end)
    local targetWatch = CreateFrame("Frame", nil, panel)
    targetWatch:RegisterEvent("PLAYER_TARGET_CHANGED")
    targetWatch:SetScript("OnEvent", function() P:Refresh() end)
end

function P:Refresh()
    if not self.panel or not self.panel:IsVisible() then return end
    local bot = R:FocusBot()
    if self.wholeGroup then
        self.title:SetText(L.WHOLE_GROUP)
    else
        self.title:SetText(bot and L.STRATEGIES_FOR:format(bot) or L.NO_BOT_SELECTED)
    end
    self.group:SetChecked(self.wholeGroup)
    local known = bot and (S:Get(bot, "co") or S:Get(bot, "nc"))
    W.SetShown(self.hint, not self.wholeGroup and not known)
    for which, boxes in pairs(self.boxes) do
        local set = (not self.wholeGroup and bot) and S:Get(bot, which) or nil
        for name, c in pairs(boxes) do c:SetChecked(set and set[name] or false) end
    end
end
