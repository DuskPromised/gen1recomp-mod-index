# Red Earth 2 — Ground-Up Rebuild Plan

Status: architecture reset. The existing `red_earth` and `red_earth_philosophers_stones` carts are reference/archive only and are not development baselines.

## Design rule
Treat the cart like a Skyrim modlist: one owner per system, explicit dependencies, explicit load order, pinned options, and compatibility patches only where ownership overlaps.

No bridge may replace a renderer, sprite source, shiny owner, follower owner, or data registry unless its contract is documented first.

## What successful carts teach us
- OMEGA RANDOM COMPETITION publishes one pinned gameplay mod.
- Wild Crystal publishes two consolidated suite mods with an explicit load order.
- Wild Green publishes four pinned mods with an explicit load order.
- Development/nightly work is separated from release identity and saves.

Red Earth will follow the same pattern: develop in small isolated modules, test each module, then merge stable modules into a small suite before release.

## Canonical asset source
The Irregular line must be derived only from the approved transparent master archives:
- Stage-1-Psydren-Transparent-PNG-Masters.zip
- Stage-2-Vesperis-Transparent-PNG-Masters.zip
- Stage-3-Solipsdion-Transparent-PNG-Masters.zip
- Irregular-Line-All-Stages-Transparent-PNG-Masters.zip

Older `irregular_origin` sprites and all v1.2.x/v1.3.0 visual bridge assets are forbidden.

## Development modules
### red_earth_core_next
Owns starter flow, gender/rival choice contract, Irregular species records, genuine shiny construction/DVs, evolution persistence, shared save metadata. No renderer overrides.

### red_earth_visuals_next
Owns canonical Irregular battle front/back, summary/menu/party icon routing, acquisition/Pokédex presentation, follower sheets, species-specific scale/grounding integration. No shiny-state creation.

### red_earth_alchemy_next
Owns Philosopher's Stone, reagents, Crucible, First Condition, Resonance/Communion/Awakening, Aetheric Transmutation, weather/terrain dominance, Seraph's Verdict.

### red_earth_traits_next
Added only later: Modest mechanical nature, Distance, Solitary Reign.

### red_earth_player_next
Added only after core Pokémon systems pass: player choices, Human Ansem, rival presentation.

### red_earth_patch_<target>
Single-purpose compatibility translators only. Never a third owner of the same system.

## Build gates
### Gate 0 — Fresh cart identity
New test cart ID and save scope. No inherited Red Earth custom mods.
Pass: launches; old assets cannot appear.

### Gate 1 — External foundation
Pin exact versions, hashes, dependencies, options, and explicit load order for species/data, battle presentation, shiny presentation, and overworld/followers.
Pass: ordinary stock Pokémon render/animate/follow/battle correctly before Red Earth code exists.

### Gate 2 — Three starter route
Add only `red_earth_core_next`.
Pass: Psydren, Fennekin, and selected Grass starter are granted and are genuine shiny by state/DVs.

### Gate 3 — Canonical Irregular art
Add `red_earth_visuals_next`.
Pass Psydren first: acquisition image, Pokédex image, party icon, summary/menu, battle front/back, follower, scale, grounding, authored shiny routing. Then repeat for Vesperis/Solipsdion.

### Gate 4 — Shiny presentation
No custom screen-coordinate sparkle patch.
Pass: official shiny Fennekin/regional starter, authored shiny Psydren, menu shiny state, battle reveal/SFX, follower state across map/save/evolution.

### Gate 5 — Battle scale contract
Freeze supported scale/ground behavior.
Pass: no global shrink, no Treecko floor clipping, intended stage growth, breaking options pinned where supported.

### Gate 6 — Philosopher's Stone
Add only `red_earth_alchemy_next`.
Pass: reagents/crafting, one-Stone binding, First Condition, Irregular progression, terrain attunement, weather override/restoration, Seraph's Verdict.

### Gate 7 — Traits
Nature, then Distance, then Solitary Reign. Test independently.

### Gate 8 — Player/rival presentation
Custom player/rival systems only after Pokémon systems are stable.

### Gate 9 — QOL/story content
Menus, box, bag, quests, achievements, saves, etc. one family at a time.

### Gate 10 — Consolidation
Merge stable Red Earth modules into the smallest practical release suite. Keep only necessary compatibility patches separate.

## Conceptual load order
1. species/data foundation
2. battle renderer/presentation
3. shiny presentation
4. overworld/follower owner
5. Red Earth core
6. Red Earth visuals
7. Red Earth alchemy
8. Red Earth traits
9. Red Earth player/rival
10. compatibility patches
11. UI/QOL/story additions

Exact order is accepted only after every manifest/hook is audited.

## Options policy
Every option that changes identity or can break compatibility is pinned after validation:
- battle rendering/scaling
- follower mode/count/control
- menu mode
- shiny presentation
- dynamic trainer/wild settings

Purely cosmetic, non-contract options may stay user-configurable.

## Deferred idea — Pathways
Parked until after Gate 10.
Potential future system: player selects a Pathway around Pokédex acquisition; Pathways affect Pokémon/stat progression; rivals/gym leaders get authored Pathways.
