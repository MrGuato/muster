---
title: Home
nav_order: 1
description: Muster is a WoW 3.3.5a addon for mod-playerbots. Raise groups, give orders and tune strategies from one panel.
permalink: /
---

<p align="center">
  <img src="{{ '/assets/logo.svg' | relative_url }}" width="128" alt="Muster logo">
</p>

# Muster
{: .text-center }

Raise, command and tune your [mod-playerbots](https://github.com/mod-playerbots/mod-playerbots) bots from one panel.
{: .fs-6 .fw-300 .text-center }

[Download the latest release](https://github.com/MrGuato/muster/releases/latest){: .btn .btn-primary .mr-2 }
[Install in two minutes]({{ '/installation' | relative_url }}){: .btn }
{: .text-center }

---

## What you can do with it

**Raise a group in one click.** Pick a template (a 5-man where you tank, heal or deal damage, a 10, a 25, or a classic 40-man raid) and press Raise. Muster asks the server for each bot in turn, and when a bot joins it tells it the spec its slot needs, so the tank slot gets a tank. With *Only add what's missing* on, it counts what your group already has first.

**Give orders without typing.** Follow, stay, attack, tank in, pull, flee, summon and more, sent to everyone, to one role (tanks, healers, damage, melee, ranged), or to one bot. The five you use most can go on key bindings.

**Tune each bot.** Read a bot's in-combat and out-of-combat strategies and switch them with checkboxes, each with a tooltip saying what it does. Turn on *avoid aoe* for the whole raid with one click.

**See your roster.** Every bot your account can log in, in class colours, with who's online and who's in your group. Add one of any class from its icon.

## Is it for me?

You need a WoW **3.3.5a** client and an **AzerothCore** server running **mod-playerbots**: your own server, or one whose admin lets players add bots. Muster has no server part; it uses the chat commands mod-playerbots already understands. See [Server settings]({{ '/server' | relative_url }}) for the two settings that matter.

## Where to go next

- [Installation]({{ '/installation' | relative_url }}): unzip, log in, `/muster`.
- [Using Muster]({{ '/usage' | relative_url }}): every tab, button and option.
- [Commands]({{ '/commands' | relative_url }}): the slash command, the key bindings, and every line Muster sends to the server.
- [Server settings]({{ '/server' | relative_url }}): what the server needs to allow.
- [Troubleshooting]({{ '/troubleshooting' | relative_url }}): when bots don't show up or don't listen.

Muster is written from scratch and was inspired by [UnBot](https://github.com/liyunfan1223/unbot-addon), the original playerbots control addon.
