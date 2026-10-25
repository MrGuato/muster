---
title: Server settings
nav_order: 5
---

# Server settings

Muster needs nothing installed on the server, but mod-playerbots has a few settings in `playerbots.conf` that decide what a player is allowed to do. If you run the server, check these. If you don't, ask your admin.

{: .note }
Recent mod-playerbots versions name every key `Playerbots.*`. Older ones used `AiPlayerbot.*` for the same keys. Use whichever prefix your `playerbots.conf.dist` uses.

| Setting | Needed for | Value |
| --- | --- | --- |
| `Playerbots.AddClassCommand` | the class icons and every template | `1` lets every player use `addclass`. With `0`, only GM accounts can. |
| `Playerbots.MaxAddedBots` | big templates | at least the number of bots you raise: 9 for a 10-man, 24 for a 25-man, 39 for a 40-man |
| `Playerbots.AddClassAccountPoolSize` | big templates | how many characters per class the server keeps ready for `addclass`. If a 40-man stops with *no available characters*, raise this. |
| `Playerbots.AllowAccountBots` | adding your own characters by name | `1` |
| `Playerbots.AllowGuildBots` | adding guildmates' characters by name | `1` |

The specs Muster picks for raised bots (`prot pve`, `holy pve`, `frost pve` and so on) are mod-playerbots' default premade specs, `Playerbots.PremadeSpecName.<class>.<n>`. If your server renamed them, a bot answers *Spec ... not found* and keeps the spec it rolled.

## After changing a setting

`playerbots.conf` is read when the worldserver starts, so restart it after editing.
