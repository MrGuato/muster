---
title: Installation
nav_order: 2
---

# Installation

1. Download `Muster-<version>.zip` from the [latest release](https://github.com/MrGuato/muster/releases/latest). Use the zip attached to the release, not GitHub's "Source code" zip: the release zip holds just the addon folder.
2. Close the game, then unzip into your `World of Warcraft/Interface/AddOns/` folder. You should end up with:

   ```
   World of Warcraft/
     Interface/
       AddOns/
         Muster/
           Muster.toc
           Core.lua
           ...
   ```

3. Start the game. On the character screen, open **AddOns** and make sure **Muster** is ticked. If it says *out of date*, tick **Load out of date AddOns**; Muster is built for 3.3.5a (interface 30300).
4. Log in. The chat frame says `Muster: v0.1.0 loaded`. Type `/muster` or click the banner on your minimap.

## Updating

Delete the old `Interface/AddOns/Muster` folder and unzip the new release in its place. Your settings live in `WTF/Account/<account>/SavedVariables/Muster.lua` and carry over.

## Removing

Delete `Interface/AddOns/Muster`. To forget its settings too, delete `Muster.lua` from the `SavedVariables` folder above.

## From the source

If you'd rather run the current `main` branch, copy the `Muster/` folder from the repository into `Interface/AddOns/`. Everything outside that folder (docs, tests, workflows) is for development and isn't needed in game.
