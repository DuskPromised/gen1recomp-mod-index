# Red Earth Kaizo Bridge

Compatibility layer for **Pokémon Red Earth: The Philosopher's Stones**.

It deliberately leaves Allgen Kaizo in charge of species, encounter pools, six-Pokémon trainer teams, competitive movesets, boss Megas and AI, then adds four narrow behaviors:

- **Dynamic wilds:** strongest healthy party Pokémon -2 to +1. Existing/Kaizo levels are never lowered.
- **Dynamic trainers:** strongest healthy party Pokémon +0 to +2 across the final Kaizo roster. Existing/Kaizo levels are never lowered.
- **Regional rival continuity:** the rival's Kanto starter slot is rewritten to the matching evolution line from your selected region, while preserving vanilla counter-pick logic.
- **Shiny Oak gifts:** any regional companion you receive in Oak's Lab gets real Gen-2-compatible shiny DVs. Irregular Origin separately guarantees Psydren's shiny DVs.

The first Oak-lab rival remains at Kaizo's intended vanilla level. Wilds of Kanto contact battles are handled through the normal `start_battle wild` script seam, so visible encounters receive the same scaling policy.

This mod is intentionally incompatible with the old Kanto-only Take the Last Starter and Shiny Gifts & Starters mods.


## v1.0.1

- Rival starter continuity now follows the selected region for the entire rival starter line. A Fennekin choice, for example, makes the vanilla Squirtle counter slot become Froakie, then Frogadier/Greninja later.
- Oak's first rival battle keeps its authored level while still using the regional counter species.
- The optional leftover-ball second starter automatically disables when Irregular Origin has already given Psydren, preventing an unintended third starter.
- Regional shiny detection now recognizes all seven supported starter trios directly rather than depending on a single region lookup.
