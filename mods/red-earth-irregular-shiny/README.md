# Gate 2 — Irregular Shiny 0.2.1

Standalone shiny state and authored-art module; requires accepted Core 0.1.2.
It does not give Pokémon, replace species, or make normal individuals shiny.

`exports.makeShiny(mon, game)` is the opt-in API for later acquisition gates.
It sets Atk/Def/Spe/Spc DVs to 15/10/10/10, derived HP DV to 8, recalculates
stats while retaining damage/fainting, and sets `mon.shiny=true`.
The native engine retains the DVs through evolution, boxes and serialization.
Load/evolution listeners normalize the explicit flag from those DVs for only
the three Irregular species. They never force normal DVs to shiny values.

The species-specific sprite/icon hooks run after the normal core's hook.
They route shiny individuals to authored front/back/menu/icon PNGs; normal
individuals delegate unchanged. Species-only views have no individual shiny
identity and remain normal. No generated palette recoloring is used.

`art-sources.json` pins the historical authored raster derivatives recovered
as art only. No historical Lua module is used. Packaging verifies all 12
hashes, alpha channels and dimensions before copying the files.

Player sparkle/SFX and Potato's shiny back sizing are in the separately
downloadable Gate 2 Presentation Compatibility module. QA acquisition is
in the separately downloadable Gate 2 Test Harness. No follower systems.

Version 0.2.1 restores 54 transparent torso/leg/tail pixels in shiny Solipsdion's
48x48 battle back. The supplied master retained their original RGB values
under alpha zero. The localized restoration record recovers those values;
all previously opaque pixels and the leg gap remain unchanged. An imagegen
alpha-only repair served as the silhouette reference; generated colors were
not adopted. The other eleven images, shiny behavior and normal core are unchanged.
