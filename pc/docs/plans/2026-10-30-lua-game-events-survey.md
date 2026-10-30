# Lua game events and actions: survey (input for the design talk)

Status: research notes, 2026-10-30. Not a plan and not approved; it gathers what
exists and the main choice to make, so the design conversation can start from facts.

## What Lua has today

- **An event bus:** `rood.on(event, fn)`, `rood.off`, `rood.emit` (Extensions.md "API").
  Core events are engine ones only: `tick`, `frame`, `plugin.loaded/unloaded`,
  `registry.changed`, `unload`, `input.action`, and `hud.<kind>` (a HUD element drawn).
- **Read-only game queries:** `rood.game.ashley()`, `mode()`, `room()`, `first_person()`,
  `menu()`, `paused()`, and the player state (`inventory()`, `weapons()`, ... `workshop`).
- **No game events** (a room entered, damage dealt, an enemy defeated, an item picked up,
  a chest opened, a save made, a cutscene started) and **no game actions** (give an item,
  set HP, move Ashley, start a fight). Everything a plugin learns about play today it
  learns by polling queries every tick.

## Where events could come from

1. **Hooks inside the C bodies** (how the classic UI's `PC_CLASSIC` sites work).
   - Exact, and placed where the meaning is (after the damage is applied, not before).
   - **Lost when a function is ported to Zig unless the port repeats it.** This week three
     ports lacked hooks added after they were written (printVariableWidthFontChar,
     func_800941FC, func_8009627C); zig_diff caught them, but only because the hooks are
     calls it records. Porting waves now cover hundreds of 146C / 5BF94 functions, the
     units where most battle events live (`_enemyDefeated`, `_applyBattleAbilityEffect`,
     `_dropLoot`, `vs_battle_equipWeapon`, `_updateWeaponKillStreak` are all Zig-owned).
2. **The routing trampolines** (PORTING.md §13). Every routed function is reached through
   its trampoline `F`, and the owner byte picks the C body or the Zig port. An observer at
   the trampoline (on call: the arguments; on return: the result) sees the call whoever
   owns the body, so it **survives porting by construction**.
   - Only routed functions have trampolines. Functions not ported yet can be routed with
     `default = "original"` to get one (ownership.py; statics cannot be routed).
   - Arguments and results are raw (guest pointers, ids); a curated event layer turns them
     into meaningful payloads (`{enemy = "Minotaur", room = ..., weapon = ...}`).
   - Cost: one flag test per routed call when nothing listens.
3. **State diffing per tick** (room id changed, HP changed, inventory changed): no hooks at
   all, works today from Lua, but coarse (misses what happens within a frame, cannot say why).

## The main choice for the design

- **Events at the trampolines plus a curated layer** (my recommendation to discuss):
  low-level `game.call` observers for modders who want everything, and named events
  (`game.room_entered`, `game.enemy_defeated`, `game.damage`, `game.item_gained`,
  `game.saved`, ...) built from them in one place, documented with their payloads.
- **Actions** follow the same seam: a Lua function may wrap a routed function
  (before / after / replace), which is also what "fully scriptable" needs for gameplay
  mods. Replace needs the same safety nets as HUD claims (budget, fault fallback to the
  game's own code, a setting to turn it off) and must stay out of the original-profile
  differential runs (zig_diff, tick-mode checks pin features off).
- Direct actions (`rood.game.give_item`, `set_hp`, `teleport`) are a separate, smaller
  surface: each one a C/Zig helper that does what the game's own code does, with tests.

## Questions for the user

- Which events matter first (what do you want plugins to react to)?
- Are gameplay-changing wraps (replace a game function from Lua) in scope now, or only
  observation and a few direct actions?
- Should events be available in the classic/vanilla profile, or only with a plugin
  granted a capability (like `elevated`)?
