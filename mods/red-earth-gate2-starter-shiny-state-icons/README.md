# Red Earth — Gate 2.5 Starter Shiny Contract

Clean rebuild from the accepted Gate 2.4 baseline.

## Versioning
The failed Gate 2.5 build was already installed on test devices, so this clean Gate 2.5 replacement is published as **0.2.6**. That higher package/cart version is intentional so the updater can offer it as an actual upgrade instead of treating it as the same version.

## Why the first 2.5 failed
The discarded patch assumed Fennekin/regional starters were already genuine shinies and only tried to swap their menu icon. If the actual Oak gift was normal, that branch could never activate. It also did not solve battle presentation.

## This rebuild
- makes the actual level-5 Oak-gift Fennekin a genuine shiny
- makes the approved selectable Grass Oak gift a genuine shiny
- preserves that shiny identity through evolution and reload
- uses dedicated shiny front/back art through the native `pokemon.sprite` chain
- uses dedicated true-color shiny party/menu icons

The battle-art route selects the shiny asset, then passes it back through the normal renderer. It does not set global scale or grounding.

## Approved Grass lines in this pass
Bulbasaur, Chikorita, Treecko, Turtwig, Snivy, Chespin, and Rowlet, including evolutions.

## Untouched from accepted Gate 2.4
- Psydren / Vesperis / Solipsdion state and authored art
- Solipsdion 54-pixel repair
- gold shiny sparkle + existing sound
- battle scale/grounding
- PotatoVoxel settings
- starter-region selector
- followers
- Nature
- passives

## Required test
Use a fresh save for acquisition.

1. Confirm the existing Gate 2 custom-line QA remains identical to 0.2.4.
2. Finish the QA gifts so normal Oak starter flow resumes.
3. Acquire Fennekin and verify: genuine shiny state, shiny battle art, shiny party/menu icon, sparkle + sound.
4. Evolve Fennekin and verify Braixen/Delphox remain shiny visually and internally.
5. On another fresh save choose one Grass starter and repeat the same checks.
6. Reorder, box/withdraw, save, fully close, reopen.
7. Confirm no sprite shrink/sink and no change to the Irregular line.
