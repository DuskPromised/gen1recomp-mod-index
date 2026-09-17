# Red Earth modular acceptance record

## Gate 1 — PASSED (recorded 2026-09-17)

The user confirmed all four Gate 1.3 live-device retests passed: relative
battle proportions, transparent leg gaps, clean nickname prompts, and
save → full close → reopen. The user specifically confirmed the later stages
are substantially larger and the white patches between the legs are gone.

Frozen accepted stack: Gate 0A + Irregular Core 0.1.2 + QA Harness 0.1.2 +
Irregular/Potato Compatibility 0.1.3. The harness's Lv15/Lv35/Lv50 gifts were
intentional test levels, not production starter levels.

Accepted cart SHA256:
`c02e65b22113d821b189157d45794b8efcfc76cb4eefda9b7287bdd74b96a707`

## Gate 2 — FUNCTIONAL PATHS PASSED; SHINY BACK ART RETEST PENDING

Three separately downloadable modules: Irregular Shiny, Gate 2 QA Harness,
and Gate 2 Presentation Compatibility. The new cart retains the accepted
normal core and Gate 1 compatibility pins. Only the QA harness is replaced.

Left ball: shiny Psydren Lv15; talk to it again for normal Psydren Lv15.
Center: shiny Vesperis Lv35. Right: shiny Solipsdion Lv50. Fifty Rare Candies
are provided once for evolution tests. After all four gifts, Kaizo's starter
choice resumes normally. Use a new Gate 2 QA save; the separate cart does not
overwrite the Gate 1 save.

Retest authored shiny fronts/backs, summary/party/icons, standard player
sparkle/SFX, the preserved sizes/alpha, evolution, reorder/box/save reload,
and normal-art controls. Species-only Dex previews remain the normal species
portrait; an individual-aware view can display its shiny portrait.

Follower effects, regional starters, characters, passives and Stone systems
remain later gates. All modules and compatibility layers remain separate
until final production consolidation. Gate 1.2's pre-existing ID change is
not reversed here; migration of older IRR_ saves remains unimplemented.

### Device report and narrow 0.2.1 revision

The user confirmed normal Psydren stays normal through both evolutions; shiny
Psydren and shiny Vesperis stay shiny through Solipsdion. Rare Candies, native
evolution and level-up move prompts work. This report does not independently
confirm the full save/reorder/box checklist. The regional starter menu icon
remains a later-gate issue.

Shiny Solipsdion battle-back holes reproduce in the PNG itself. The supplied
master has transparent pearl-colored body pixels with retained original RGB;
a white menu background conceals the holes. Version 0.2.1 changes only the
shiny module and Gate 2 cart, restoring 54 body pixels from the master. All
existing opaque pixels, other eleven shiny images, normal core, sizing/alpha
compatibility modules and QA harness remain unchanged. Gate 2 is still open
until the corrected back sprite and remaining persistence checks pass.

### Gate 2.1 packaging regression — corrected in cart 0.2.2

The user reported the QA gifts were absent and the balls went straight to
Kaizo region selection. Both unchanged 0.2.0 support manifests required shiny
0.2.0 exactly, while cart 0.2.1 pinned shiny 0.2.1. Native Loader blocks both
modules for that mismatch. Previous tests invoked module code directly and
cartkit validated pins without checking this manifest compatibility.

Harness and Presentation now have separate 0.2.2 packages requiring shiny
0.2.1. The shiny ZIP and all artwork remain byte-identical. Native Loader
dependency enforcement now reproduces both prior failures and requires all
current Red Earth modules to survive dependency resolution before publishing.
Gate 2.1 must not be used for testing; use cart 0.2.2.

### Recovery 0.2.3 — exact 0.2.0 stack plus standalone pixel repair

The user reported normal art on a fresh start in 0.2.2 and instructed us to
restore 0.2.0, then re-add only the missing pixels. The shiny state module,
harness and presentation module are restored from their exact immutable
0.2.0 ZIPs. Every original 0.2.0 cart pin remains identical. A separate
`red_earth_solipsdion_shiny_back_fix` changes only the exported shiny
Solipsdion back path to the 54-pixel repaired asset. The original module
files, state, acquisition logic, normal art and other shiny art are unchanged.

The strengthened test loads packaged Red Earth modules through native Loader
and its sandbox, then runs native ScriptRunner/Commands with nickname-dialogue
yield/resume, Pokemon.new, DVs, sprite/icon selection, evolution, PC deposit,
party reorder and serializer reload. Headless dialogue rendering and upstream
module bodies are test stand-ins; accepted upstream version records are used
for dependency checks. This is not an iOS full-game run. Separate composition
tests cover the existing Potato scale/alpha and sparkle paths with the repaired
back reference. Physical-device acceptance remains pending.

Standing user release verification rule is recorded in AGENTS.md.
