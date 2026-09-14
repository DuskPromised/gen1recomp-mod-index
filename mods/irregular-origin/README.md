# Irregular Origin

Custom starter-story mod for **Pokémon Red Earth: The Philosopher's Stones**.

## Fated encounter

The first time the player touches Oak's starter table, Oak interrupts:

> This one isn't from any region I know.  
> It was found where records end.

The player receives a guaranteed shiny **Psydren** at level 5. The vanilla starter flag is intentionally left unset, so the player must then choose one of Allgen Kaizo's regional table starters as a conventional companion. Red Earth Kaizo Bridge handles that companion's shiny treatment.

## Evolution line

- **Psydren** — Psychic / Water — evolves at Lv. 16
- **Vesperis** — Psychic / Ghost — evolves at Lv. 36
- **Solipsdion** — Psychic / Dragon

Balanced Gen-I five-stat totals: 275 / 375 / 515.

## Signature moves

- **Sovereign Rage** — Dragon / Special — 80 power / 100 accuracy / 10 PP
- **Seraph's Verdict** — Dragon / Special — 140 power / 90 accuracy / 5 PP / recharge

## Shiny logic

Psydren receives a valid Gen-II-compatible shiny DV spread: Attack 15, Defense 10, Speed 10, Special 10. The line's art is authored as its radiant Irregular appearance.

## Philosopher Stone resonance

The line can bind stones normally, but its hidden Irregular resonance adds modest secondary effects and unique party-menu lore. It also senses Greater Stone locations when carried in the active party.

## Art status

v1.0.2 normalizes all party-icon sheets to the engine's vertical 16x32 two-frame format and regenerates every 64x64 battle image from a verified icon frame. This fixes the corrupted Psydren PNG crash and the broken party-menu icon while preserving species/save IDs. The current package prioritizes functional battle/icon art; dedicated rear-facing and follower sheets can replace these assets later without changing species IDs or save compatibility.


### v1.0.1

Corrected the registered Psychic type id to the engine/Kaizo `PSYCHIC` registry key before cart integration.


### v1.0.2

- Fixed Psydren battle crash caused by a malformed PNG IDAT CRC.
- Rebuilt all three battle-front PNGs from verified icon frames.
- Normalized party icons from horizontal 32x16 sheets to GenRecomp's required vertical 16x32 two-frame layout.
- Added Pillow decode/CRC validation and exact-dimension checks to CI so malformed art cannot publish again.
- The existing Wilds follower fallback remains functional; dedicated six-frame walker art is still a later art upgrade.


### v1.0.3

- Psydren/Vesperis/Solipsdion now use a private **CONFUSION** move record with the same Psychic power/accuracy/PP/confusion side effect, but a particle-based battle animation instead of the classic scanline-deformation animation.
- This specifically avoids the odd Dramaless 3D battlefield/sprite warping seen during the first Psydren tests.
- Species IDs, save compatibility, shiny DVs, evolution levels, stats, and the rest of the learnsets are unchanged.
- Battle/follower art is still the functional concept set; the dedicated final art pass remains separate from this gameplay hotfix.
