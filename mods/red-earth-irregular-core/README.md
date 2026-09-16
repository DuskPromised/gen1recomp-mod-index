# Red Earth — Gate 1: Irregular Core

This is the first Red Earth-owned module built on the verified Gate 0A foundation.

**Architecture rule:** Gate 1 remains a standalone species/data module. It does not absorb later Red Earth systems. Shiny state/art routing belongs to a separate Gate 2 module; followers, starter flow, characters, passives, Stone mechanics, environment logic, and compatibility patches remain separate until final production consolidation.

## Gate 1 scope

This package contains only the stable species/data layer for:

- Psydren — Psychic/Water — Lv. 16 → Vesperis
- Vesperis — Psychic/Ghost — Lv. 36 → Solipsdion
- Solipsdion — Psychic/Dragon

It registers canonical stats, learnsets, evolution data, three Red Earth moves, normal battle/menu/icon art, Pokédex data, and stable species IDs used by save files.

## Intentionally absent

Gate 1 does **not** implement:

- Oak/starter acquisition
- guaranteed shiny state or shiny art routing
- Wilds/followers
- player/rival gender, Ansem, or Melony
- Distance or Solitary Reign
- Philosopher's Stone mechanics
- Aetheric Transmutation/environment typing
- quest integration

Those systems belong to later gates and should not be backported into this core.

## Canonical stats

| Species | Type | HP | Atk | Def | Spe | Spc |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Psydren | Psychic / Water | 55 | 40 | 65 | 45 | 70 |
| Vesperis | Psychic / Ghost | 70 | 55 | 75 | 80 | 95 |
| Solipsdion | Psychic / Dragon | 95 | 85 | 105 | 105 | 125 |

## Presentation rule

All routing is species-specific. The module does not install global battle-sprite scaling or global renderer wrappers. Unrelated Pokémon are delegated untouched.

Psydren's immersive acquisition/Dex reveal is intentionally deferred to the starter-path gate. The Dex entry data is already present here so that later presentation can use the canonical species record rather than duplicating lore.
