# Changelog

All notable changes to Muster. Releases follow [semantic versioning](https://semver.org/). Each release on GitHub has a `Muster-<version>.zip` ready to unzip into `Interface/AddOns/`.

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

[0.1.0]: https://github.com/MrGuato/muster/releases/tag/v0.1.0
