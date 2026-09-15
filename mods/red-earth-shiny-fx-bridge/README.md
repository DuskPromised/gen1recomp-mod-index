# Red Earth Shiny FX Bridge v1.0.1

A tiny compatibility layer for the Red Earth stack.

The upstream **SHINY_POKEMON** mod already provides the yellow/white sparkle burst, shiny SFX, and shiny name marker. In the Dramaless/Wilds voxel path it can also see a stale `player._pokepcAsPokemon` flag after the trainer sprite has been restored, which projects the follower sparkle onto the trainer.

This bridge:

- clears that stale player-control flag only when the visible player sprite is actually the trainer;
- reasserts `pokepcShiny` from the real follower Pokémon object;
- runs immediately before the world draw pass so SHINY_POKEMON targets the actual follower.

It does **not** create shiny Pokémon, recolor sprites, or own regional/Irregular artwork.

## v1.0.1 targeting hardening

When Wilds is set to **Control = Trainer**, the trainer can never be the controlled-Pokémon sparkle target. The bridge now clears that stale state unconditionally in Trainer control mode and reasserts `pokepcShiny` on the real follower in both Wilds entity collections immediately before drawing.
