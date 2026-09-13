# Pokémon Red Earth

A curated Pokémon Red cart combining voxel battles, all 151 obtainable in one save, a boy/girl avatar choice, **The Mirage of Mew**, refined widescreen menus, shiny Pokémon, quality-of-life upgrades, Kanto achievements, and the FAFF0x quest/story layer.

**Red Earth v1.0.9 keeps Gen1 Modern UI and Modern UI Fix removed because they caused misaligned touch/options input on iOS. **Wilds of Kanto is restored** as the cart's only overworld wild/follower system; the separate `overworld_encounters` mod remains excluded to avoid overlap.

**Gen1BetterMenus is configured to avoid overlap with the existing specialized mods:** BetterPC is OFF so Advanced Box System remains authoritative; BetterBag is OFF so Modern Bag remains authoritative; BetterParty is ON; BetterBattle is set to MOD so Battle Art Voxel remains the battle renderer.

**Choose Your Avatar** adds Oak's boy/girl question and applies the selected player avatar across the game.

**Wilds of Kanto v2.1.9** provides visible overworld Pokémon and the built-in party follower system. No separate Followers EX/PokéPC install is pinned, and the older overlapping `overworld_encounters` mod is intentionally excluded.

**The Mirage of Mew is the cart's Mew storyline.** Gen151 remains enabled for the all-151 framework, but its own `MEW EVENT` option is pinned OFF so the two Mew systems do not overlap.

**Multiple Save Slots v1.0.1** is the cart-aware compatibility build. It uses Red Earth's own `cartSlots` registry and `saves/cart_red_earth/` scope when the cart is active, while retaining normal Red/Blue/Yellow slot behavior outside a cart.

**Shiny Gifts & Starters v1.2.0** is pinned with `SHINY STARTERS` ON and `SHINY ALL GIFTS` OFF. It loads before `SHINY_POKEMON`, so your starter is guaranteed shiny while the separate shiny mod can use a custom wild rate such as 1/100.

The cart includes `quest_system` plus the FAFF0x story quests that depend on it. The build performs a dependency/conflict/overlap audit before packing and refuses to publish if the audit fails.

The cart uses `sealed+`, so the pinned set and load order stay defined while individual pinned mods can still be toggled on or off.

The v1.0.9 cart contains 36 pinned mods.
