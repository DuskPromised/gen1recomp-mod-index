# Red Earth Dramaless Battle Bridge

A narrow compatibility patch for **DRAMALESS_SHAPE 2.0.x** used by the Red Earth split stack.

Dramaless deliberately captures its native 2D world cards at 1x. Red Earth's starter pipeline uses real player **back** sprites, which Gen1Recomp normally renders at 2x and grounds at the battle baseline. This bridge restores the engine's normal back-sprite scale resolver only while Dramaless captures the Red Earth starter families.

It does **not** replace Dramaless, change the voxel camera, change enemy scaling, own shiny art, or merge Red Earth's custom mods.
