# Red Earth — Gate 2 Gold-Lilac Shiny Sparkle v0.2.4

This is a narrow presentation-only extension of the accepted Gate 2.3 cart.

## Changes
- player send-out sparkle becomes warm yellow/gold
- a small deterministic subset of sparkle pixels uses lilac as an accent
- Crystal's existing sparkle timing, placement, sound, and delayed cry remain authoritative
- the colored overlay is drawn at the exact battler coordinates and effective scale used by Gate 2.0 presentation

## Does not change
- shiny DVs or `mon.shiny`
- authored normal/shiny Pokemon art
- Solipsdion's 54-pixel repair
- sprite scale or grounding
- evolution or persistence
- starter logic
- natures or passives
- sparkle audio

## Test target
Use the Gate 2.4 cart and verify Psydren, Vesperis, and Solipsdion shiny player send-outs. The black sparkle should be fully covered by the gold/lilac overlay and remain centered on the Pokemon.
