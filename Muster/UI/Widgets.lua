-- Small builders for the stock 3.3.5 widgets the panels use.
Muster = Muster or {}
local M = Muster

local W = {}
M.Widgets = W

function W.Tooltip(frame, title, body)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        if body then GameTooltip:AddLine(body, nil, nil, nil, true) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function W.Button(parent, text, width, height)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetText(text)
    b:SetWidth(width or 80)
    b:SetHeight(height or 22)
    return b
end

function W.Check(parent, label, tip)
    local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    c:SetWidth(24)
    c:SetHeight(24)
    local text = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", c, "RIGHT", 1, 1)
    text:SetText(label)
    c.label = text
    if tip then W.Tooltip(c, label, tip) end
    return c
end

-- 3.3.5 has no SetShown, so show or hide by flag here.
function W.SetShown(region, shown)
    if shown then region:Show() else region:Hide() end
end

function W.Label(parent, text, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    fs:SetText(text or "")
    fs:SetJustifyH("LEFT")
    return fs
end

-- "|cffRRGGBB" for a class token, white when unknown.
function W.ClassColor(token)
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token or ""]
    if not c then return "|cffffffff" end
    return ("|cff%02x%02x%02x"):format(c.r * 255, c.g * 255, c.b * 255)
end

-- A class icon cut out of the character-create sheet every client has.
function W.ClassIcon(parent, token, size)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(size)
    b:SetHeight(size)
    local tex = b:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token]
    if coords then tex:SetTexCoord(coords[1], coords[2], coords[3], coords[4]) end
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    return b
end
