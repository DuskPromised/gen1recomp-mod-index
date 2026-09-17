# Red Earth — Gate 2 Starter First-Presentation Fix 0.2.7

Additive timing/presentation repair on top of the device-green 0.2.6 cart.

## Fixes
- Fennekin / approved regional Grass Oak gifts are made genuine shiny at the instant their Pokémon object is created, before the gift flow can expose them to battle presentation.
- Oak's starter Pokédex/acceptance preview uses the same authored shiny front art already proven in 0.2.6.
- The first player send-out receives the accepted warm gold sparkle with restrained lilac glint and shiny sparkle sound, centered on the Pokémon.

## Explicitly unchanged
- Gate 2.6 shiny battle/front/back/menu/icon routing
- Psydren / Vesperis / Solipsdion art and shiny behavior
- Solipsdion 54-pixel repair
- sprite scaling and grounding
- starter/region-selection logic
- evolution logic
- Nature and passives
- follower behavior

The creation shim is one-shot: it is armed only for the transformed Oak `give_pokemon` command, consumed by that single level-5 starter construction, and restored before the gift flow continues.
