# Red Earth 2 — Gate 0 + Gate 1 Foundation

This file records the first clean-room foundation choices. Nothing here imports the old Red Earth custom modules.

## Gate 0 — new cart identity

Development cart identity: `red_earth_next` (working name).

Rules:
- base game: Red
- separate save scope from `red_earth` and `red_earth_philosophers_stones`
- sealed during testing
- no old Irregular/Philosopher/bridge mods
- no old sprite assets
- text speed seeded to FAST (Gen 1 `textSpeed = 1`) once cart boot configuration is added

## Gate 1A — mechanical/presentation foundation

### gen1_kaizo — species/data/AI owner
Use Gen1 Recomp Allgen Kaizo as the upstream foundation instead of reimplementing its roster and AI.

Owns:
- expanded all-generation species registry
- modern types and expanded moves
- trainer party construction
- competitive trainer move-selection AI
- wild encounter expansion
- evolution mapping
- baseline all-generation battler front/back art

Initial Red Earth setting: BATTLE = STATIC.

A later `red_earth_kaizo_profile_next` compatibility module may replace only the level-scaling policy with Red Earth's upward-only rule. It must not duplicate the species registry, AI, or battler pack.

Do not install Trade Evolution Fix on top of Kaizo unless an audit finds a real gap; Kaizo already converts trade methods to solo-completable level evolutions and has its own evolution fallback rules.

### potato_voxel — sole voxel/world renderer
Provisional renderer: PotatoVoxel.

Reason:
- one renderer only
- explicitly tuned for low-end/handheld frame budgets
- render-scale and quality modes give us a performance path on iOS/Android
- Wilds supports it as a variable-size renderer

Conflicts mean the following are excluded while PotatoVoxel owns rendering:
- BATTLE_ART_VOXEL_FORK
- DRAMATIC_SHAPE
- DRAMALESS_SHAPE

Initial test setting:
- conservative quality profile
- 3D battle rendering OFF until the 2D battler contract passes
- exact release/options to be frozen only after package validation

### overworld_wild_spawns — Wilds + follower owner
Use Wilds of Kanto as one combined owner for visible wild Pokémon and party followers.

Do not add Followers EX or PokéPC separately; current Wilds has built-in follower selection/control and treats legacy installs as migration sources.

Initial performance-oriented Red Earth defaults:
- Sprite Style: Poke Followers / GSC
- Spawn Amount: Low
- Followers: 1
- Control Mode: Trainer
- Trainer Trail: Off
- Random Encounters: On
- Town Pokémon: Off for the first benchmark
- advanced HGSS/PMDCollab sizing stays out of the first performance baseline

Show Wild Mons remains user-switchable so iPhone users can disable visible wilds without losing the cart or follower integration.

### performance_monitor — development-only diagnostic
Use FAFF0x Performance Monitor only in the development/nightly cart.

Purpose:
- quantify Wilds + voxel cost on iPhone, Nubia, Mac, and future handheld hardware
- identify slow callbacks/draw calls instead of guessing

It does not ship in the final release unless there is a reason to keep a diagnostics build.

## Sprite ownership at Gate 1

Kaizo is the baseline battler-art owner because its expanded roster includes front/back art for the all-generation species it registers.

Do NOT use Crystal Animated Sprites as the global Gate 1 sprite owner. It is a Crystal-art/shiny presentation mod, while Red Earth needs one complete art path for Kaizo's expanded roster. We can revisit animation later only through a provider that covers the actual roster or through a Red Earth adapter.

Red Earth's Irregular art is introduced only in Gate 3 through `red_earth_visuals_next`.

## Gate 1B — chosen later, after Gate 1A passes

These are provisional subsystem choices, not yet enabled:

- Bag owner: Wild's Gen1ModernBag (preferred candidate; conflicts with FAFF0x `modern_bag`, so only one is allowed)
- PC/terminal owner: FAFF0x Advanced Box System
- Menu owner: Gen1BetterMenus, with overlapping PC/Bag/Battle sub-UIs disabled if those systems have separate owners
- Quest journal owner: FAFF0x Quest System
- Quest content: add quest packs only after the journal passes by itself
- Red Earth Philosopher's Stones quest/content: `red_earth_alchemy_next`, added at Gate 6

## Evolution contract

Gate 1 must regression-test:
- Fire/Water/Thunder/Leaf/Moon Stone evolutions
- modern-stone approximations supplied by Kaizo
- trade-evolution replacements
- starter lines through final evolution
- item consumption exactly once
- no dead-end evolution methods

## Load-order draft

1. `gen1_kaizo`
2. `potato_voxel`
3. `overworld_wild_spawns`
4. development-only `performance_monitor`

No Red Earth custom module enters until this stack passes.

The order is provisional until hooks/manifests and packed release artifacts are validated together.
