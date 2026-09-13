# Multiple Save Slots — Cart-Aware Patch

This is a compatibility-patched build of **Multiple Save Slots** by **masterwebx**, based on upstream v1.0.0.

## What the patch changes

GenRecomp stores custom-cart playthroughs separately from ordinary Red/Blue/Yellow saves. Upstream v1.0.0 always addressed the base-game slot registry, so inside a custom cart its slot picker could point at the wrong save scope.

v1.0.1 routes slot listing, creation, activation, deletion, disk reconciliation, and registry preservation through GenRecomp's cart-slot APIs whenever a cart is active. Outside a cart it retains the original base-game behavior.

The original user-facing behavior is unchanged:

- Title **CONTINUE** opens the slot list.
- In-game **SAVE** opens the slot list.
- **NEW SAVE** creates and immediately writes a slot.
- **MANAGE** deletes slots.

Upstream project: https://github.com/masterwebx/gen1recomp-multi-save-slots

## License

MIT. Original copyright and license are preserved in `LICENSE`.
