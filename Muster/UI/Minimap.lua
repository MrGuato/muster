-- Minimap button: left-click toggles the window, right-click refreshes the
-- roster, drag moves it around the minimap edge.
Muster = Muster or {}
local M = Muster
local L = M.L

local RADIUS = 80

local function place(button)
    local angle = math.rad(M.db.minimap.angle or 200)
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * RADIUS, math.sin(angle) * RADIUS)
end

local function dragUpdate(button)
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    M.db.minimap.angle = math.deg(math.atan2(py - my, px - mx))
    button:ClearAllPoints()
    place(button)
end

function M:CreateMinimapButton()
    if self.minimapButton then return end
    local b = CreateFrame("Button", "MusterMinimapButton", Minimap)
    b:SetWidth(31)
    b:SetHeight(31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetWidth(20)
    bg:SetHeight(20)
    bg:SetPoint("TOPLEFT", 7, -5)

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(M.ICON)
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("TOPLEFT", 7, -5)

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetWidth(53)
    border:SetHeight(53)
    border:SetPoint("TOPLEFT")

    b:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            M.Roster:Refresh()
        elseif IsShiftKeyDown() then
            M:ToggleBar()
        else
            M:Toggle()
        end
    end)
    b:SetScript("OnDragStart", function(btn) btn:SetScript("OnUpdate", dragUpdate) end)
    b:SetScript("OnDragStop", function(btn) btn:SetScript("OnUpdate", nil) end)
    b:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
        GameTooltip:SetText(L.TITLE, 1, 1, 1)
        GameTooltip:AddLine(L.MINIMAP_TIP_LEFT)
        GameTooltip:AddLine(L.MINIMAP_TIP_RIGHT)
        GameTooltip:AddLine(L.MINIMAP_TIP_SHIFT)
        GameTooltip:AddLine(L.MINIMAP_TIP_DRAG)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.minimapButton = b
    place(b)
    self:UpdateMinimapButton()
end

function M:PlaceMinimapButton()
    if not self.minimapButton then return end
    self.minimapButton:ClearAllPoints()
    place(self.minimapButton)
end

function M:UpdateMinimapButton()
    if not self.minimapButton then return end
    if self.db.minimap.hide then self.minimapButton:Hide() else self.minimapButton:Show() end
end

-- Built with the window at PLAYER_LOGIN.
local createUI = M.CreateUI
function M:CreateUI()
    createUI(self)
    self:CreateMinimapButton()
end
