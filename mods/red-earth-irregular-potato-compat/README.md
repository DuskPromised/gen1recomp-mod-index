# Irregular / PotatoVoxel compatibility v0.1.3

Standalone optional compatibility patch, required by the Gate 1.3 QA cart.
Install after Irregular Core 0.1.2 and the exact PotatoVoxel 1.9.6 release.
Core and test harness remain individually downloadable at 0.1.2.

## Why a patch, rather than new PNGs

The existing Psydren and Solipsdion back PNGs have transparent leg gaps.
PotatoVoxel 1.9.6 `lib/BattlePics.lua` reconstructs white areas in keyed Gen 1
art. In pinned-back mode it seals the bottom of the figure and fills these
intentional gaps. Removing more alpha from the files would not fix that rule.

The same release's `OverworldBattle.install` rounds pinned battle scales to
integers, so the core's 0.94, 1.00 and 1.05 back scales all become 1.

## Narrow behavior

Only an Irregular player's authored back picture, in a staged battle with
BACK SPRITES enabled, bypasses paper reconstruction. Engine palette effects
still run. White portions of the actual art, including Psydren's tail, remain.
No assets or upstream files are changed.

The core keeps the historical scales. This patch applies explicit framing
factors in the pinned view so the later stages read larger:

| Species | Core back scale | Framing factor | Effective back scale |
| --- | ---: | ---: | ---: |
| Psydren | 0.94 | 1.00 | 0.94 |
| Vesperis | 1.00 | 1.18 | 1.18 |
| Solipsdion | 1.05 | 1.30 | 1.365 |

The engine's back placement still grounds the image on the text box. The
48-pixel canvases remain below 66 rendered logical pixels high. Front scales,
billboards, trainers, unrelated species and non-staged battles are untouched.

The patch attaches methods to each battle instance. During a target draw only,
it temporarily delegates the specific scale request and suppresses that
picture's fill call; both upstream functions are restored on success or error.
There is no permanently replaced global renderer or scale resolver.

## Save compatibility and scope

This patch never touches save data or species IDs. Gate 1.2 had already switched
to PSYDREN/VESPERIS/SOLIPSDION; this revision preserves those IDs. It does not
claim to migrate older 0.1.3/0.1.1 IRR_ saves, which remains a logged issue.
No later-gate systems or regional starter art are included.

## Retest

Compare the three back sizes, inspect Psydren/Solipsdion leg gaps, confirm clean
nickname prompts, then save, fully close and reopen. Gate 1 remains unsealed
until the live-device retest passes.
