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

v1.0.9 carries the first complete Pokémon-native sprite authenticity pass for the entire Irregular line, while retaining the hardened corruption-checking release pipeline. Each species now ships separate authored **normal and shiny** assets for battle front, battle back, menu portrait, party icon, and follower presentation.

- Battle front/back and menu portraits: 64×64 true-color PNGs
- Party icons: engine-native 16×32 two-frame sheets
- Followers: 16×96 six-frame walker sheets
- Runtime shiny routing uses GenRecomp's sanctioned `pokemon.sprite` and `pokemon.icon` hooks, so the shiny is a distinct picture rather than a palette swap.
- The guaranteed gift Psydren remains shiny and keeps that shiny identity through Vesperis and Solipsdion.
- Solipsdion's **normal** form is the pearl/lilac/gold sovereign design. Its **shiny** is the ruby-ascended design.
- Solipsdion's seven-wing canon remains **2 flight wings + 4 hand-wings + 1 crown wing**.
- Wilds integration supplies the dedicated six-frame Irregular follower sheets while delegating every non-Irregular species back to Wilds unchanged.

## Dramaless / voxel presentation

The Irregular artwork should stay **2D**. Dramaless Shape 2.x deliberately stages native 2D Pokémon battle pictures as camera-facing **3D billboards** inside its voxel arena; 3D Pokémon models belong to StadiumBattleFX rather than Dramaless itself. Irregular Origin therefore supplies true-color 2D front/back PNGs and lets Dramaless project them into the voxel scene.

The overworld/follower side works the same way: the dedicated 16×96 six-frame walker sheets remain 2D textures, while Wilds of Kanto and compatible voxel renderers place those textures on world billboards with depth, grass occlusion, and geometry-aware sizing.

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


### v1.0.5

- Repaired the production PNG set and made CI validate all 30 authored assets before packaging.
- Restored clean copies of art files that were damaged during the previous binary transfer and corrected remaining PNG chunk CRCs without regenerating the artwork from icons.
- Kept the final art as true-color 2D textures because Dramaless 2.x renders native Pokémon art as 3D billboards in its voxel arena; no 3D model conversion is required.
- Improved the `pokemon.sprite` wrapper so Dramaless' **BACK SPRITES** setting still composes correctly while shiny Irregulars keep their authored shiny front/back art.
- Declared Wilds of Kanto and Dramaless Shape as optional integrations; neither is required to use Irregular Origin.
- Version/package/index advanced to v1.0.5. Species IDs and save compatibility are unchanged.


### v1.0.6

- Corrected integration metadata without changing species IDs, stats, moves, saves, or authored sprite art.
- Wilds of Kanto and Dramaless Shape are documented as **optional integrations**, not hard/optional manifest dependencies; Irregular Origin remains usable without either graphics/overworld mod.
- Compatibility is verified against the currently released **Wilds of Kanto v2.1.9** provider API and **Dramaless Shape v2.0.4**.
- Keeps the complete 30-file normal/shiny production art set and the Dramaless-aware front/back shiny routing introduced in v1.0.5.
- Publishes a new immutable v1.0.6 package rather than overwriting the already-published v1.0.5 archive.


### v1.0.7

- Rebuilt the release from the already-clean v1.0.6 source art instead of retransferring or regenerating the artwork.
- Hardened CI with explicit PNG signature/chunk/CRC validation in addition to Pillow decode checks.
- Verifies every expected frame sheet is non-empty: two party-icon frames and all six follower frames for normal and shiny variants.
- Verifies the packaged ZIP after creation with ZIP CRC testing, exact file-list checks, byte-for-byte source/package comparisons, PNG re-validation from inside the archive, and manifest/version checks.
- The release is blocked before publication if any sprite byte, PNG chunk, frame sheet, ZIP member, or package metadata is corrupted or missing.
- Publishes a new immutable v1.0.7 archive; v1.0.6 remains unchanged for rollback.


### v1.0.8

- Reworked all twelve battle images (front/back × normal/shiny × three stages) into deterministic low-color, hard-edged pixel sprites instead of downscaled illustration-like PNGs.
- Player-side battles now always use the authored **back** angle; enemy-side battles use the authored **front** angle. Dramaless can still billboard the texture in 3D, but it can no longer silently replace an Irregular back sprite with its front portrait.
- Menu portraits remain the richer 64×64 artwork; battle sprites are intentionally a separate visual treatment.
- **IRR CONFUSION** no longer borrows SWIFT. It now uses PSYBEAM's psychic projectile animation while preserving Confusion's 50 power, accuracy, PP, Psychic typing, and confusion side effect.
- CI pixel-locks and validates the battle sprites before packaging: binary alpha, low color count, correct dimensions, PNG CRCs, and byte-identical ZIP verification.


### v1.0.9 — Round-one sprite authenticity pass

- Replaced the full battle front/back set for **Psydren, Vesperis, and Solipsdion**, normal and shiny, with cleaner full-body sprites derived from the approved round-one sprite sheets.
- Replaced the menu/status art with **compact full-body versions** so the stats screen shows the complete creature rather than an oversized head/upper-body crop.
- Preserved the existing party icons and six-frame followers because those were already reading correctly in-game; the follower presentation remains the strongest continuity anchor across the line.
- Player-side art remains a genuine rear view, while enemy-side art remains a genuine front view.
- Psydren keeps its pearl/aqua normal identity and seafoam/mint shiny; Vesperis keeps violet/indigo normal and ash/crimson shiny; Solipsdion keeps pearl/lilac/gold normal and ruby-ascended shiny.
- Solipsdion still preserves the mandatory **seven-wing canon: 2 flight + 4 hand + 1 crown**.
- CI no longer mutates authored battle art at build time. It validates the final sprites as shipped: PNG CRC, decode, 64×64 dimensions, binary alpha, bounded framing, and a controlled low-color pixel palette.
