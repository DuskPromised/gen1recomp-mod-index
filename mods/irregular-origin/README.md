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

v1.0.4 is the production art pass for the entire Irregular line. Each species now ships separate authored **normal and shiny** assets for battle front, battle back, menu portrait, party icon, and follower presentation.

- Battle front/back and menu portraits: 64×64 true-color PNGs
- Party icons: engine-native 16×32 two-frame sheets
- Followers: 16×96 six-frame walker sheets
- Runtime shiny routing uses GenRecomp's sanctioned `pokemon.sprite` and `pokemon.icon` hooks, so the shiny is a distinct picture rather than a palette swap.
- The guaranteed gift Psydren remains shiny and keeps that shiny identity through Vesperis and Solipsdion.
- Solipsdion's **normal** form is the pearl/lilac/gold sovereign design. Its **shiny** is the ruby-ascended design.
- Solipsdion's seven-wing canon remains **2 flight wings + 4 hand-wings + 1 crown wing**.
- Wilds integration supplies the dedicated six-frame Irregular follower sheets while delegating every non-Irregular species back to Wilds unchanged.


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

- Replaced the functional concept placeholders with the final production art pass for Psydren, Vesperis, and Solipsdion.
- Added independent normal/shiny front, back, menu, party-icon, and follower assets for all three stages.
- Added runtime shiny image routing for battle/summary art and party icons; no palette-swap shortcut is used.
- Added dedicated Wilds follower sheets for the Irregular line.
- Preserved Solipsdion's pearl/lilac/gold normal identity and ruby-ascended shiny identity, including the seven-wing anatomy requirement.
- Removed the old build-time behavior that regenerated battle art from tiny party icons.
