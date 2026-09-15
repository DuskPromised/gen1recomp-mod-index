# Red Earth Regional Shiny Art v1.0.1

A separate visual layer for **Pokémon Red Earth: The Irregular and The Philosopher Stones**.

## Owns

- Dedicated shiny front/back artwork for every Kanto-through-Alola regional starter family used by Red Earth's selector.
- Shiny summary/menu portraits.
- Shiny party icons.
- Proper Fennekin/Braixen/Delphox normal + shiny follower walker sheets, because Wilds' built-in land runtime set currently stops at National Dex 649.

## Does not own

- Whether a Pokémon is shiny. That remains **Red Earth Shiny Bridge**.
- Psydren/Vesperis/Solipsdion artwork. That remains **Irregular Origin**.
- Sparkle/SFX presentation. That remains the shiny FX layer.

Battle/summary assets are normalized from the pinned PokeAPI sprite set with nearest-neighbor-only processing. The Fennekin-line follower source is the pinned PokéWilds overworld sprite set.

## Wilds provider-chain compatibility

Wilds' public `followers` style resolves through `followers_ex → pokemmo → pokedex`. v1.0.1 wraps every available provider in that chain for Fennekin/Braixen/Delphox, so an earlier normal-art provider cannot mask the dedicated Red Earth shiny walker.
