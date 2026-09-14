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

v1.0.4 is the production art pass. Psydren, Vesperis, and Solipsdion each ship with dedicated **normal and shiny** front battle art, rear battle art, 64x64 summary/dex portraits, 16x32 two-frame party icons, and 16x96 six-frame follower sheets.

The engine's `pokemon.sprite` and `pokemon.icon` hooks select normal versus shiny art from the actual Pokémon instance, so the guaranteed shiny Psydren line displays its authored shiny identity everywhere instead of relying on a palette swap. Solipsdion's normal form uses the pearl/lilac/gold design; the ruby-ascended design is reserved for its shiny form.

When **Wilds of Kanto** is present, Irregular Origin wraps its final Pokedex follower provider only for the three custom species so the dedicated follower sheets are used without changing other Pokémon providers. Species IDs and save compatibility remain unchanged.


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

### v1.0.4

- Added the complete 30-file production sprite pack: normal + shiny front, back, menu/stat portrait, party icon, and follower art for all three stages.
- Added runtime shiny routing for battle, summary/dex, and party visuals.
- Added dedicated rear-facing battle sprites instead of mirroring/reusing the front art.
- Added optional Wilds of Kanto follower-provider integration for the custom 16x96 walker sheets.
- Locked Solipsdion's normal presentation to pearl/lilac/gold and its shiny presentation to the ruby-ascended art direction.
- Removed the old build-time art regeneration path; CI now validates authored PNGs without overwriting them.
