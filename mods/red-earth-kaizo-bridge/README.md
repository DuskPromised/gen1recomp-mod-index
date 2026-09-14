# Red Earth Kaizo Bridge

Compatibility layer for **Pokémon Red Earth: The Philosopher's Stones**.

It deliberately leaves Allgen Kaizo in charge of species, encounter pools, six-Pokémon trainer teams, competitive movesets, boss Megas and AI, then adds four narrow behaviors:

- **Dynamic wilds:** strongest healthy party Pokémon -2 to +1. Existing/Kaizo levels are never lowered.
- **Dynamic trainers:** strongest healthy party Pokémon +0 to +2 across the final Kaizo roster. Existing/Kaizo levels are never lowered.
- **Regional second starter:** the one ball left after the rival's pick gives the matching leftover starter from the same region selected by Allgen Kaizo.
- **Two shiny starters:** both player Oak-lab gifts get real Gen-2-compatible shiny DVs, regardless of which supported regional trio was selected.

The first Oak-lab rival remains at Kaizo's intended vanilla level. Wilds of Kanto contact battles are handled through the normal `start_battle wild` script seam, so visible encounters receive the same scaling policy.

This mod is intentionally incompatible with the old Kanto-only Take the Last Starter and Shiny Gifts & Starters mods.
