-- Orders tab: choose who listens, then click an order.
Muster = Muster or {}
local M = Muster
local L = M.L
local W = M.Widgets
local C = M.Commands
local R = M.Roster

local P = { label = L.TAB_ORDERS }
M.Panels = M.Panels or {}
M.Panels.orders = P

local TARGETS = { "all", "tank", "heal", "dps", "melee", "ranged", "selected" }
local LABELS = {
    all = L.TARGET_ALL, tank = L.TARGET_TANKS, heal = L.TARGET_HEALERS, dps = L.TARGET_DPS,
    melee = L.TARGET_MELEE, ranged = L.TARGET_RANGED, selected = L.TARGET_SELECTED,
}

function P:Create(panel)
    self.panel = panel
    self.targets = {}

    for i, key in ipairs(TARGETS) do
        local c = W.Check(panel, LABELS[key])
        local col, line = (i - 1) % 3, math.floor((i - 1) / 3)
        c:SetPoint("TOPLEFT", col * 116, -line * 24)
        c:SetScript("OnClick", function()
            M.db.orderTarget = key
            P:Refresh()
        end)
        self.targets[key] = c
    end

    self.sentTo = W.Label(panel, "", "GameFontHighlightSmall")
    self.sentTo:SetPoint("TOPLEFT", 2, -80)

    for i, order in ipairs(C.ORDERS) do
        local b = W.Button(panel, order.label, 110, 24)
        local col, line = (i - 1) % 3, math.floor((i - 1) / 3)
        b:SetPoint("TOPLEFT", col * 116, -100 - line * 28)
        W.Tooltip(b, order.label, order.tip .. "\n|cff808080" .. order.text .. "|r")
        b:SetScript("OnClick", function() M:GiveOrder(order.key) end)
    end

    M:On("SELECTION", function() P:Refresh() end)
end

function P:Refresh()
    if not self.panel then return end
    local target = M.db.orderTarget or "all"
    for key, c in pairs(self.targets) do c:SetChecked(key == target) end
    local who = LABELS[target]
    if target == "selected" then who = R:FocusBot() or L.NO_BOT_SELECTED end
    self.sentTo:SetText(L.ORDERS_SENT_TO:format(who))
end
