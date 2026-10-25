-- Muster's tests. Run from the repo root:  lua5.1 tests/run.lua
package.path = "tests/?.lua;" .. package.path
local wow = require("wow")

local passed, failed = 0, {}
local function test(name, fn)
    wow.reset()
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
    else
        table.insert(failed, name .. "\n    " .. tostring(err))
    end
end

local function eq(actual, expected, what)
    if actual ~= expected then
        error(("%s: expected %q, got %q"):format(what or "value", tostring(expected), tostring(actual)), 2)
    end
end

local function lastSent() return wow.sent[#wow.sent] end

local function printedMatch(pattern)
    for _, line in ipairs(wow.printed) do
        if line:find(pattern) then return true end
    end
    return false
end

wow.install()
wow.loadAddon("Muster")
wow.fire("ADDON_LOADED", "Muster")
wow.fire("PLAYER_LOGIN")

local M = Muster
local C, R, T, S = M.Commands, M.Roster, M.Templates, M.Strategies

---------------------------------------------------------------------------
test("loads and says hello", function()
    eq(M.VERSION, "0.1.0", "version")
    assert(MusterDB and M.db == MusterDB, "saved variables set up")
    eq(M.db.addDelay, 1.2, "default add delay")
end)

test("toc version matches the code", function()
    local toc = io.open("Muster/Muster.toc"):read("*a")
    eq(toc:match("## Version: (%S+)"), M.VERSION, "toc version")
    eq(toc:match("## Interface: (%d+)"), "30300", "interface")
end)

test("toc lists every Lua file and nothing else", function()
    local listed = {}
    for _, f in ipairs(wow.tocFiles) do listed[f] = true end
    local found = io.popen("cd Muster && find . -name '*.lua' | sed 's|^./||' | sort")
    for path in found:lines() do
        assert(listed[path], path .. " is not in Muster.toc")
        listed[path] = nil
    end
    found:close()
    assert(next(listed) == nil, "toc lists a missing file: " .. tostring(next(listed)))
end)

test("every L.KEY in the code has an English string", function()
    local missing = {}
    local files = io.popen("find Muster -name '*.lua'")
    for path in files:lines() do
        local src = io.open(path):read("*a")
        for key in src:gmatch("L%.([A-Z][A-Z_]+)") do
            if rawget(M.L, key) == nil then table.insert(missing, path .. ": L." .. key) end
        end
    end
    files:close()
    assert(#missing == 0, table.concat(missing, ", "))
end)

---------------------------------------------------------------------------
test("server commands", function()
    eq(C.List(), ".playerbot bot list")
    eq(C.Add("Aldric, Mira"), ".playerbot bot add Aldric,Mira")
    eq(C.Add({ "Aldric", "Mira" }), ".playerbot bot add Aldric,Mira")
    eq(C.Remove("Vol"), ".playerbot bot remove Vol")
    eq(C.AddClass("mage"), ".playerbot bot addclass mage")
end)

test("class names the server understands", function()
    eq(C.ClassArg("Mage"), "mage")
    eq(C.ClassArg(" death knight "), "dk")
    eq(C.ClassArg("DK"), "dk")
    eq(C.ClassArg("bard"), nil)
    eq(C.ClassToken("Death Knight"), "DEATHKNIGHT")
    eq(C.ClassToken("DeathKnight"), "DEATHKNIGHT")
end)

test("order filters and strategies", function()
    eq(C.Filtered("tank", "follow"), "@tank follow")
    eq(C.Filtered("healers", "stay"), "@heal stay")
    eq(C.Filtered("all", "attack"), "attack")
    eq(C.Filtered(nil, "attack"), "attack")
    eq(C.Strategy("co", true, "avoid aoe"), "co +avoid aoe")
    eq(C.Strategy("nc", false, "loot"), "nc -loot")
    eq(C.StrategyQuery("nc"), "nc ?")
    eq(C.SpecPick("prot pve"), "talents spec prot pve")
end)

---------------------------------------------------------------------------
test("parses the server's roster line", function()
    local list = R.Parse("Bot roster: +Vol DeathKnight, -Mira Priest, +Aldric Warrior")
    eq(#list, 3, "entries")
    eq(list[1].name, "Aldric"); eq(list[1].class, "WARRIOR"); eq(list[1].online, true)
    eq(list[2].name, "Mira"); eq(list[2].online, false)
    eq(list[3].class, "DEATHKNIGHT")
    eq(#R.Parse("Bot roster: "), 0, "empty roster")
    eq(R.Parse("Hello!"), nil, "other messages")
end)

test("roster refresh asks the server and hides its reply", function()
    R:Refresh()
    eq(lastSent().msg, ".playerbot bot list"); eq(lastSent().channel, "SAY")
    local filter = wow.chatFilters.CHAT_MSG_SYSTEM
    eq(filter(nil, "CHAT_MSG_SYSTEM", "Bot roster: +Aldric Warrior"), true, "hidden while waiting")
    wow.fire("CHAT_MSG_SYSTEM", "Bot roster: +Aldric Warrior, -Mira Priest")
    eq(#R.bots, 2, "roster stored")
    -- Chat frames may filter the same message after Muster's handler ran.
    eq(filter(nil, "CHAT_MSG_SYSTEM", "Bot roster: +Aldric Warrior"), true, "still hidden this frame")
    eq(filter("CHAT_MSG_SYSTEM", "Bot roster: +Aldric Warrior"), true, "older filter signature")
    wow.advance(0.1)
    eq(filter(nil, "CHAT_MSG_SYSTEM", "Bot roster: +Aldric Warrior"), false, "shown when not asked")
end)

---------------------------------------------------------------------------
-- mod-playerbots' default premade specs (Playerbots.PremadeSpecName.*).
local PREMADE = {
    warrior = { "arms pve", "fury pve", "prot pve" }, paladin = { "holy pve", "prot pve", "ret pve" },
    hunter = { "bm pve", "mm pve", "surv pve" }, rogue = { "as pve", "combat pve", "subtlety pve" },
    priest = { "disc pve", "holy pve", "shadow pve" }, shaman = { "ele pve", "enh pve", "resto pve" },
    mage = { "arcane pve", "fire pve", "frost pve" }, warlock = { "affli pve", "demo pve", "destro pve" },
    druid = { "balance pve", "bear pve", "resto pve", "cat pve" },
}

test("templates have the right sizes and real specs", function()
    local sizes = { dungeon = 4, ["dungeon-tank"] = 4, ["dungeon-heal"] = 4, raid10 = 9, raid25 = 24, raid40 = 39 }
    for _, tpl in ipairs(T:All()) do
        eq(#tpl.slots, sizes[tpl.id], tpl.id .. " size")
        for _, slot in ipairs(tpl.slots) do
            local known = false
            for _, spec in ipairs(PREMADE[slot.class] or {}) do
                if spec == slot.spec then known = true end
            end
            assert(known, tpl.id .. ": " .. slot.class .. " has no spec '" .. tostring(slot.spec) .. "'")
            assert(slot.role == "tank" or slot.role == "heal" or slot.role == "dps", "role")
        end
    end
    local total, tanks, heals, dps = T.Summary(T:Get("raid40"))
    eq(total, 39); eq(tanks, 3); eq(heals, 11); eq(dps, 25)
end)

test("plan skips classes already in the group", function()
    local todo = T.Plan(T:Get("dungeon").slots, { warrior = 1, mage = 2 })
    eq(#todo, 2, "left to add")
    eq(todo[1].class, "priest"); eq(todo[2].class, "rogue")
end)

test("plan counts existing members against damage slots first", function()
    -- raid25 has 2 prot warriors and 2 fury warriors; one warrior already in
    -- the group must not cost a tank.
    local prot, fury = 0, 0
    for _, s in ipairs(T.Plan(T:Get("raid25").slots, { warrior = 1 })) do
        if s.class == "warrior" and s.role == "tank" then prot = prot + 1 end
        if s.class == "warrior" and s.role == "dps" then fury = fury + 1 end
    end
    eq(prot, 2, "both tanks still added"); eq(fury, 1, "one fury slot filled")
end)

test("raising a dungeon adds four bots and sets their specs", function()
    wow.setGroup(nil)
    T:Raise(T:Get("dungeon"))
    eq(lastSent().msg, ".playerbot bot addclass warrior", "first add")
    wow.advance(1.3)
    eq(lastSent().msg, ".playerbot bot addclass priest", "second add")
    wow.advance(2.5)
    eq(lastSent().msg, ".playerbot bot addclass rogue", "fourth add")
    wow.advance(1.3)
    eq(T:IsRaising(), false, "finished")
    assert(printedMatch("4 bots requested"), "done message")

    -- The warrior joins; three seconds later it is told to tank.
    wow.reset()
    wow.setGroup("party", { { name = "Brakk", class = "WARRIOR" } })
    wow.fire("PARTY_MEMBERS_CHANGED")
    wow.advance(3.2)
    eq(lastSent().msg, "talents spec prot pve"); eq(lastSent().target, "Brakk")
    eq(lastSent().channel, "WHISPER")
end)

test("a bot whose class isn't known yet still gets its spec", function()
    wow.setGroup(nil)
    T:Raise(T:Get("dungeon"))
    wow.advance(5)
    wow.reset()
    -- The client hasn't resolved the new member yet.
    wow.setGroup("party", { { name = "Unknown", class = nil } })
    wow.fire("PARTY_MEMBERS_CHANGED")
    wow.advance(0.5)
    eq(#wow.sent, 0, "nothing sent for an unknown member")
    -- A second later it is resolved, without another group event.
    wow.group.members[1] = { name = "Mira", class = "PRIEST" }
    wow.advance(4.5)
    eq(lastSent().msg, "talents spec holy pve"); eq(lastSent().target, "Mira")
    T.pendingSpecs = {}
end)

test("a refused bot's spec isn't given to the next bot", function()
    wow.setGroup(nil)
    T:Raise(T:Get("dungeon"))
    -- The warrior request is refused.
    wow.fire("CHAT_MSG_SYSTEM", "Add class failed, no available characters!")
    for _, p in ipairs(T.pendingSpecs) do
        assert(p.class ~= "warrior", "the refused warrior's spec is still queued")
    end
end)

test("raising stops when the server says no", function()
    wow.setGroup(nil)
    T:Raise(T:Get("raid10"))
    wow.advance(1.3)
    wow.fire("CHAT_MSG_SYSTEM", "Add class failed, no available characters!")
    eq(T:IsRaising(), false, "stopped")
    local count = #wow.sent
    wow.advance(5)
    eq(#wow.sent, count, "nothing more sent")
    assert(printedMatch("1 of 9"), "stop message counts the bot that got through")
end)

test("fill-missing raise with a full group does nothing", function()
    wow.setGroup("party", {
        { name = "A", class = "WARRIOR" }, { name = "B", class = "PRIEST" },
        { name = "C", class = "MAGE" }, { name = "D", class = "ROGUE" },
    })
    M.db.fillMissing = true
    T:Raise(T:Get("dungeon"))
    eq(#wow.sent, 0, "nothing sent")
    assert(printedMatch("already has everything"), "message")
end)

---------------------------------------------------------------------------
test("strategies: query, parse replies, toggle", function()
    local set = S.Parse("Strategies: avoid aoe, dps, threat")
    assert(set["avoid aoe"] and set.dps and set.threat, "parsed")
    eq(S.Parse("Hello!"), nil)

    S:Query("Brakk")
    eq(lastSent().msg, "co ?"); eq(lastSent().target, "Brakk")
    eq(S:Query("Brakk"), false, "a second click while waiting is ignored")
    wow.fire("CHAT_MSG_WHISPER", "Strategies: avoid aoe, tank", "Brakk")
    eq(lastSent().msg, "nc ?", "asks out-of-combat only after the combat answer")
    wow.fire("CHAT_MSG_WHISPER", "Strategies: follow, loot", "Brakk")
    assert(S:Get("Brakk", "co")["avoid aoe"], "combat set")
    assert(S:Get("Brakk", "nc").loot, "non-combat set")
    eq(S.pending.Brakk, nil, "nothing left waiting")

    S:Set("Brakk", "co", "avoid aoe", false)
    eq(lastSent().msg, "co -avoid aoe")
    eq(S:Get("Brakk", "co")["avoid aoe"], nil, "local state follows")
end)

test("strategies: an unanswered question expires", function()
    S:Query("Vol")
    wow.advance(3.5)
    wow.fire("CHAT_MSG_WHISPER", "Strategies: dps", "Vol")
    eq(S:Get("Vol", "co"), nil, "late reply ignored")
    eq(S.pending.Vol, nil)
end)

---------------------------------------------------------------------------
test("orders go to the right channel", function()
    wow.setGroup(nil)
    eq(M:Order("follow"), false, "no group")
    eq(#wow.sent, 0)
    assert(printedMatch("not in a group"), "explains why")

    wow.setGroup("party", { { name = "Brakk", class = "WARRIOR" } })
    M:Order("follow", "tank")
    eq(lastSent().msg, "@tank follow"); eq(lastSent().channel, "PARTY")

    wow.setGroup("raid", { { name = "Brakk", class = "WARRIOR" }, { name = "Mira", class = "PRIEST" } })
    M:Order("tank")
    eq(lastSent().msg, "tank attack"); eq(lastSent().channel, "RAID")

    M:Order("summon", nil, "Mira")
    eq(lastSent().msg, "summon"); eq(lastSent().channel, "WHISPER"); eq(lastSent().target, "Mira")
end)

test("dismiss refreshes the roster, then removes only your bots", function()
    wow.setGroup("party", { { name = "Brakk", class = "WARRIOR" }, { name = "Realplayer", class = "MAGE" } })
    R.bots = {}
    R:DismissGroupBots()
    eq(lastSent().msg, ".playerbot bot list", "refresh first")
    wow.fire("CHAT_MSG_SYSTEM", "Bot roster: +Brakk Warrior, -Mira Priest")
    eq(lastSent().msg, ".playerbot bot remove Brakk", "only the bot")
end)

test("slash commands", function()
    wow.setGroup("party", { { name = "Brakk", class = "WARRIOR" } })
    SlashCmdList.MUSTER("order follow heal")
    eq(lastSent().msg, "@heal follow")
    SlashCmdList.MUSTER("class Death Knight")
    eq(lastSent().msg, ".playerbot bot addclass dk")
    SlashCmdList.MUSTER("add Aldric Mira")
    eq(lastSent().msg, ".playerbot bot add Aldric,Mira")
    SlashCmdList.MUSTER("raise nope")
    assert(printedMatch("No template called"), "unknown template")
    SlashCmdList.MUSTER("stop")
end)

---------------------------------------------------------------------------
test("the window builds, switches tabs and clicks through", function()
    assert(MusterFrame, "MusterFrame exists")
    assert(MusterMinimapButton, "minimap button exists")
    MusterFrame:Hide()
    M:Toggle()
    eq(MusterFrame:IsShown(), true, "toggle shows")
    for _, tab in ipairs({ "roster", "muster", "orders", "strategies" }) do
        M:ShowTab(tab)
        eq(M.activeTab, tab)
    end

    -- A roster reply fills the list; clicking a row selects that bot.
    M:ShowTab("roster")
    wow.fire("CHAT_MSG_SYSTEM", "Bot roster: +Aldric Warrior, -Mira Priest")
    local rows = M.Panels.roster.rows
    eq(rows[1].botName, "Aldric")
    rows[1]:Click()
    eq(R:FocusBot(), "Aldric", "selected")

    -- Orders tab with "selected bot" whispers it.
    M:ShowTab("orders")
    M.db.orderTarget = "selected"
    M:GiveOrder("stay")
    eq(lastSent().msg, "stay"); eq(lastSent().target, "Aldric")
    M.db.orderTarget = "all"

    -- Strategies tab redraws for the selection.
    M:ShowTab("strategies")
    S.state.Aldric = { co = { ["avoid aoe"] = true } }
    M:Fire("STRATEGIES", "Aldric")
    eq(M.Panels.strategies.boxes.co["avoid aoe"]:GetChecked(), 1, "box follows bot state")

    -- Minimap: right-click refreshes the roster.
    MusterMinimapButton:Click("RightButton")
    eq(lastSent().msg, ".playerbot bot list")
    M:Toggle()
    eq(MusterFrame:IsShown(), false, "toggle hides")
end)

---------------------------------------------------------------------------
print(("%d passed, %d failed"):format(passed, #failed))
for _, f in ipairs(failed) do print("FAIL: " .. f) end
os.exit(#failed == 0 and 0 or 1)
