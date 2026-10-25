-- The command bar: a row of category icons with your pinned shortcuts beside
-- them. Clicking a category opens a column of its commands above it. Left-click
-- a command to run it (shift-click turns a strategy off), right-click it to
-- pin or unpin it. Drag the banner at the left end to move the bar.
Muster = Muster or {}
local M = Muster
local L = M.L
local A = M.Actions

local SIZE, GAP = 32, 4

local B = {}
M.CommandBar = B

local function tooltip(button, action)
    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    GameTooltip:SetText(action.title, 1, 0.82, 0)
    if action.tip then GameTooltip:AddLine(action.tip, 1, 1, 1, true) end
    if action.send then GameTooltip:AddLine(L.TIP_SENDS:format(action.send), 0.5, 0.75, 1, true) end
    if action.targeted then GameTooltip:AddLine(L.TIP_GOES_TO:format(M:TargetLabel()), 0.6, 0.6, 0.6) end
    GameTooltip:AddLine(action.toggle and L.TIP_CLICK_TOGGLE or L.TIP_CLICK_RUN, 0.6, 0.6, 0.6)
    GameTooltip:AddLine(A:IsPinned(action.id) and L.TIP_UNPIN or L.TIP_PIN, 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

local function setIcon(button, action)
    button.icon:SetTexture(action.icon)
    local coords = action.classToken and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[action.classToken]
    if coords then
        button.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    else
        button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- trim the icon's own border
    end
end

local function iconButton(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(SIZE)
    b:SetHeight(SIZE)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    return b
end

-- A button that runs `action`: left-click runs, right-click pins/unpins.
local function actionButton(parent, action)
    local b = iconButton(parent)
    b.action = action
    setIcon(b, action)
    b:SetScript("OnClick", function(self, mouse)
        if mouse == "RightButton" then
            A:TogglePin(self.action.id)
        else
            self.action.run(IsShiftKeyDown())
        end
        if GameTooltip:IsOwned(self) then tooltip(self, self.action) end
    end)
    b:SetScript("OnEnter", function(self) tooltip(self, self.action) end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

function B:Create()
    if self.frame then return end
    local f = CreateFrame("Frame", "MusterCommandBar", UIParent)
    f:SetHeight(SIZE + 12)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0, 0, 0, 0.8)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    local pos = M.db.bar.point
    if pos then
        f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 170)
    end

    -- The banner at the left end: drag to move, click to open the window.
    local handle = iconButton(f)
    handle:SetPoint("LEFT", 6, 0)
    handle.icon:SetTexture(M.ICON)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function() f:StartMoving() end)
    handle:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local point, _, relPoint, x, y = f:GetPoint()
        M.db.bar.point = { point, relPoint, x, y }
    end)
    handle:SetScript("OnClick", function() M:Toggle() end)
    handle:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText(L.TITLE, 1, 0.82, 0)
        GameTooltip:AddLine(L.BAR_HANDLE_TIP, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    handle:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Category buttons, each with a column of its actions above it.
    self.columns = {}
    local prev = handle
    for _, cat in ipairs(A.categories) do
        local b = iconButton(f)
        b:SetPoint("LEFT", prev, "RIGHT", GAP + (prev == handle and 4 or 0), 0)
        b.icon:SetTexture(cat.icon)
        b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        b:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_TOP")
            GameTooltip:SetText(cat.title, 1, 0.82, 0)
            GameTooltip:AddLine(L.BAR_CATEGORY_TIP, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)

        local column = CreateFrame("Frame", nil, f)
        column:SetWidth(SIZE)
        column:SetHeight(#cat.actions * (SIZE + GAP))
        column:SetPoint("BOTTOM", b, "TOP", 0, GAP + 6)
        column:Hide()
        for i, action in ipairs(cat.actions) do
            local ab = actionButton(column, action)
            ab:SetPoint("BOTTOM", column, "BOTTOM", 0, (i - 1) * (SIZE + GAP))
        end
        self.columns[cat.id] = column
        b:SetScript("OnClick", function() B:OpenColumn(cat.id) end)
        b.category = cat.id
        self["cat_" .. cat.id] = b
        prev = b
    end

    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(1, 0.82, 0, 0.35)
    divider:SetWidth(1)
    divider:SetHeight(SIZE - 6)
    divider:SetPoint("LEFT", prev, "RIGHT", GAP + 2, 0)
    self.pinAnchor = divider
    self.firstPinX = 0
    self.pinButtons = {}

    self.frame = f
    M:On("PINS", function() B:LayoutPins() end)
    self:LayoutPins()
    self:Update()
end

-- Show one category's column; clicking its button again closes it.
function B:OpenColumn(id)
    for cid, column in pairs(self.columns) do
        if cid == id and not column:IsShown() then column:Show() else column:Hide() end
    end
end

function B:LayoutPins()
    for _, b in ipairs(self.pinButtons) do b:Hide() end
    local pins = A:Pins()
    local prev = self.pinAnchor
    local shown = 0
    for i, id in ipairs(pins) do
        local action = A.byId[id]
        if action then
            local b = self.pinButtons[i]
            if not b then
                b = actionButton(self.frame, action)
                self.pinButtons[i] = b
            end
            b.action = action
            setIcon(b, action)
            b:ClearAllPoints()
            b:SetPoint("LEFT", prev, "RIGHT", GAP + (prev == self.pinAnchor and 2 or 0), 0)
            b:Show()
            prev = b
            shown = shown + 1
        end
    end
    -- handle + gap + categories + divider + pins, with the backdrop's padding.
    local width = 12 + SIZE + 8 + #A.categories * (SIZE + GAP) + 8 + shown * (SIZE + GAP)
    self.frame:SetWidth(width + (shown == 0 and 0 or 2))
end

function B:Update()
    if not self.frame then return end
    if M.db.bar.hide then self.frame:Hide() else self.frame:Show() end
end

function M:ToggleBar()
    if not B.frame then B:Create() end
    M.db.bar.hide = not M.db.bar.hide
    B:Update()
end

-- Built with the window at PLAYER_LOGIN.
local createUI = M.CreateUI
function M:CreateUI()
    createUI(self)
    B:Create()
end
