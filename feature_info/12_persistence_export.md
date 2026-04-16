---
name: Persistence & Export
description: Local-first autosave (localStorage + IDB), open/save .excalidraw files, PNG/SVG export with font subsetting, embed-scene-in-SVG, File System Access API
type: project
---

# Persistence & Export

## Overview
The app saves to localStorage and IndexedDB automatically every 300ms. Users can open and save `.excalidraw` JSON files using the File System Access API (with in-place overwrite support). Export supports PNG and SVG, with optional dark mode, scale, scene embedding, and HarfBuzz WASM font subsetting for clean SVG output.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| LocalData.ts | `excalidraw-app/data/LocalData.ts` | 73–134 | Debounced autosave to localStorage + IDB |
| SAVE_TO_LOCAL_STORAGE_TIMEOUT | `excalidraw-app/app_constants.ts` | 2 | 300ms debounce |
| LocalFileManager | `excalidraw-app/data/LocalData.ts` | 54–70 | IDB file GC: deletes unused files > 24 hours old |
| LibraryIndexedDBAdapter | `excalidraw-app/data/LocalData.ts` | 229–256 | IDB library persistence |
| filesystem.ts | `packages/excalidraw/data/filesystem.ts` | 13–73 | `fileOpen()`, `fileSave()` wrappers (browser-fs-access) |
| serializeAsJSON | `packages/excalidraw/data/json.ts` | 52–75 | Serializes scene to .excalidraw JSON format |
| exportToCanvas | `packages/excalidraw/scene/export.ts` | 176–280 | Renders elements to HTMLCanvasElement for PNG |
| exportToSvg | `packages/excalidraw/scene/export.ts` | 289–506 | Builds SVGSVGElement, optionally embeds scene |
| encodeSvgBase64Payload | `packages/excalidraw/scene/export.ts` | 508–527 | Compresses + base64-encodes scene into SVG metadata |
| decodeSvgBase64Payload | `packages/excalidraw/scene/export.ts` | 529–561 | Extracts + decompresses scene from SVG metadata |
| ExcalidrawFontFace.toCSS | `packages/excalidraw/fonts/ExcalidrawFontFace.ts` | 37–51 | Calls subsetWoff2GlyphsByCodepoints per font |
| subsetWoff2GlyphsByCodepoints | `packages/excalidraw/subset/subset-main.ts` | 21+ | HarfBuzz WASM subsetting via WorkerPool or main thread |
| harfbuzz-bindings.ts | `packages/excalidraw/subset/harfbuzz/harfbuzz-bindings.ts` | full file | HarfBuzz WASM bindings (browser port of hb-subset) |
| ExportedDataState type | `packages/excalidraw/data/types.ts` | 14–21 | `.excalidraw` file JSON schema |

## How It Works

### Autosave
`LocalData._save` (LocalData.ts:118–134) is a 300ms debounced function. It calls `saveDataStateToLocalStorage()` (lines 73–109), which writes:
- `STORAGE_KEYS.LOCAL_STORAGE_ELEMENTS` → serialized non-deleted elements
- `STORAGE_KEYS.LOCAL_STORAGE_APP_STATE` → cleaned app state subset

Binary files (images) go to IDB via `idb-keyval` in store `"files-db/files-store"`. `LocalFileManager` (lines 54–70) garbage-collects files unused for > 24 hours on next app load. Autosave is paused during collaboration via `LocalData.pauseSave("collaboration")`.

### Open/Save .excalidraw Files
`fileOpen()` (filesystem.ts:13–47) wraps `browser-fs-access.fileOpen()`. `fileSave()` (filesystem.ts:49–73) wraps `browser-fs-access.fileSave()` — if an existing `FileSystemFileHandle` is provided (active file), it overwrites in-place (File System Access API). Serialization: `serializeAsJSON()` (json.ts:52–75) produces the canonical `.excalidraw` JSON.

**File format** (ExportedDataState, types.ts:14–21):
```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [...],
  "appState": { ...cleanedSubset },
  "files": { ...binaryFilesMap }
}
```

### PNG Export
`exportToCanvas()` (export.ts:176–280):
1. Calls `Fonts.loadElementsFonts(elements)` to ensure fonts are loaded
2. Renders elements to an offscreen `HTMLCanvasElement` via `renderStaticScene()`
3. Returns the canvas (caller converts to PNG blob via `canvas.toBlob()`)

### SVG Export
`exportToSvg()` (export.ts:289–506):
1. Builds a fresh `SVGSVGElement` via DOM APIs
2. Calls `renderSceneToSvg()` from `renderer/staticSvgScene`
3. If `exportEmbedScene`: calls `encodeSvgBase64Payload()` and embeds in `<metadata>` between HTML comment markers `<!-- payload-start -->...<!-- payload-end -->`
4. Font inlining (lines 435–447): calls `Fonts.generateFontFaceDeclarations(elements)` → collects all character codepoints → calls `toCSS(characters)` per font face → inlines `@font-face` rules in SVG `<style>` block

### Font Subsetting (HarfBuzz WASM)
`ExcalidrawFontFace.toCSS(characters)` (ExcalidrawFontFace.ts:37–51) collects Unicode codepoints and calls `subsetWoff2GlyphsByCodepoints()` (subset-main.ts:21). This runs HarfBuzz WASM (browser port of `hb-subset`) via `WorkerPool` if available, or falls back to main thread. The result is a minimal woff2 font containing only the glyphs used in the export — dramatically smaller SVG files for large documents.

### Scene Embedding in SVG
When `appState.exportEmbedScene === true`, `encodeSvgBase64Payload()` (export.ts:508): serializes scene JSON → compresses via `encode()` → base64 → inserts between comment markers in `<metadata>`. `decodeSvgBase64Payload()` (export.ts:529): regex-extracts → base64 decode → decompresses. This makes SVG files self-contained — opening the SVG in Excalidraw reconstructs the full editable scene.

## Dependencies
- `browser-fs-access` npm package (File System Access API wrapper)
- `idb-keyval` (IDB file storage)
- `Fonts` class, `WorkerPool` (font subsetting)
- HarfBuzz WASM binary (`harfbuzz-wasm.ts`)
- `appState.exportBackground`, `appState.exportWithDarkMode`, `appState.exportScale`

## Pros
- **Scene embedding in SVG is powerful:** The exported SVG is both a viewable image and a restorable editor state — one file serves both purposes.
- **Font subsetting produces clean SVGs:** Using HarfBuzz WASM ensures SVGs include only the glyphs actually used — exported SVGs are self-contained and display correctly in any SVG viewer without font dependencies.
- **In-place file save:** File System Access API support lets users save to an existing file without a "Save As" dialog every time.
- **300ms autosave is conservative:** Debounce is short enough that very few edits are lost on an unexpected close.
- **File GC prevents IDB bloat:** 24-hour unused file cleanup prevents binary data accumulation in long-running apps.
- **Autosave pauses during collab:** Prevents race conditions between local IDB writes and collaborative sync.

## Cons
- **`browser-fs-access` falls back to download on unsupported browsers:** Safari and Firefox (as of late 2025) have limited File System Access API support — save operations fall back to file downloads, making iterative edits cumbersome.
- **No cloud/remote save in the core library:** Autosave is localStorage/IDB only — cloud sync (Firebase) is only in the hosted `excalidraw-app`, not the embeddable library.
- **Font subsetting runs on WASM, blocking main thread without workers:** If `WorkerPool` is unavailable, HarfBuzz runs synchronously on the main thread, potentially freezing the UI for large documents with many fonts.
- **Exported PNG has no metadata:** PNG export does not embed the scene — only SVG supports scene re-import.
- **`localStorage` size limit:** The 5MB localStorage cap can be hit with large scenes. Elements are split from files (which go to IDB), but large element arrays can still overflow. No graceful degradation — save silently fails.
- **No "save to cloud" from the core library:** The `onExport` async generator hook (unreleased API, see CHANGELOG) is intended to address this but is not yet shipped.

## Notes
- `data/types.ts:31` `@deprecated #6213 TODO remove 23-06-01` — a past-due deprecated type is still present in the codebase (over 2 years past the removal target date).
- `appState.fileHandle` stores the active `FileSystemFileHandle` — it is excluded from serialization but used for in-place save on `Ctrl+S`.
- `VERSIONS.excalidraw = 2` (constants.ts:352) — the file format version has not changed since v2 was introduced; all restore logic handles both v1 (legacy) and v2.
