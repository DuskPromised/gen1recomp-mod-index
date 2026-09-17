# Gate 2 Presentation Compatibility 0.2.0

Separate companion to Irregular Shiny, the accepted Gate 1.3 Potato patch,
PotatoVoxel 1.9.6 and Crystal Animated Sprites 2.0.3. No upstream file edits.

The Gate 1 patch already preserves authored alpha for the player's sprite.
This layer extends the accepted framing to the exact Gate 2 shiny back paths:
Psydren 0.94, Vesperis 1.18, Solipsdion 1.365. It delegates normal paths to
the accepted patch and all unrelated species to their existing renderer.
The temporary resolver is restored on success or error, per battle draw.

Crystal's Gen 1 reveal targets the opponent. For a shiny Irregular player's
entrance this module uses the installed Crystal mod's standard sparkle sheet,
frame timings and MP3. It locates the effect from the actual drawBattlerPic
coordinates, image dimensions and scale. The cry follows the sparkle sound.
Instances are keyed by the entering mon, and battle exit stops pending audio.
Effects use wall time, so they do not speed up with gameplay logic.

No world/follower effect, generic shiny recoloring or production acquisition
is installed. This patch attaches instance methods, with no permanent global
sprite/scaling wrapper. Device retesting is still required before Gate 2 passes.
