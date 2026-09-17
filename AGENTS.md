# Red Earth release rule — user instruction

Before delivering any mod or cart, double-check the packaged result against
the intended player-facing behavior. Hashes, valid pins and direct calls to
module entrypoints alone do not establish that the game works.

For Gate 2, verify native Loader dependency resolution and sandboxed module
entrypoints, actual script gift execution, genuine shiny DVs and normal
controls, selected front/back/menu/icon paths, evolution and persistence.
Record what was actually exercised and any device-only checks still pending.

Keep accepted gate/module ZIPs immutable and individually downloadable.
Compatibility and asset repairs remain separate. For the current recovery,
restore the exact accepted Gate 2 v0.2.0 modules; add only the 54-pixel shiny
Solipsdion back repair. Preserve all existing opaque pixels and original
texture; do not use redesigned/generated artwork.

Do not claim publication until build, dependency checks, sealed online pins,
merge, Pages deployment and public byte verification have all passed.
