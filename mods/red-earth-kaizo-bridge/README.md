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


## v1.0.2

- Fixes the Oak receipt-text leak where a correctly granted Froakie could still be announced as **SQUIRTLE**. Player and rival receipt text now resolve through the selected region.
- Restores the optional remaining Poké Ball for the Irregular route instead of disabling it after Psydren.
- Touching that final ball now opens the region selector again. The ball keeps its grass/fire/water element, but the player can choose a **different region** for the optional extra starter.
- The player can simply leave after Psydren + the conventional companion; the final ball is never forced.
- Final-ball starters continue through the same Gen-II-compatible shiny-DV gift hook when SHINY STARTERS is enabled.


## v1.0.3

- Fixes the optional final-ball receipt using the **companion region's** name after the player deliberately chose a different region. A Kanto grass choice now says **BULBASAUR**, not CHESPIN, while still granting Bulbasaur.
- Keeps the original companion/rival placeholder rewrite intact, so a Kalos water companion/rival still displays **FROAKIE** instead of SQUIRTLE.
- Cleans custom-species gift text by translating GenRecomp's pending internal species id through the registered display name before nickname/received text. The player now sees **PSYDREN**, not the internal namespace **IRR_PSYDREN**.
- Species ids, saves, starter selection, shininess, rival continuity, battle art, followers, and difficulty rules are unchanged.
