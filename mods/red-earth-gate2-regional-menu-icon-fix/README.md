# Red Earth — Gate 2 Regional Shiny Menu/Icon Fix 0.2.5

Standalone additive Gate 2 patch built on the accepted 0.2.4 cart.

## Scope
- reads genuine shiny state only
- supplies shiny 16x32 party/menu icons for Fennekin line and selectable Grass starter lines
- covers stock party menu plus the generic `pokemon.icon` route used by menu/box/summary UI
- preserves normal individuals unchanged

## Supported lines
Bulbasaur, Chikorita, Treecko, Turtwig, Snivy, Chespin, Rowlet, Grookey, Sprigatito, and Fennekin, including evolutions.

## Explicitly unchanged
- Psydren/Vesperis/Solipsdion authored art
- battle front/back sprites
- followers
- sprite scaling/grounding
- starter routing / region selector
- shiny state and evolution persistence
- Solipsdion 54-pixel repair
- gold/lilac sparkle and shiny sound
- Nature/passives

If an icon asset cannot load, the accepted engine icon is used instead of drawing a blank row.
