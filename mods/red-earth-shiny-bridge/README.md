# Red Earth Shiny Bridge

A deliberately small compatibility mod for the split Red Earth stack.

## Ownership

This bridge **does not render Pokemon** and does not replace Oak's working
dialogue, region selector, battle renderer, or follower runtime.

It owns only the underlying shiny state for Red Earth's three player gifts:

1. Psydren
2. Oak's normal regional companion (including Fennekin)
3. the optional final regional starter

Each gift receives Gen-2-compatible shiny DVs plus `mon.shiny = true` and a
persistent `redEarthGuaranteedShiny` marker.

## Presentation remains separate

- **Crystal Animated Sprites with Shiny Visuals** owns battle shiny
  detection, sparkle animation, and shiny SFX.
- **Wilds of Kanto** owns the follower entity and shiny follower variant.
- **Red Earth Irregular Upgrade** owns Psydren/Vesperis/Solipsdion authored
  normal/shiny art.

That separation is intentional: no duplicate battle overlays, palette hooks,
or follower runtimes are introduced here.

## Evolution and saves

Gen1Recomp mutates the existing Pokemon object during Gen-1 evolution. This
bridge reasserts the explicit shiny flag after `pokemon.evolved` and repairs
marked Pokemon on game ready / map entry. Shiny-compatible DVs therefore
remain the source of truth while custom metadata survives with the Pokemon.

## Test target

For a fresh Oak sequence, verify all three player gifts have shiny DVs and
shiny presentation. Then evolve them and verify the shiny state remains.
