---
title: Commands
nav_order: 4
---

# Commands

## Slash command

`/muster` and the shorter `/mu` do the same thing.

| Command | What it does |
| --- | --- |
| `/muster` | show or hide the window |
| `/muster help` | list these commands in chat |
| `/muster list` | refresh your bot roster |
| `/muster add Aldric,Mira` | log in bots by name (commas or spaces) |
| `/muster remove Aldric` | log bots out |
| `/muster class mage` | add one bot of a class: `warrior`, `paladin`, `hunter`, `rogue`, `priest`, `shaman`, `mage`, `warlock`, `druid`, `dk` |
| `/muster raise raid40` | raise a group from a template: `dungeon`, `dungeon-tank`, `dungeon-heal`, `raid10`, `raid25`, `raid40` |
| `/muster stop` | stop raising |
| `/muster order follow` | give an order to everyone |
| `/muster order attack tank` | give an order to one role: `tank`, `heal`, `dps`, `melee`, `ranged` |
| `/muster minimap` | show or hide the minimap button |

Order names for `/muster order`: `follow`, `stay`, `attack`, `tank`, `pull`, `flee`, `summon`, `release`, `revive`, `rebuff`, `drink`, `maxdps`, `savemana`, `grind`.

You can put these in macros, for example `/muster order follow` on an action bar.

## Key bindings

Under **Key Bindings → AddOns → Muster**:

- Show or hide Muster
- Order: follow me
- Order: stay
- Order: attack my target
- Order: flee
- Order: summon to me

The order bindings go to whoever the Orders tab is set to: everyone, a role, or the selected bot.

## What Muster sends

Muster has no server component. Every action is a line of chat that mod-playerbots already understands, so you can always see what it does.

| Action | Line sent | Where |
| --- | --- | --- |
| Refresh roster | `.playerbot bot list` | say (the server takes it as a command, nobody hears it) |
| Add by name | `.playerbot bot add Aldric,Mira` | say |
| Remove | `.playerbot bot remove Aldric` | say |
| Add by class, Raise | `.playerbot bot addclass warrior` | say |
| Set a raised bot's spec | `talents spec prot pve` | whisper to that bot |
| Order to everyone | `follow` | party or raid chat |
| Order to a role | `@tank follow` | party or raid chat |
| Order to one bot | `follow` | whisper to that bot |
| Read strategies | `co ?`, then `nc ?` | whisper to that bot |
| Toggle a strategy | `co +avoid aoe`, `nc -loot` | whisper, or party/raid chat for the whole group |

And what it reads back:

| Reply | From | Used for |
| --- | --- | --- |
| `Bot roster: +Aldric Warrior, -Mira Priest` | system message | the Roster list (`+` online, `-` offline) |
| `Strategies: avoid aoe, tank, threat` | whisper from the bot | the Strategies checkboxes |
| `Add class failed, no available characters!`, `Failure: ...`, `ERROR: ...` | system message | stopping a raise |
