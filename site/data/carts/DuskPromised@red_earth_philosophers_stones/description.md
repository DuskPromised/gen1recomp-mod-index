## Shiny presentation ownership

Red Earth keeps shiny **state** and shiny **presentation** separate.

- **Red Earth Shiny Bridge** guarantees the Oak gifts have Gen-2-compatible shiny DVs plus `mon.shiny = true`.
- **Shiny Pokemon 1.0.1** supplies the missing battle sparkle/SFX, party/summary shiny marker, and looping follower sparkle.
- `SHINY RATE` is pinned **OFF**, so this renderer does not change ordinary wild shiny odds.
- `SHINY COLORS` is pinned **OFF** so it cannot recolor Psydren/Vesperis/Solipsdion on top of the authored custom shiny PNGs.
- `SHINY INTRO` is pinned **ON**.
- Crystal Animated Sprites remains installed for its existing battle presentation; the new FX layer is present specifically so custom/all-generation shiny gifts are not dependent on Crystal artwork coverage.

The authored Irregular shiny art remains controlled by Red Earth Irregular Upgrade. Standard regional-starter shiny colour assets are a separate visual pass; system shiny state and sparkle behavior do not depend on that art pass.

## Recovery architecture

This cart deliberately stays **split into separate mods**. The known-good v1.0.10 stack remains the foundation.

Current layered ownership:
- **Irregular Origin 1.0.9** — species registration and working Oak acquisition flow
- **Red Earth Irregular Upgrade 1.0.0** — final Irregular art, Modest, Distance, Solitary Reign, shiny persistence and Oak speaker labels
- **Philosopher Stones 1.1.0** — existing working Stone framework only; final Crucible/Second Condition work comes in a later separate layer
- **Red Earth Kaizo Bridge 1.0.3** — dynamic difficulty, regional companion/third starter, rival continuity and starter shiny flags
- **Wilds of Kanto 2.1.9** — follower runtime
- **Leaf Avatar 2.0.0** — existing player selector baseline

No unified `red_earth_irregular` mod is loaded.

# Red Earth: The Irregular and The Philosopher Stones

A unified Red Earth cart built on **Gen1 Recomp Allgen Kaizo**, centered on the Irregular line and the completed Philosopher's Stone system.

## The Irregular

- **Psydren** — Psychic / Water
- **Vesperis** — Psychic / Ghost
- **Solipsdion** — Psychic / Dragon by default
- Canonical Solipsdion anatomy: **2 flight wings + 4 hand-wings + 1 crown wing**
- Mechanical **Modest** nature layer: +10% Special, -10% Attack
- **Distance**: the first damaging hit after entry is reduced by 25%
- **Solitary Reign**: when Solipsdion is the sole conscious Pokémon on its side, Special and Speed are +20% and negative Special/Speed stages are suppressed

All three stages ship with authored normal/shiny battle art, menu art, party icons, follower sheets, and authored right-facing follower art.

## Oak's Lab

The opening sequence is:

1. **Psydren** — guaranteed genuine shiny
2. **Fennekin** companion — guaranteed genuine shiny
3. Optional final ball — reopen the installed regional starter selector and receive that region's **Grass starter**, also guaranteed genuine shiny

The rival uses the Froakie line after the Fennekin choice. Genuine shiny state is carried by shiny-compatible DVs and persists through evolution.

## Rival and player presentation

- Player option: **Human Ansem** or default Red
- Rival gender choice during Oak's introduction: **Male** or **Female**
- Female rival presentation uses the supplied **Melony** battle/Oak and overworld sprites
- Rival naming remains independent from gender

## Philosopher's Stone

The cart has one physical Philosopher's Stone. It can be bound to one Pokémon at a time and reclaimed only at the Cinnabar Crucible before being rebound elsewhere.

Four alchemical materials feed the Crucible:

- **Sulfur** — Blaine milestone
- **Mercury** — Silph / Master Ball milestone
- **Aether** — Mr. Fuji rescue milestone
- **Salt** — Giovanni milestone

After Champion status, the Crucible performs:

**Calcination → Dissolution → Separation → Conjunction → Rubedo**

Ordinary Stone-bound Pokémon receive the First Condition. The Irregular line progresses through **Resonance → Communion → Awakening**.

### Second Condition — Aetheric Transmutation

Awakened, Stone-bound Solipsdion keeps Psychic as its primary type while its secondary type follows the environment:

- neutral / ordinary interior: Dragon
- harsh sun / volcanic: Fire
- rain / ocean: Water
- snow / hail / ice cavern: Ice
- sandstorm / desert: Ground
- cave / rocky underground: Rock
- dense forest / overgrowth: Grass

Active battle weather overrides map attunement. **Seraph's Verdict** follows the current secondary type.

## Kaizo dynamic difficulty

The former Red Earth Kaizo Bridge scaling is integrated directly into the unified mod and is **enabled on first launch**.

- **Dynamic Wilds: ON** — wild encounters target the strongest healthy party Pokémon at **-2 to +1**, but authored encounters that are already stronger are never lowered.
- **Dynamic Trainers: ON** — Kaizo trainer levels target the strongest healthy party Pokémon at **+0 to +2**, while Allgen Kaizo keeps control of team composition, competitive movesets, boss design and AI.
- The scripted level-5 Oak rival tutorial battle stays at its authored level. Scaling begins immediately afterward.
- Both switches remain editable in Mod Options.

## Follower and voxel defaults

Red Earth ships with these editable defaults:

- **Dramaless Shape R.DIST:** FAR
- **Wilds Sprite Style:** Poke Followers / GSC
- **Control Mode:** Trainer
- **Followers:** 1
- **Trainer Trail:** Off

Wilds of Kanto owns follower runtime. Red Earth: The Irregular and The Philosopher Stones supplies the custom Irregular follower art and shiny follower sparkle layer, avoiding duplicate follower runtimes.

## Runtime stack

- Allgen Kaizo supplies the expanded roster and Kaizo battle/encounter framework
- Dramaless Shape supplies voxel Kanto
- Crystal Animated Sprites supplies the standard Gen-2-style shiny battle reveal/SFX
- Wilds of Kanto supplies visible overworld Pokémon and follower runtime
- Red Earth: The Irregular and The Philosopher Stones owns the custom species, starter sequence, Stone system, Ansem/Melony presentation, passives, and authored custom shiny/follower assets

The older split **Irregular Origin**, **Philosopher Stones**, **Red Earth Kaizo Bridge**, Leaf avatar, SHINY_POKEMON, and FOLLOWERS_EX are intentionally not loaded in this unified cart to prevent overlapping ownership.

## Version archive

Published cart builds remain archived under:

`site/data/carts/DuskPromised@red_earth_philosophers_stones/`

The internal cart ID is preserved for update continuity, while the displayed nomenclature is now **Red Earth: The Irregular and The Philosopher Stones**.
