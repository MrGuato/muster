-- The Muster window: a movable dialog with one tab per panel. Panel files
-- register themselves in M.Panels; the window is built at PLAYER_LOGIN.
Muster = Muster or {}
local M = Muster
local L = M.L
local W = M.Widgets

M.Panels = M.Panels or {}
M.ICON = "Interface\\AddOns\\Muster\\Media\\muster"

local TAB_ORDER = { "roster", "muster", "orders", "strategies" }

local function savePosition(frame)
    local point, _, relPoint, x, y = frame:GetPoint()
    M.db.frame = { point = point, relPoint = relPoint, x = x, y = y }
end

function M:CreateUI()
    if self.frame then return end

    local f = CreateFrame("Frame", "MusterFrame", UIParent)
    f:SetWidth(390)
    f:SetHeight(460)
    local pos = M.db.frame
    if pos and pos.point then
        f:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        f:SetPoint("CENTER")
    end
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        savePosition(frame)
    end)
    f:Hide()
    table.insert(UISpecialFrames, "MusterFrame") -- Escape closes it

    local header = f:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetWidth(256)
    header:SetHeight(64)
    header:SetPoint("TOP", 0, 12)
    local title = W.Label(f, L.TITLE)
    title:SetPoint("TOP", header, "TOP", 0, -14)

    local icon = f:CreateTexture(nil, "OVERLAY")
    icon:SetTexture(M.ICON)
    icon:SetWidth(28)
    icon:SetHeight(28)
    icon:SetPoint("TOPLEFT", 18, -16)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    f.tabs, f.panels = {}, {}
    local prev
    for _, key in ipairs(TAB_ORDER) do
        local def = M.Panels[key]
        local tab = W.Button(f, def.label, 86, 22)
        if prev then
            tab:SetPoint("LEFT", prev, "RIGHT", 2, 0)
        else
            tab:SetPoint("TOPLEFT", 20, -48)
        end
        tab:SetScript("OnClick", function() M:ShowTab(key) end)
        f.tabs[key] = tab
        prev = tab

        local panel = CreateFrame("Frame", nil, f)
        panel:SetPoint("TOPLEFT", 20, -78)
        panel:SetPoint("BOTTOMRIGHT", -20, 18)
        panel:Hide()
        def:Create(panel)
        f.panels[key] = panel
    end

    self.frame = f
    f:SetScript("OnShow", function() M:ShowTab(M.activeTab or "roster") end)
    M:ShowTab("roster")
end

function M:ShowTab(key)
    local f = self.frame
    if not f then return end
    for k, panel in pairs(f.panels) do
        if k == key then
            panel:Show()
            f.tabs[k]:LockHighlight()
            local def = M.Panels[k]
            if def.Refresh then def:Refresh() end
        else
            panel:Hide()
            f.tabs[k]:UnlockHighlight()
        end
    end
    self.activeTab = key
end

function M:Toggle()
    if not self.frame then self:CreateUI() end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end
