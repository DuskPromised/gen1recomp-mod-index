# Red Earth — Gate 1 Test Harness

Temporary QA companion for **Red Earth — Gate 1: Irregular Core**.

This mod exists only to expose the three Irregular species quickly on a fresh Gate A save. It is not production story logic.

## Oak Lab test dispensers

Before choosing the real Kaizo starter:

- Bulbasaur ball → Psydren Lv. 15
- Charmander ball → Vesperis Lv. 35
- Squirtle ball → Solipsdion Lv. 50

Each ball first opens the species Dex-entry screen, then gives the test Pokémon. The harness does **not** set `EVENT_GOT_STARTER`.

Until all three QA gifts have been collected, touching an already-used test ball will only show a reminder instead of falling through to Kaizo. After all three are collected, the three balls revert to normal Kaizo behavior and the real starter can be chosen.

## Why Lv. 15 / Lv. 35?

Psydren evolves at Lv. 16 and Vesperis at Lv. 36, so one level-up tests each evolution boundary without debug-level grinding.

## Test checklist

For each species check battle front/back scale and grounding, Party icon, Summary/Dex portrait, moves/types/stats, then save → close → reopen.

For Psydren and Vesperis, gain one level and verify the correct evolution and post-evolution art/data.

This harness contains no shiny logic, Wilds/follower integration, Stone mechanics, passives, Melony, Ansem, or production starter story.
