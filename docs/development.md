---
title: Development
nav_order: 7
---

# Development

## Layout

```
Muster/                 the addon; this folder is what ships
  Muster.toc            load order and metadata
  Locale/enUS.lua       every string the player sees
  Core.lua              settings, timer, events, /muster
  Commands.lua          every line sent to the server
  Roster.lua            roster parsing and selection
  Templates.lua         group templates and raising
  Strategies.lua        strategy lists, parsing, toggles
  UI/                   the window, its four tabs, the minimap button
  Bindings.xml          key bindings
  Media/muster.tga      the in-game icon
tests/                  test suite and a stand-in for the WoW API
scripts/                release and asset helpers
docs/                   this site
```

The non-UI files keep their logic in plain functions (`Commands.Add`, `Roster.Parse`, `Templates.Plan`, `Strategies.Parse`) so the tests can check them without a client.

## Checks

Every push and pull request runs:

- **luacheck** against Lua 5.1 with the WoW globals Muster uses (`.luacheckrc`).
- **Tests**: `tests/run.lua` loads the addon from its `.toc` into a stand-in WoW API under Lua 5.1, fires events, runs the timer and clicks the buttons. It checks the exact chat lines Muster sends, the parsers, a full raise, that the `.toc` lists every file, and that every string key has English text.
- **Package check**: `scripts/package.sh` builds the release zip and checks the `.toc`.
- **Security**: gitleaks and Trivy; **CodeQL** for the workflows.

To run them locally you need Lua 5.1 and luacheck:

```bash
lua5.1 tests/run.lua
luacheck .
bash scripts/package.sh
```

## Releasing

1. Bump `## Version:` in `Muster/Muster.toc` and `M.VERSION` in `Muster/Core.lua` (the tests check they match).
2. Add a section to `CHANGELOG.md`.
3. Tag and push: `git tag v0.2.0 && git push origin v0.2.0`.

The release workflow checks that the tag matches the `.toc`, runs the tests, builds `Muster-<version>.zip`, and publishes a GitHub release with that version's changelog section as its notes.

## Assets

`scripts/render-assets.py` renders the social card, favicons and the in-game TGA from `docs/assets/logo.svg`. It needs librsvg and cairo.

## Translating

Copy `Muster/Locale/enUS.lua` to, say, `deDE.lua`, wrap its assignments in `if GetLocale() == "deDE" then ... end`, translate the strings, and add the file to `Muster.toc` right after `enUS.lua`.
