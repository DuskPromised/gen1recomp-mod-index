# Red Earth — Gate 2.5 Starter Shiny State + Icons

This is the clean Gate 2.5 rebuild from the accepted Gate 2.4 baseline.

## What changed from the failed 2.5 attempt
The failed attempt only checked whether Fennekin/regional starters were already shiny before choosing the shiny icon. It never made the actual Oak gift shiny, so the icon branch could not activate.

This rebuild first makes the intended Oak gift a genuine shiny, then routes the shiny icon from that real state.

## Scope
- Fennekin Oak gift: genuine shiny DVs + `mon.shiny = true`
- selectable Grass Oak gift: same genuine shiny state
- shiny state marker persists through evolution/save reload
- shiny party/menu icon for Fennekin line + Grass starter lines
- fresh save required for acquisition test

## Untouched from accepted Gate 2.4
- Psydren / Vesperis / Solipsdion shiny routing and authored art
- Solipsdion 54-pixel repair
- gold/lilac send-out sparkle and sound
- battle sprite scaling/grounding
- PotatoVoxel configuration
- starter-region selector itself
- followers
- Natures
- passives

## Test order
1. Use a fresh Gate 2.5 save.
2. Complete the existing Gate 2 QA gifts as before.
3. Proceed into Kaizo's normal Oak starter selection.
4. Select Kalos/Fennekin and verify it is truly shiny and its party icon is shiny.
5. On another fresh save, select a Grass starter and verify the same.
6. Evolve with Rare Candy and confirm shiny state/icon persist.
7. Reorder, box/withdraw, save, fully close, reopen.
8. Confirm Psydren/Vesperis/Solipsdion remain identical to accepted 0.2.4.
