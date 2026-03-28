# Asset Source Map And Extraction Rules

## Purpose

This document defines the canonical source map for Tyrian gameplay assets and the extraction rule that applies to each source family.

The goal is to minimize assumptions. Extraction should be driven by the original data format used by the game, not by a guessed universal atlas layout.

## Core Decision

Tyrian does not use one universal sprite format.

The project must distinguish at least these source classes:

- `Sprite`: variable-size sprite records with explicit width and height
- `Sprite2`: compressed index-addressed sprite records with a fixed logical row width of `12` pixels and row advance of `14`
- tile-set graphics in `shapes*.dat`
- level routing/script data in `levels?.dat`
- level tilemap/event data in `tyrian?.lvl`
- palette-backed fullscreen art in `tyrian.pic` plus `palette.dat`

Canonical consequence:

- fixed-grid extraction is valid only for `Sprite2` families
- fixed-grid extraction is invalid for `Sprite` families

## Canonical Source Map

### `tyrian.shp`

Primary gameplay sprite archive for player-facing assets.

OpenTyrian splits this file into:

- sections `1..7`: variable-size `Sprite` tables
- section `8`: `Sprite2` player shots
- section `9`: `Sprite2` player ships
- section `10`: `Sprite2` powerups
- section `11`: `Sprite2` coins, datacubes, and misc pickups
- section `12`: `Sprite2` more player shots

Rules:

- sections `1..7` must be decoded with the variable-size sprite path
- sections `8..12` may be decoded with the current `Sprite2` extractor path
- ship extraction is a composition rule on top of section `9`, not a direct single-cell dump

### `newsh*.shp`

Enemy sprite banks.

Rules:

- treat as `Sprite2` banks loaded by `JE_loadCompShapes`
- do not treat them as `Sprite`
- do not assume they map cleanly to one gameplay family without consulting enemy definitions and shape-bank metadata

### `shapes*.dat`

Level tileset graphics.

Rules:

- keep separate from sprite extraction
- these need a dedicated tile extractor
- do not try to decode them with `Sprite` or `Sprite2` logic

### `tyrian?.lvl`

Level tilemaps and level-local event/script payloads.

Rules:

- not a direct art source
- use to map visual assets back to actual level usage
- useful for provenance and atlas tagging, not raw sprite rasterization

### `levels?.dat`

Episode routing and between-level flow.

Rules:

- not a direct art source
- use for content provenance, shop flow, datacube flow, and campaign structure

### `tyrian.hdt`

Structured gameplay data.

Rules:

- use to map graphics to gameplay identities
- especially important for:
  - ships
  - weapons
  - generators
  - shields
  - sidekicks
  - enemies

### `palette.dat` + `tyrian.pic`

Palette-backed fullscreen interface art.

Rules:

- palette application is mandatory
- extraction must record palette index in metadata

## Metadata Requirements

Every extracted family should emit enough metadata to reconstruct provenance and atlas placement without re-reading game code.

Minimum metadata:

- source file path
- source format class
- section or bank identifier where relevant
- source file offset or source record index
- source dimensions or source cell dimensions
- trimmed bounds
- atlas frame
- logical identity when known
- composition rule when the output is assembled from multiple source records

Family-specific additions:

- ships:
  - `shipGraphicIndex`
  - bank offset
  - component cell indices
- enemies:
  - shape bank id
  - enemy definition linkage when known
- tiles:
  - tile id
  - tile bank
  - usage linkage to levels when available

## Extraction Order

The low-assumption extraction order should be:

1. build and refresh the source manifest
2. extract source families according to their actual format class
3. generate full reference datasets under `references/tyrian21-extracted`
4. validate with contact sheets and metadata inspection
5. only then curate smaller runtime atlases

## Canonical Outputs

### Source Manifest

The project should maintain a generated source manifest at:

- `references/tyrian21-extracted/source-manifest.json`

This manifest should describe:

- which original files exist
- what format each family uses
- which extraction rule applies
- where fixed-grid extraction is valid or invalid

### Family Outputs

Each extractor should create:

- raw source output when practical
- trimmed output
- one or more atlases
- inspection contact sheets
- metadata sufficient for deterministic reuse

## Current Implementation Direction

The current extraction system should evolve toward:

- one manifest-driven inventory of source families
- one shared extraction core for common binary helpers
- one extractor script per family or source format
- no silent assumptions about universal cell sizes

The canonical reference for this policy is the generated source manifest plus this document.
