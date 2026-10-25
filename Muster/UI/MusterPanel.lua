-- Muster tab: pick a template and raise the whole group in one go.
Muster = Muster or {}
local M = Muster
local L = M.L
local W = M.Widgets
local R = M.Roster
local T = M.Templates

local P = { label = L.TAB_MUSTER }
M.Panels = M.Panels or {}
M.Panels.muster = P

local function describe(tpl)
    local total, tanks, heals, dps = T.Summary(tpl)
    local counts, order = {}, {}
    for _, s in ipairs(tpl.slots) do
        local key = s.class .. " (" .. s.spec .. ")"
        if not counts[key] then table.insert(order, key) end
        counts[key] = (counts[key] or 0) + 1
    end
    local lines = { L.TEMPLATE_SLOTS:format(total, tanks, heals, dps) }
    for _, key in ipairs(order) do
        table.insert(lines, ("%dx %s"):format(counts[key], key))
    end
    return table.concat(lines, "\n")
end

function P:Create(panel)
    self.panel = panel
    self.buttons = {}
    self.selected = T:All()[1]

    local prev
    for _, tpl in ipairs(T:All()) do
        local b = W.Button(panel, tpl.name, 170, 22)
        if prev then
            b:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -3)
        else
            b:SetPoint("TOPLEFT", 0, 0)
        end
        b:SetScript("OnClick", function()
            P.selected = tpl
            P:Refresh()
        end)
        self.buttons[tpl.id] = b
        prev = b
    end

    self.detail = W.Label(panel, "", "GameFontHighlightSmall")
    self.detail:SetPoint("TOPLEFT", 180, -2)
    self.detail:SetWidth(170)
    self.detail:SetJustifyV("TOP")

    local fill = W.Check(panel, L.FILL_MISSING, L.FILL_MISSING_TIP)
    fill:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", -2, -14)
    fill:SetScript("OnClick", function(c) M.db.fillMissing = c:GetChecked() and true or false end)
    self.fill = fill

    local specs = W.Check(panel, L.PICK_SPECS, L.PICK_SPECS_TIP)
    specs:SetPoint("TOPLEFT", fill, "BOTTOMLEFT", 0, -2)
    specs:SetScript("OnClick", function(c) M.db.pickSpecs = c:GetChecked() and true or false end)
    self.specs = specs

    local raise = W.Button(panel, L.RAISE, 100, 24)
    raise:SetPoint("TOPLEFT", specs, "BOTTOMLEFT", 2, -12)
    raise:SetScript("OnClick", function() if P.selected then T:Raise(P.selected) end end)

    local stop = W.Button(panel, L.STOP, 70, 24)
    stop:SetPoint("LEFT", raise, "RIGHT", 6, 0)
    stop:SetScript("OnClick", function() T:Stop() end)

    local dismiss = W.Button(panel, L.DISMISS_ALL, 150, 24)
    dismiss:SetPoint("LEFT", stop, "RIGHT", 6, 0)
    dismiss:SetScript("OnClick", function() R:DismissGroupBots() end)

    self.progress = W.Label(panel, "", "GameFontNormal")
    self.progress:SetPoint("TOPLEFT", raise, "BOTTOMLEFT", 0, -10)

    M:On("RAISE", function(index, total, name)
        if index then
            P.progress:SetText(L.RAISING:format(name, index, total))
        else
            P.progress:SetText("")
        end
    end)
end

function P:Refresh()
    if not self.panel then return end
    for id, b in pairs(self.buttons) do
        if self.selected and self.selected.id == id then b:LockHighlight() else b:UnlockHighlight() end
    end
    self.detail:SetText(self.selected and describe(self.selected) or "")
    self.fill:SetChecked(M.db.fillMissing)
    self.specs:SetChecked(M.db.pickSpecs)
end
