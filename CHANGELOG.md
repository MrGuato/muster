# Changelog

All notable changes to Muster. Releases follow [semantic versioning](https://semver.org/). Each release on GitHub has a `Muster-<version>.zip` ready to unzip into `Interface/AddOns/`.

## [0.2.0] - 2026-10-25

Fixes from the first run in a real client, the command bar, and screenshots.

### Added
- **Command bar** ([#9](https://github.com/MrGuato/muster/issues/9)): a bar of category icons (orders, bots, raise a group, combat strategies, out-of-combat strategies). Click one to open a column of its commands; every icon's tooltip shows what it does and the line it sends. Left-click runs a command (shift-click turns a strategy off), right-click pins it to the bar, up to ten pins. Follow, stay, attack and flee start pinned. Drag the banner at its left end to move it. `/muster bar`, a key binding, or shift-click on the minimap button shows or hides it. Commands go to whoever the Orders tab is set to. Every icon is checked against the 3.3.5 client's icon list by the tests.
- Strategy changes from the bar follow the Orders tab's target: everyone, one role, or the selected bot.
- `/muster minimap reset` puts the minimap button back in its starting place.
- Screenshots and GIFs in the README and docs ([#10](https://github.com/MrGuato/muster/issues/10)).

### Fixed
- The minimap button started under Dungeon Clear's button. It now starts at 148° ([#3](https://github.com/MrGuato/muster/issues/3)).
- Dismissing bots, or removing ones in your group from the Roster tab, left them in the party as offline members. When you lead the group, Muster now takes them out of it too ([#4](https://github.com/MrGuato/muster/issues/4)).
- Template names were wider than their buttons ([#5](https://github.com/MrGuato/muster/issues/5)).
- The template summary said "1 tanks, 1 healers" and wrapped. It now reads "4 bots" over "1 tank, 1 healer, 2 damage" ([#6](https://github.com/MrGuato/muster/issues/6)).
- The window was so see-through that nameplates and chat showed through the lists. It now has a dark backing ([#7](https://github.com/MrGuato/muster/issues/7)).
- The roster scrollbar had no track ([#8](https://github.com/MrGuato/muster/issues/8)).

### Changed
- Template names: *Dungeon, you deal damage*, *Dungeon, you tank*, *Dungeon, you heal*, *Raid, 10 players*, *Raid, 25 players*, *Raid, 40 classic*. The slash command ids (`dungeon`, `raid40`, ...) are unchanged.
- GitHub Actions: gitleaks-action 3.

## [0.1.0] - 2026-10-25

The first release: a playerbots control panel for WoW 3.3.5a, written from scratch for current mod-playerbots.

### Added
- **Roster tab**: your bots from `.playerbot bot list`, with class colours, online and in-group status. Add or remove by selection (shift-click for several), by name, or one of any class from its icon.
- **Muster tab**: raise a group from a template. Three 5-man dungeon groups (you tank, heal or deal damage), 10, 25 and a classic 40-man raid. Options to add only what your group is missing and to give each new bot the premade spec its slot needs (`talents spec ...`). Stops by itself when the server refuses a bot, and a button dismisses the bots in your group.
- **Orders tab**: fourteen orders (follow, stay, attack, tank in, pull, flee, summon, release, revive, rebuff, eat/drink, max DPS, save mana, grind) for everyone, one role, or one selected bot.
- **Strategies tab**: read a bot's in-combat and out-of-combat strategies and toggle eighteen common ones, each with a tooltip. Can also toggle for the whole group.
- Minimap button, key bindings (window plus follow, stay, attack, flee and summon) and the `/muster` slash command.
- English strings kept in one locale file, ready for translations.
- Documentation site at <https://mrguato.github.io/muster/>.
- Checks on every push and pull request: luacheck, a test suite that loads the addon against a stand-in WoW API under Lua 5.1, a `.toc` check, gitleaks and Trivy, and CodeQL for the workflows. Tagged releases are packaged and published by a workflow.

[0.2.0]: https://github.com/MrGuato/muster/releases/tag/v0.2.0
[0.1.0]: https://github.com/MrGuato/muster/releases/tag/v0.1.0
