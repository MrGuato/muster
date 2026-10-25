-- Roster tab: your bots, who is online, add/remove by selection, by name or
-- by class.
Muster = Muster or {}
local M = Muster
local L = M.L
local W = M.Widgets
local C = M.Commands
local R = M.Roster

local ROWS, ROW_HEIGHT = 10, 20
local CLASS_TOKENS = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "DEATHKNIGHT" }

local P = { label = L.TAB_ROSTER }
M.Panels = M.Panels or {}
M.Panels.roster = P

local function inGroupSet()
    local set = {}
    for _, m in ipairs(R.GroupMembers()) do set[m.name] = true end
    return set
end

function P:Create(panel)
    self.panel = panel

    local refresh = W.Button(panel, L.REFRESH, 80)
    refresh:SetPoint("TOPLEFT", 0, 0)
    refresh:SetScript("OnClick", function() R:Refresh() end)

    local add = W.Button(panel, L.ADD, 70)
    add:SetPoint("LEFT", refresh, "RIGHT", 4, 0)
    add:SetScript("OnClick", function()
        local names = R:SelectedNames()
        if #names > 0 then M:SendServerCommand(C.Add(names)) end
    end)

    local remove = W.Button(panel, L.REMOVE, 70)
    remove:SetPoint("LEFT", add, "RIGHT", 4, 0)
    remove:SetScript("OnClick", function()
        local names = R:SelectedNames()
        if #names > 0 then M:SendServerCommand(C.Remove(names)) end
    end)

    self.count = W.Label(panel, "", "GameFontHighlightSmall")
    self.count:SetPoint("LEFT", remove, "RIGHT", 8, 0)

    local scroll = CreateFrame("ScrollFrame", "MusterRosterScroll", panel, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -28)
    scroll:SetWidth(328)
    scroll:SetHeight(ROWS * ROW_HEIGHT)
    scroll:SetScript("OnVerticalScroll", function(s, offset)
        FauxScrollFrame_OnVerticalScroll(s, offset, ROW_HEIGHT, function() P:Refresh() end)
    end)
    self.scroll = scroll

    self.rows = {}
    for i = 1, ROWS do
        local row = CreateFrame("Button", nil, panel)
        row:SetWidth(328)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        local sel = row:CreateTexture(nil, "BACKGROUND")
        sel:SetAllPoints()
        sel:SetTexture(0.82, 0.64, 0.27, 0.25)
        sel:Hide()
        row.sel = sel
        row.name = W.Label(row, "", "GameFontHighlight")
        row.name:SetPoint("LEFT", 6, 0)
        row.class = W.Label(row, "", "GameFontDisableSmall")
        row.class:SetPoint("LEFT", 140, 0)
        row.status = W.Label(row, "", "GameFontHighlightSmall")
        row.status:SetPoint("RIGHT", -6, 0)
        row:SetScript("OnClick", function(r)
            if r.botName then R:Select(r.botName, IsShiftKeyDown()) end
        end)
        self.rows[i] = row
    end

    self.empty = W.Label(panel, L.ROSTER_EMPTY, "GameFontDisable")
    self.empty:SetPoint("TOPLEFT", scroll, "TOPLEFT", 6, -6)
    self.empty:SetWidth(320)

    local hint = W.Label(panel, L.ROSTER_HINT, "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", scroll, "BOTTOMLEFT", 0, -4)

    -- Add by name
    local box = CreateFrame("EditBox", "MusterAddNameBox", panel, "InputBoxTemplate")
    box:SetWidth(200)
    box:SetHeight(20)
    box:SetAutoFocus(false)
    box:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 6, -10)
    local byName = W.Button(panel, L.ADD_BY_NAME, 110)
    byName:SetPoint("LEFT", box, "RIGHT", 8, 0)
    local function addTyped()
        local text = M.Trim(box:GetText() or "")
        if text ~= "" then M:SendServerCommand(C.Add(text)) end
        box:SetText("")
        box:ClearFocus()
    end
    byName:SetScript("OnClick", addTyped)
    box:SetScript("OnEnterPressed", addTyped)
    box:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)

    -- Add by class
    local prev
    for i, token in ipairs(CLASS_TOKENS) do
        local icon = W.ClassIcon(panel, token, 30)
        if prev then
            icon:SetPoint("LEFT", prev, "RIGHT", 4, 0)
        else
            icon:SetPoint("TOPLEFT", box, "BOTTOMLEFT", -6, -12)
        end
        local arg = C.CLASS_BY_TOKEN[token]
        W.Tooltip(icon, L.ADD_BY_CLASS, arg)
        icon:SetScript("OnClick", function() M:SendServerCommand(C.AddClass(arg)) end)
        prev = icon
        self["class" .. i] = icon
    end

    M:On("ROSTER", function(total, online)
        -- With the window open the list says it all; otherwise say it in chat.
        if not (M.frame and M.frame:IsShown()) then M:Print(L.ROSTER_UPDATED, total, online) end
        P:Refresh()
    end)
    M:On("SELECTION", function() P:Refresh() end)
    M:On("GROUP", function() P:Refresh() end)
end

function P:Refresh()
    if not self.panel or not self.panel:IsVisible() then return end
    local bots = R.bots
    local inGroup = inGroupSet()
    FauxScrollFrame_Update(self.scroll, #bots, ROWS, ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(self.scroll)
    local online = 0
    for _, b in ipairs(bots) do if b.online then online = online + 1 end end
    self.count:SetText(("%d / %d %s"):format(online, #bots, L.ONLINE:lower()))
    W.SetShown(self.empty, #bots == 0)

    for i, row in ipairs(self.rows) do
        local b = bots[offset + i]
        if b then
            row.botName = b.name
            row.name:SetText(W.ClassColor(b.class) .. b.name .. "|r")
            row.class:SetText(b.class:sub(1, 1) .. b.class:sub(2):lower())
            local status = b.online and ("|cff40ff40" .. L.ONLINE .. "|r") or ("|cff808080" .. L.OFFLINE .. "|r")
            if inGroup[b.name] then status = "|cffd1a246" .. L.IN_GROUP .. "|r  " .. status end
            row.status:SetText(status)
            W.SetShown(row.sel, R.selected[b.name] == true)
            row:Show()
        else
            row.botName = nil
            row:Hide()
        end
    end
end
