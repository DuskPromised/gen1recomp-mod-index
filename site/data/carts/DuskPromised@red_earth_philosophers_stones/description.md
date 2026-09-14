# Pokémon Red Earth: The Philosopher's Stones

A separate, harder Red Earth cart built around **Gen1 Recomp Allgen Kaizo** rather than Gen151. The original **Pokémon Red Earth** cart remains a separate experience and is not replaced by this one.

## v1.0.2 — Greater Stones

Cart edition **1.0.2** upgrades the Philosopher Stones system to **v1.1.0**. The four badge-awakened Lesser Stones remain, but four **Greater Stones** are now actual exploration/story discoveries rather than automatic rewards. The cart also adds an **ALCHEMY** start-menu journal that tracks found relics and the alchemical essences they reveal.

### Lesser Stones

- **Ruby Stone** — awakens from the Boulder Badge — +15% damage dealt.
- **Sapphire Stone** — awakens from the Cascade Badge — -15% damage taken.
- **Emerald Stone** — awakens from the Rainbow Badge — restores 1/16 max HP after each completed battle turn.
- **Amethyst Stone** — awakens from the Marsh Badge — a missed move gets a 10% second-chance accuracy roll.

### Greater Stones

- **Moonstone** — after earning the Cascade Badge, return to **Mt. Moon B2F** with a normal Moon Stone. The normal Moon Stone acts as the catalyst and is consumed. The Greater Moonstone cleanses the holder's first major status condition each battle and reveals **Aether Essence**.
- **Obsidian Stone** — after the restless Marowak spirit has departed, return through **Pokémon Tower 7F**. Obsidian lets its holder survive one otherwise-lethal hit at 1 HP per battle and reveals **Salt Essence**.
- **Solar Stone** — after earning the Volcano Badge, investigate **Pokémon Mansion B1F** again. Solar creates a field-like aura while its holder is active: Fire damage +25%, Water damage -25%, and reveals **Sulfur Essence**.
- **Tempest Stone** — after defeating or capturing Zapdos, investigate the charged area of the **Power Plant**. Tempest boosts the holder's Electric damage by 20%, immediately cleanses paralysis, and reveals **Mercury Essence**.

Greater Stones are not consumed when their essences are learned. The journal knowledge is permanent progression for the later Prime-Stone / final Philosopher's Stone system.

## Binding

Use the Pokémon party submenu's **STONE** entry to bind or remove a relic. A physical stone can resonate with only one Pokémon at a time. The binding lives on that Pokémon, so it follows the Pokémon through party reordering, PC storage, evolution, save and reload.

## Core identity

- **Allgen Kaizo v0.8.3** supplies the expanded ~908-species roster, modernized type/move ecosystem, six-Pokémon trainer teams, competitive movesets and AI, boss Megas, and expanded Kanto encounter pools.
- **Dramaless Shape v2.0.4** replaces Battle Art Voxel Fork. It keeps voxel Kanto while using native 2D battle cards and avoids the Battle Art rendering path.
- **Wilds of Kanto v2.1.9** supplies visible overworld Pokémon and party followers, with fallback rendering for species that do not have dedicated walker sheets.
- **Red Earth Kaizo Bridge v1.0.0** leaves Kaizo's authored level floors intact while dynamically raising wild Pokémon to approximately **-2 to +1** of the strongest healthy party Pokémon and trainers to **+0 to +2**. It never scales a stronger authored encounter downward.

## Oak's Lab

Allgen Kaizo's region selector remains authoritative. Choose Kanto, Johto, Hoenn, Sinnoh, Unova, Kalos, or Alola; Oak's three balls become that region's Grass / Fire / Water trio.

After you choose and the rival takes the counter-pick, the surviving ball remains claimable once. It gives the **leftover starter from the same selected region**. Both player Oak gifts receive real Gen-2-compatible shiny DVs by default.

## Intentionally omitted

To keep the expanded Kaizo runtime coherent and reduce overlap, this cart does **not** include Gen151, Battle Art Voxel Fork, Pokédex Plus, Moves Manager, Move Learn Stats, Mirage of Mew, the Kanto-only Shiny Gifts & Starters / Take the Last Starter pair, Shiny Pokémon, Kanto Achievements, Eevee Three Stones, or Crystal Onix.

The Red Earth quest pack, cart-aware Multi Save, BetterMenus, Wilds, avatar choice, bag/box/QOL stack, and other low-overlap conveniences remain.

## Version archive

Published cart builds are never overwritten. Every released `.g1rcart` remains in:

`site/data/carts/DuskPromised@red_earth_philosophers_stones/`

The machine-readable `versions.json` in that folder records each released version, file URL, byte size, and SHA-256. GenRecomp++ follows the newest release from the normal cart feed, while older editions remain directly downloadable for anyone who wants them.


## Irregular Origin

**Irregular Origin v1.0.1** adds a new three-stage species line created specifically for this cart:

- **Psydren** — Psychic / Water — the Abyssal Seed
- **Vesperis** — Psychic / Ghost — the Gravekeeper's Storm
- **Solipsdion** — Psychic / Dragon — the Sovereign Apex

The first interaction with Oak's starter table triggers a fated encounter instead of immediately opening the regional starter selection. Oak entrusts the player with a guaranteed shiny Psydren at level 5, using a legitimate Gen-II-compatible shiny DV spread. The normal starter flag stays unset, so the player then chooses a conventional regional companion through Allgen Kaizo's existing seven-region starter system.

Psydren evolves at level 16 and Vesperis at level 36. Solipsdion learns two custom Dragon-special signature moves: **Sovereign Rage** and **Seraph's Verdict**.

The entire line has hidden **Irregular Resonance** with Philosopher Stones. It gains modest secondary effects from bound stones, unique resonance dialogue in the party menu, and atmospheric reactions near Greater Stone discovery sites. The red core visible through the evolutionary line is deliberately tied to the larger alchemical mystery.

v1.0.1 uses the approved concept-poster pixel artwork as the first functional battle/icon set. Dedicated rear-facing and follower sheets can be upgraded later without changing species IDs or save compatibility.


## v1.0.4 — Irregular art hotfix

Irregular Origin is pinned to v1.0.2. Psydren's malformed battle PNG was rebuilt from verified source art, all Irregular party icons were normalized to GenRecomp's 16x32 two-frame layout, and CI now verifies PNG decoding plus dimensions before publishing. This fixes the Oak rival battle/switch-in crash and the broken Psydren party-menu icon. Wilds follower fallback remains functional; dedicated six-frame follower art is a later visual upgrade.
