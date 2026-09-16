# Red Earth Voxel Profile NEXT

Development-only Gate 0 compatibility shim for PotatoVoxel.

It restores a PotatoVoxel named quality preset after boot/load only when the
pipeline level says HIGH/MEDIUM/LOW/POTATO but one of that preset's component
settings no longer matches.

It intentionally does **not**:
- force HIGH
- change OFF or CUSTOM
- touch ATMOS
- touch WEATHER
- touch DAY/NIGHT
- touch BACK SPRITES
- replace PotatoVoxel rendering

This keeps Red Earth compatible with lower-performance devices while ensuring a
named PotatoVoxel preset is internally consistent when selected.
