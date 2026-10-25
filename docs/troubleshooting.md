---
title: Troubleshooting
nav_order: 6
---

# Troubleshooting

## Muster doesn't show up in the AddOns list

The folder is probably nested one level too deep. You need `Interface/AddOns/Muster/Muster.toc`, not `Interface/AddOns/Muster-0.1.0/Muster/Muster.toc`. Move the inner `Muster` folder up.

If it's listed as *out of date*, tick **Load out of date AddOns** on the character screen.

## The roster stays empty

- Press **Refresh**. The roster isn't loaded until you ask.
- Type `.playerbot bot list` in chat yourself. If the server answers *There is no such command*, the server doesn't run mod-playerbots, or bots are disabled for players.
- The roster lists your own account's other characters and the random bots in your group. A brand-new account with one character has an empty roster until you add bots by class.

## Raise stops after a few bots

Muster prints the server's reason. The common ones:

| Message | Meaning | Fix |
| --- | --- | --- |
| *Add class failed, no available characters!* | the server has no free character of that class for your faction | raise `Playerbots.AddClassAccountPoolSize`, or remove some bots |
| *Failure: You have added too many bots* | you reached `Playerbots.MaxAddedBots` | raise it, or dismiss some bots |
| *You do not have permission to create bot by addclass command* | `Playerbots.AddClassCommand` is `0` | set it to `1`, or use a GM account |
| *Your level is too low to summon Deathknight* | death knights need a high-level master | no template uses death knights; this only comes from the DK icon |

See [Server settings]({{ '/server' | relative_url }}).

## Bots join but keep the wrong spec

- Check that **Set each bot's spec** is ticked on the Muster tab.
- The bot answers `Spec ... not found` if your server renamed its premade specs. Whisper it `talents spec list` to see the names it knows.
- The spec is whispered within a minute of the request; a bot that takes longer to log in keeps its own spec. Whisper it `talents spec <name>` yourself.

## Bots ignore orders

- Orders to everyone or a role go out in party or raid chat, so you must be in a group with the bots.
- Bots only take orders from their master: the player who added them. A bot someone else added doesn't listen to you.
- A role filter only reaches bots with that role. If `@tank follow` does nothing, your tank may have a damage spec; check with the Strategies tab.

## Strategies don't load

Press **Read from bot** with exactly one bot selected (or targeted). The bot whispers `Strategies: ...` twice, once for combat and once for out of combat. If nothing comes back, the bot isn't yours or isn't online.

## Something else

Open an [issue](https://github.com/MrGuato/muster/issues/new/choose) with your Muster version, what you clicked, and what chat said.
