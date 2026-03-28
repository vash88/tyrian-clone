# Asset Acquisition And Pipeline

## Purpose

This document is the canonical source for how TyrianClone acquires, extracts, names, stores, and consumes gameplay art derived from the original game data.

It exists to prevent ad hoc asset handling. The project should have one repeatable path from original reference data to runtime-ready resources.

See also:

- `docs/specs/tyrian-core/11-asset-source-map-and-extraction-rules.md`
- `references/tyrian21-extracted/source-manifest.json`

## Scope

This document covers gameplay-relevant visual assets only:

- player ships
- pickups
- projectiles
- sidekicks
- enemies
- bosses
- hazards
- UI-adjacent gameplay overlays when sourced from original data

This document does not cover:

- platform app icons or marketing art
- settings, storefront, or website assets
- audio extraction
- networked content delivery

## Canonical Source Hierarchy

When the same asset appears in multiple reference sets, use this priority order:

1. Original game data from `references/tyrian21`
2. OpenTyrian decoding logic and documentation from `references/opentyrian-master`
3. Remastered or third-party packs only as visual comparison material

Canonical source files currently in use:

- `references/tyrian21/tyrian.shp`
- `references/tyrian21/tyrianc.shp`
- `references/tyrian21/palette.dat`
- `references/opentyrian-master/src/sprite.c`
- `references/opentyrian-master/src/varz.c`
- `references/opentyrian-master/doc/files.txt`
- `references/opentyrian-master/doc/tyrian.hdt.txt`

Before building a new extractor, confirm the source format in:

- `docs/specs/tyrian-core/11-asset-source-map-and-extraction-rules.md`
- `references/tyrian21-extracted/source-manifest.json`

## Core Rules

### Original Data First

If an asset exists in original game data, extract from the original data instead of redrawing or manually cropping a third-party pack.

### OpenTyrian Is The Decode Authority

When the original data format is opaque, OpenTyrian source is the decoding authority for sheet layout, sprite indexing, palette use, and composition rules.

### Repeatable Extraction Only

Do not create runtime assets by hand-editing arbitrary screenshots or one-off crops. Runtime resources should be produced by scripts or by a documented deterministic process.

Canonical rule:

- asset-family scripts may exist, but they must be built on shared extraction primitives rather than duplicating SHP decode logic independently
- the preferred operator entrypoint is `scripts/extract_tyrian_assets.py`

### Metadata Must Travel With Art

Every extracted atlas or sprite family must ship with machine-readable metadata that explains what the runtime is consuming.

At minimum, metadata should capture:

- source file
- source sheet or section
- palette used
- sprite index or index family
- frame dimensions
- logical name or presentation reference
- bounds or anchor-related data when applicable

### Runtime Uses Bundled Folders, Not Asset Catalogs, For Extracted Sets

For extracted Tyrian gameplay art, prefer bundling folders in the app target over hand-importing each file into `.xcassets`.

Reasons:

- preserves script-generated file names
- keeps metadata adjacent to art
- supports bulk refreshes from extraction scripts
- avoids manual Xcode catalog maintenance

Asset catalogs remain acceptable for platform-native assets that are not part of the Tyrian extraction pipeline.

## Canonical Output Layout

### Reference Extraction Output

Script-generated research output belongs under `references/tyrian21-extracted`.

Current examples:

- `references/tyrian21-extracted/source-manifest.json`
- `references/tyrian21-extracted/item-data`
- `references/tyrian21-extracted/level-usage`
- `references/tyrian21-extracted/level-enemy-usage`
- `references/tyrian21-extracted/spriteSheet9`
- `references/tyrian21-extracted/pickups`
- `references/tyrian21-extracted/tyrian-shp-sprites`
- `references/tyrian21-extracted/enemy-banks`
- `references/tyrian21-extracted/enemy-definitions`
- `references/tyrian21-extracted/tilesets`
- `references/tyrian21-extracted/projectiles`
- `references/tyrian21-extracted/sidekicks`

These directories may contain:

- raw extracted cells
- contact sheets
- exploratory composites
- metadata used for validation

This layer is for inspection and reproducibility, not direct runtime use.

### Canonical Extraction Workflow

Use this workflow for all gameplay sprite extraction work:

1. add or update the asset-family extraction logic in a dedicated script under `scripts/`
2. keep shared SHP, palette, offset, cell, bounds, atlas, and contact-sheet helpers in `scripts/tyrian_extract_core.py`
3. expose the family through `scripts/extract_tyrian_assets.py`
4. write inspection output under `references/tyrian21-extracted/<family>`
5. copy or curate only runtime-needed output into `TyrianClone/TyrianClone/TyrianAssets/<Family>`

Current canonical command:

```bash
python3 scripts/extract_tyrian_assets.py all
```

Family-scoped commands:

```bash
python3 scripts/extract_tyrian_assets.py manifest
python3 scripts/extract_tyrian_assets.py items
python3 scripts/extract_tyrian_assets.py levels
python3 scripts/extract_tyrian_assets.py level-enemies
python3 scripts/extract_tyrian_assets.py ships
python3 scripts/extract_tyrian_assets.py pickups
python3 scripts/extract_tyrian_assets.py ui
python3 scripts/extract_tyrian_assets.py enemies
python3 scripts/extract_tyrian_assets.py enemy-definitions
python3 scripts/extract_tyrian_assets.py tiles
python3 scripts/extract_tyrian_assets.py projectiles
python3 scripts/extract_tyrian_assets.py sidekicks
```

### App Runtime Output

Runtime-ready bundled resources belong under the app target.

Current canonical runtime folders:

- `TyrianClone/TyrianClone/TyrianAssets/Ships`
- `TyrianClone/TyrianClone/TyrianAssets/Pickups`

Rules for runtime folders:

- contain only the subset the app should actually load
- keep metadata file names unique across flattened bundle layouts
- avoid dumping exploratory assets into the runtime set

## Ship Pipeline

### Source

Player ship art comes from `tyrian.shp` using the same composition logic as `blit_sprite2x2` in OpenTyrian.

### Composition Rule

A valid 2x2 ship frame is composed from:

- `index`
- `index + 1`
- `index + 19`
- `index + 20`

at tile positions:

- `(0, 0)`
- `(12, 0)`
- `(0, 14)`
- `(12, 14)`

### Valid Frame Policy

Do not treat every possible 2x2 starting index as a canonical ship frame.

Only bank families that map to actual ship graphics should be bundled for runtime use. Exploratory composite sweeps may exist in the reference output, but they are not runtime assets.

### Current Script

- `scripts/extract_tyrian_sprite_sheet9.py`
- shared decode helpers in `scripts/tyrian_extract_core.py`

### Current Runtime Bundle

- `TyrianClone/TyrianClone/TyrianAssets/Ships`

Runtime ship resources should be shipped as:

- one atlas image
- one metadata file with frame rects and bank-frame mapping

Do not bundle one standalone PNG per ship bank frame for runtime use unless the atlas path is temporarily broken during migration.

## Pickup Pipeline

### Source

Pickup art is extracted from the original shape data and palette-applied into a full reference dataset for sections `10` and `11`.

### Current Script

- `scripts/extract_tyrian_pickup_atlas.py`
- shared decode helpers in `scripts/tyrian_extract_core.py`

### Canonical Reference Output

The pickup extractor should emit all source sprites, not only the small gameplay subset currently wired into the app.

Canonical reference output now includes:

- `references/tyrian21-extracted/pickups/raw/section-10`
- `references/tyrian21-extracted/pickups/raw/section-11`
- `references/tyrian21-extracted/pickups/trimmed/section-10`
- `references/tyrian21-extracted/pickups/trimmed/section-11`
- `references/tyrian21-extracted/pickups/atlases/section-10-atlas.png`
- `references/tyrian21-extracted/pickups/atlases/section-11-atlas.png`
- `references/tyrian21-extracted/pickups/atlases/all-pickups-atlas.png`
- `references/tyrian21-extracted/pickups/atlases/aliases-atlas.png`
- `references/tyrian21-extracted/pickups/metadata.json`
- `references/tyrian21-extracted/pickups/pickup-metadata.json`

Reference output responsibilities:

- keep raw `12x14` source cells for verification
- keep trimmed sprites for clean inspection and later repacking
- keep section-local atlases for source-family review
- keep one combined atlas for the full extracted pickup set
- keep a separate alias atlas and metadata file for the smaller gameplay-facing subset

### Current Runtime Bundle

- `TyrianClone/TyrianClone/TyrianAssets/Pickups`

### Current Metadata Contract

Pickup runtime metadata should define:

- atlas image path
- logical sprite name
- source section and index
- atlas pixel rect
- source bounds and trimmed size when present

The full reference metadata should additionally define:

- per-section atlas frame
- combined atlas frame
- raw source cell size
- source file offset

## Future Asset Families

The next families should follow the same pattern:

1. projectiles with gameplay-facing semantic labels
2. sidekicks and option animations
3. boss-specific grouped families derived from enemy banks plus data definitions
4. hazard tiles or animated hazard elements
5. palette-context-aware tileset previews

For each new family:

1. identify the original source file and decode path
2. build an extraction script
3. write reference output under `references/tyrian21-extracted`
4. curate runtime-ready output under the app target
5. define metadata consumed by the renderer

## Runtime Integration Rules

### Presentation References

Gameplay data should refer to extracted art through stable logical identifiers such as `presentationRef`, not through hard-coded bundle file names scattered across simulation code.

### Renderer Ownership

The renderer owns the mapping from logical presentation identifiers to textures, atlas rects, and draw dimensions.

### Keep Simulation Art-Agnostic

Simulation and authored gameplay data may name a presentation id, but they should not contain bundle paths, texture loading logic, or platform image types.

## Validation Checklist

Before a new extracted asset family is considered canonical:

- extraction is reproducible from a checked-in script
- original data source is documented
- OpenTyrian decode assumptions are cited when used
- runtime bundle excludes exploratory junk frames
- metadata exists and is machine-readable
- the renderer can fall back safely when metadata is missing
- contact-sheet or debug output exists for visual inspection

## Current Canonical Status

- source manifest: canonical and generated
- item data: canonical episode-1 baseline parse from `tyrian.hdt`
- level usage: canonical `.lvl` header and event provenance extraction in place
- ships: canonical and runtime-backed from original extracted art
- pickups: canonical first pass and runtime-backed from original extracted art
- tyrian.shp variable-size sprite tables: canonical reference extraction in place
- enemy banks: canonical reference extraction in place
- enemy definitions: canonical gameplay-linked frame grouping in place
- tilesets: canonical reference extraction in place with indexed previews plus palette variants
- projectiles: canonical reference extraction in place with weapon-linked semantic metadata
- sidekicks: canonical reference extraction in place with option-linked semantic metadata
- bosses: pending higher-level grouping on top of enemy definitions

## Implementation Notes

- Prefer unique metadata file names in runtime bundles because the current Xcode folder-sync flow may flatten copied resources at bundle build time.
- Prefer keeping extracted original art in normal bundled folders rather than `.xcassets` unless there is a specific platform feature that requires the asset catalog.
- When art appears visually offset, verify composition rules and runtime coordinate semantics separately. Do not assume the extraction is wrong without checking the original draw logic first.
