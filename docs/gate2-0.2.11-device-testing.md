# Gate 2.11 — device testing only

Gate 2 remains **PARTIAL GREEN / DEVICE TESTING PENDING**. This prerelease is not device acceptance.

Two reviewed module ZIPs are uploaded byte-for-byte, without rebuilding. All 12 baseline package pins and all 14 load-order entries are preserved from the reviewed local cart. Only the two new module records change from local to GitHub source, with repository and exact SHA256 pins. No gameplay source, authored asset, Potato setting, protected module or baseline ZIP is edited.

The cart's original local-candidate summary text is intentionally retained to keep the cart change limited to those two source records. The published source records now support automatic GitHub resolution.

19 headless native-component regression tests passed during implementation. Device visuals/audio, import, save/full-close/reopen, evolution and protected custom-line checks remain pending. The development source/test bundle is not published as an installable module.

## Immutable published bytes

- `red_earth_gate2_fennekin_recovery-0.2.11.zip` — SHA256 `72a25cdc016b8e798569efcaa3a1e24f055aa3bb3f86f943b53726b1903afd4b`
- `red_earth_gate2_fennekin_fx-0.2.11.zip` — SHA256 `7073593224d51a128853186651cf9824dd660ffd8c962a36eeddb16c02e600c6`
- `gate_2_irregular_shiny_test-0.2.11.g1rcart` — SHA256 `6c2d94de67a142406c5ee0cc00f48a8dd6f744093086712380471c6aa5970d85`

## Installation

Use this repository's existing feed and the published 0.2.11 cart. The two new module records resolve v0.2.11 release assets; starter 0.2.6 remains pinned. Do not substitute failed starter 0.2.10.

Feed: https://duskpromised.github.io/gen1recomp-mod-index/data/index.json

Stop after device testing and report explicit acceptance/failures. Do not declare Gate 2 GREEN from publication or CI success.
