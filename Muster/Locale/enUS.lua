-- English strings. Every user-facing string goes through Muster.L, so a
-- translation is a new file in Locale/ that overwrites these keys.
Muster = Muster or {}

local L = setmetatable({}, { __index = function(_, key) return key end })
Muster.L = L

-- Key bindings (Key Bindings > AddOns > Muster)
BINDING_HEADER_MUSTER = "Muster"
BINDING_NAME_MUSTER_TOGGLE = "Show or hide Muster"
BINDING_NAME_MUSTER_BAR = "Show or hide the command bar"
BINDING_NAME_MUSTER_FOLLOW = "Order: follow me"
BINDING_NAME_MUSTER_STAY = "Order: stay"
BINDING_NAME_MUSTER_ATTACK = "Order: attack my target"
BINDING_NAME_MUSTER_FLEE = "Order: flee"
BINDING_NAME_MUSTER_SUMMON = "Order: summon to me"

-- General
L.TITLE = "Muster"
L.TAB_ROSTER = "Roster"
L.TAB_MUSTER = "Muster"
L.TAB_ORDERS = "Orders"
L.TAB_STRATEGIES = "Strategies"
L.NOT_IN_GROUP = "You're not in a group, so there's no one to give orders to."
L.NO_BOT_SELECTED = "Pick a bot first: click one in the Roster tab, or target it."
L.LOADED = "v%s loaded. Type /muster for the panel, /muster help for commands."

-- Roster
L.REFRESH = "Refresh"
L.ADD = "Add"
L.REMOVE = "Remove"
L.ADD_BY_NAME = "Add by name"
L.ADD_BY_CLASS = "Add a bot of this class"
L.ROSTER_EMPTY = "No bots yet. Press Refresh, or add one by class below."
L.ROSTER_UPDATED = "Roster: %d bots, %d online."
L.ONLINE = "Online"
L.OFFLINE = "Offline"
L.IN_GROUP = "In group"
L.SELECTED = "Selected: %s"
L.ROSTER_HINT = "Click to select. Shift-click to select several."

-- Muster (templates)
L.RAISE = "Raise"
L.STOP = "Stop"
L.DISMISS_ALL = "Dismiss group bots"
L.NO_GROUP_BOTS = "None of your group members are bots you added."
L.FILL_MISSING = "Only add what's missing"
L.FILL_MISSING_TIP = "Count the bots already in your group by class and add only the rest."
L.PICK_SPECS = "Set each bot's spec"
L.PICK_SPECS_TIP = "Whisper each new bot the spec its slot asks for (talents spec ...)."
L.RAISING = "Raising %s: %d of %d"
L.RAISE_DONE = "%s: %d bots requested."
L.RAISE_STOPPED = "Stopped. %d of %d bots were requested."
L.RAISE_NOTHING = "%s: your group already has everything this template needs."
L.RAISE_FAILED = "The server refused a bot (%s). Stopping."
L.N_BOT = "%d bot"
L.N_BOTS = "%d bots"
L.N_TANK = "%d tank"
L.N_TANKS = "%d tanks"
L.N_HEALER = "%d healer"
L.N_HEALERS = "%d healers"
L.N_DPS = "%d damage"

-- Orders
L.TARGET_ALL = "Everyone"
L.TARGET_TANKS = "Tanks"
L.TARGET_HEALERS = "Healers"
L.TARGET_DPS = "Damage"
L.TARGET_MELEE = "Melee"
L.TARGET_RANGED = "Ranged"
L.TARGET_SELECTED = "Selected bot"
L.ORDERS_SENT_TO = "Orders go to: %s"

-- Strategies
L.COMBAT = "In combat"
L.NONCOMBAT = "Out of combat"
L.READ_STRATEGIES = "Read from bot"
L.WHOLE_GROUP = "Send to the whole group"
L.WHOLE_GROUP_TIP = "Toggle the strategy on every bot in your group instead of the selected one."
L.STRATEGIES_FOR = "Strategies for %s"
L.STRATEGIES_UNKNOWN = "Press \"Read from bot\" to load its current strategies."

-- Command bar
L.CAT_ORDERS = "Orders"
L.CAT_BOTS = "Bots"
L.CAT_RAISE = "Raise a group"
L.CAT_COMBAT = "Combat strategies"
L.CAT_NONCOMBAT = "Out-of-combat strategies"
L.ADD_CLASS_TITLE = "Add a %s"
L.TIP_REFRESH = "Ask the server for your bot roster."
L.TIP_DISMISS = "Log out the bots in your group and take them out of it."
L.TIP_STOP = "Stop raising after the current bot."
L.TIP_SENDS = "Sends: %s"
L.TIP_GOES_TO = "Goes to: %s (set on the Orders tab)"
L.TIP_CLICK_RUN = "Left-click: run it"
L.TIP_CLICK_TOGGLE = "Left-click: turn on. Shift-click: turn off"
L.TIP_PIN = "Right-click: pin to the bar"
L.TIP_UNPIN = "Right-click: unpin from the bar"
L.PINS_FULL = "The bar holds %d pins. Right-click a pinned one to make room."
L.BAR_HANDLE_TIP = "Click: show or hide the Muster window. Drag: move the bar."
L.BAR_CATEGORY_TIP = "Click to show or hide its commands."

-- Minimap
L.MINIMAP_TIP_LEFT = "Left-click: show or hide"
L.MINIMAP_TIP_RIGHT = "Right-click: refresh roster"
L.MINIMAP_TIP_SHIFT = "Shift-click: show or hide the command bar"
L.MINIMAP_TIP_DRAG = "Drag: move this button"

-- Slash command help
L.HELP = {
    "/muster - show or hide the panel",
    "/muster list - refresh your bot roster",
    "/muster add <name[,name]> - log in bots by name",
    "/muster remove <name[,name]> - log bots out",
    "/muster class <class> - add a bot of a class (warrior, paladin, hunter, rogue, priest, shaman, mage, warlock, druid, dk)",
    "/muster raise <template> - raise a group from a template (dungeon, dungeon-tank, dungeon-heal, raid10, raid25, raid40)",
    "/muster stop - stop raising",
    "/muster order <order> [tank|heal|dps|melee|ranged] - give your group an order (follow, stay, attack, flee, summon, ...)",
    "/muster bar - show or hide the command bar",
    "/muster minimap - show or hide the minimap button (/muster minimap reset puts it back in place)",
}
L.UNKNOWN_COMMAND = "Unknown command \"%s\". Try /muster help."
L.UNKNOWN_TEMPLATE = "No template called \"%s\". Try: %s"
L.UNKNOWN_ORDER = "No order called \"%s\". Try: %s"
L.UNKNOWN_CLASS = "No class called \"%s\". Try: %s"
