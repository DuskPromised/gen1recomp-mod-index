# Gate 2.5 — Regional Starter Menu/Icon Repair Plan

Baseline: accepted Gate 2.4 cart. Do not alter Gate 2.4 behavior.

## Scope
Fix only the known regional-starter menu/icon presentation issue. This is a narrow back-port, not a wholesale import of the later `red_earth_regional_shiny_art` stack.

## Preserve unchanged
- Psydren/Vesperis/Solipsdion shiny state and authored battle/menu art
- Solipsdion 54-pixel back repair
- gold/lilac shiny send-out sparkle
- shiny sound and centering
- sprite scale/grounding
- starter routing and region selector behavior
- evolution persistence, box/save/reload persistence, Rare Candy evolution testing
- normal-control behavior
- no natures/passives in this gate

## Candidate implementation
Create a standalone `red_earth_gate2_regional_menu_icon_fix` module that only intercepts menu/summary/box/icon presentation for the selected regional starter when its shiny state is genuine.

Use the later `red_earth_regional_shiny_art` work only as a reference for proven species IDs and icon/menu asset handling; do not import its battle-sprite, follower, global sprite-provider, or palette-transfer hooks into Gate 2.

Regional grass starter lines to support from the locked selector:
- Bulbasaur line: 001–003
- Chikorita line: 152–154
- Treecko line: 252–254
- Turtwig line: 387–389
- Snivy line: 495–497
- Chespin line: 650–652
- Rowlet line: 722–724
- Grookey line: 810–812 (verify current AllGen/engine species IDs before shipping)
- Sprigatito line: 906–908 (verify current AllGen/engine species IDs before shipping)

Also verify Fennekin line menu/icon behavior separately: 653–655.

## Gate 2.5 acceptance criteria
1. Selected regional starter shows its shiny menu/icon art immediately after acquisition.
2. Summary, party, box, and icon views agree with genuine shiny state.
3. Evolution keeps the correct shiny menu/icon art across the full line.
4. Normal-control individuals remain normal.
5. No changes to battle sprites, followers, scale, sparkle position/color, or acquisition logic.
6. Reorder -> box/withdraw -> save -> fully close -> reopen preserves presentation.
7. Gate 2.4 package hashes remain unchanged; the new module is additive and standalone.

Do not publish Gate 2.5 until Gate 2.4 device test confirms the Solipsdion pixel repair and gold/lilac sparkle are both green.
