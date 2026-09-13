# Gen 1 Recomp Community Mod Index

A comprehensive GenRecomp-compatible index focused on **Pokémon Red / Blue / Yellow**, combining the wider Gen1Recomp community catalog with the complete FAFF0x Gen 1 collection and its verified dependencies.

## Sources and precedence

1. **FAFF0x collection** — every ZIP currently published in `FAFF0x/gen1recomp` is downloaded by the sync job and its own `manifest.json` is parsed directly.
2. **Community catalog** — Gen 1-compatible listings from `bryanthaboi/gen1recomp-mod-index` are imported with their release metadata and author-hosted install URLs preserved.
3. **Required / optional external integrations** — dependencies referenced by FAFF0x manifests are included when needed.

If the same mod ID appears in more than one source, the directly verified FAFF0x entry wins. Entries explicitly marked Gen-2-only are excluded from this Gen 1 feed.

## What is preserved

- Exact mod IDs and versions
- Author and source repository
- `downloadURL` or `latest.zip.url`
- Required dependencies
- Manifest-optional dependencies
- Documented optional integrations
- Conflicts
- Engine/API metadata, permissions, tags and target games when supplied
- Alternate FAFF0x builds, such as the Android Performance Monitor package

The repository contains **no ROMs and no mirrored mod ZIP binaries**. Installs always use the authors' existing downloads.

## Automatic updates

A scheduled GitHub Action runs daily. It:

- re-reads the FAFF0x source ZIPs and manifests;
- refreshes the wider community catalog;
- deduplicates by mod ID;
- excludes entries explicitly targeted only at Gen 2;
- validates install URLs / release URLs;
- commits the combined feed only when it changes;
- redeploys GitHub Pages; and
- verifies the public `data/index.json` after deployment.

## Import

Recommended Recomp source:

`DuskPromised/gen1recomp-mod-index`

Direct feed:

`https://duskpromised.github.io/gen1recomp-mod-index/data/index.json`

Readable catalog:

`https://duskpromised.github.io/gen1recomp-mod-index/`

Primary upstreams:

- https://github.com/FAFF0x/gen1recomp
- https://github.com/bryanthaboi/gen1recomp-mod-index
