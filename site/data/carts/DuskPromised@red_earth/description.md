# Pokémon Red Earth

A curated Pokémon Red cart combining voxel battles, all 151 obtainable in one save, a boy/girl avatar choice, **The Mirage of Mew**, refined widescreen menus, shiny Pokémon, quality-of-life upgrades, Kanto achievements, and the FAFF0x quest/story layer.

**Red Earth v1.0.6 removes Gen1 Modern UI, Modern UI Fix, and Wilds of Kanto.** Gen1 Modern UI caused misaligned touch/options input on iOS; Wilds of Kanto was removed while isolating the encounter-field crash.

**Gen1BetterMenus is configured to avoid overlap with the existing specialized mods:** BetterPC is OFF so Advanced Box System remains authoritative; BetterBag is OFF so Modern Bag remains authoritative; BetterParty is ON; BetterBattle is set to MOD so Battle Art Voxel remains the battle renderer.

**Choose Your Avatar** adds Oak's boy/girl question and applies the selected player avatar across the game.

**The Mirage of Mew is the cart's Mew storyline.** Gen151 remains enabled for the all-151 framework, but its own `MEW EVENT` option is pinned OFF so the two Mew systems do not overlap.

The cart includes `quest_system` plus the FAFF0x story quests that depend on it. The build performs a dependency/conflict/overlap audit before packing and refuses to publish if the audit fails.

The cart uses `sealed+`, so the pinned set and load order stay defined while individual pinned mods can still be toggled on or off.

The v1.0.6 cart contains 34 pinned mods.
