-- luacheck config: WoW 3.3.5a runs Lua 5.1.
std = "lua51"
max_line_length = 140
codes = true
self = false -- "function M:X()" without using self is normal addon style
exclude_files = { ".luacheckrc" }

-- Globals Muster defines.
globals = {
    "Muster", "MusterDB", "SlashCmdList", "SLASH_MUSTER1", "SLASH_MUSTER2",
    "BINDING_HEADER_MUSTER", "BINDING_NAME_MUSTER_TOGGLE", "BINDING_NAME_MUSTER_FOLLOW",
    "BINDING_NAME_MUSTER_STAY", "BINDING_NAME_MUSTER_ATTACK", "BINDING_NAME_MUSTER_FLEE",
    "BINDING_NAME_MUSTER_SUMMON", "BINDING_NAME_MUSTER_BAR", "UISpecialFrames",
}

-- WoW API Muster reads.
read_globals = {
    "CreateFrame", "UIParent", "Minimap", "GameTooltip", "DEFAULT_CHAT_FRAME",
    "SendChatMessage", "ChatFrame_AddMessageEventFilter",
    "GetNumRaidMembers", "GetNumPartyMembers", "GetTime", "GetCursorPosition",
    "UnitExists", "UnitName", "UnitClass", "UnitIsUnit", "UnitIsPlayer", "IsShiftKeyDown",
    "FauxScrollFrame_Update", "FauxScrollFrame_GetOffset", "FauxScrollFrame_OnVerticalScroll",
    "RAID_CLASS_COLORS", "CLASS_ICON_TCOORDS", "UNKNOWNOBJECT",
    "UninviteUnit", "IsPartyLeader", "IsRaidLeader",
}

files["tests/**"] = {
    std = "+busted",
    globals = {
        "CreateFrame", "UIParent", "Minimap", "GameTooltip", "DEFAULT_CHAT_FRAME",
        "SendChatMessage", "ChatFrame_AddMessageEventFilter",
        "GetNumRaidMembers", "GetNumPartyMembers", "GetTime", "GetCursorPosition",
        "UnitExists", "UnitName", "UnitClass", "UnitIsUnit", "UnitIsPlayer", "IsShiftKeyDown",
        "FauxScrollFrame_Update", "FauxScrollFrame_GetOffset", "FauxScrollFrame_OnVerticalScroll",
        "RAID_CLASS_COLORS", "CLASS_ICON_TCOORDS", "unpack", "MusterFrame", "MusterMinimapButton",
        "MusterCommandBar", "UninviteUnit", "IsPartyLeader", "IsRaidLeader",
    },
}
