---
name: Shape Libraries
description: Sidebar library of reusable shape collections, add-to-library, URL token import, browse portal, .excalidrawlib format
type: project
---

# Shape Libraries

## Overview
The library sidebar lets users store, organize, and reuse groups of elements as "library items." Items can be added from the current selection, imported via URL tokens (deep links), or browsed from the community portal at libraries.excalidraw.com. Library data persists in IndexedDB.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| LibraryMenu.tsx | `packages/excalidraw/components/LibraryMenu.tsx` | 60–130 | Sidebar wrapper, `isLibraryMenuOpenAtom`, addToLibrary callback |
| LibraryMenuItems.tsx | `packages/excalidraw/components/LibraryMenuItems.tsx` | full file | Library item grid rendering |
| LibraryMenuHeaderContent.tsx | `packages/excalidraw/components/LibraryMenuHeaderContent.tsx` | full file | Search/filter header |
| LibraryMenuControlButtons.tsx | `packages/excalidraw/components/LibraryMenuControlButtons.tsx` | full file | Import/export/clear buttons |
| LibraryUnit.tsx | `packages/excalidraw/components/LibraryUnit.tsx` | full file | Individual library item tile |
| LibraryMenuBrowseButton.tsx | `packages/excalidraw/components/LibraryMenuBrowseButton.tsx` | 19–29 | "Browse libraries" link to portal |
| parseLibraryTokensFromUrl | `packages/excalidraw/data/library.ts` | 530–543 | Reads `addLibrary` from URL hash/query |
| actionAddToLibrary | `packages/excalidraw/actions/actionAddToLibrary.ts` | 10–65 | Adds selection as unpublished library item |
| LibraryItem type | `packages/excalidraw/data/library.ts` | ~113 | `{ id, status, elements, name?, created }` |
| LibraryIndexedDBAdapter | `packages/excalidraw/data/LocalData.ts` | 229–256 | IDB persistence for library items |

## How It Works

1. **Library data format:** A `LibraryItem` is `{ id: string, status: "published" | "unpublished", elements: ExcalidrawElement[], name?: string, created: number }`. A library file (`.excalidrawlib`) is JSON: `{ type: "excalidrawlib", version: 2, source: string, libraryItems: LibraryItem[] }`.

2. **Persistence:** `LibraryIndexedDBAdapter` stores all library items in IndexedDB (in `LocalData.ts:229–256`). The library is loaded on app startup and saved on every change. `data/library.ts:253` has a TODO: `// TODO uncomment after/if we make jotai store scoped to each excal instance` — library isolation between multiple editor instances on the same page is deferred.

3. **Add to library:** `actionAddToLibrary` (actionAddToLibrary.ts:10–65): calls `app.library.getLatestLibrary()`, prepends a new `LibraryItem` with `status: "unpublished"` and the selected elements, then calls `app.library.setLibrary()`. Shows a success toast. Checks `LIBRARY_DISABLED_TYPES` — some element types are blocked from library storage.

4. **Import from URL:** `parseLibraryTokensFromUrl()` (library.ts:530–543) reads `URL_HASH_KEYS.addLibrary` from `window.location.hash` (primary) or `URL_QUERY_KEYS.addLibrary` from the query string (legacy). Also reads a `token` parameter for authentication. The resolved URL is fetched and its `.excalidrawlib` JSON is merged into the current library.

5. **Browse portal:** `LibraryMenuBrowseButton.tsx:19–29` opens `${VITE_APP_LIBRARY_URL}` (production: `https://libraries.excalidraw.com`) in a named window `"_excalidraw_libraries"` with params: `target`, `referrer`, `useHash=true`, `token` (random ID), `theme`, `version`.

6. **Drag to canvas:** Library items are dragged from the sidebar onto the canvas. On drop, the elements are deserialized and positioned at the drop coordinates.

## Dependencies
- `IndexedDB` via `idb-keyval` (library persistence)
- `VITE_APP_LIBRARY_URL` environment variable (portal URL)
- `app.library` API object (wraps IDB adapter)
- `appState.theme` (passed to portal for matching theme)

## Pros
- **URL token import enables library sharing:** Any library URL can be turned into a one-click import link — useful for teams sharing a common symbol library.
- **Published vs. unpublished status:** Items added locally start as `"unpublished"` — a clear distinction from community-published content.
- **SVG preview rendering:** Each library item renders a live SVG preview (no static thumbnails), so previews always reflect the actual element styles.
- **Portal integration:** Direct link to the community library catalog, with auth token passed for seamless install flow.
- **IDB persistence:** Library survives page refreshes and is not subject to localStorage size limits (5MB).

## Cons
- **Library is not scoped per editor instance:** `data/library.ts:253` TODO — if multiple Excalidraw instances run on the same page, they share the same library IDB store.
- **No folder/category organization:** Library items are flat — no nesting, tagging, or custom categories beyond what the portal provides.
- **No search in library sidebar:** The `LibraryMenuHeaderContent` has a search field, but it is basic text filtering on item names — not tag or shape-type based.
- **No version control for library items:** Updating an item replaces it — no history, no diff, no "what changed" for collaborative team libraries.
- **Import overwrites on conflict:** Importing a library with duplicate item IDs silently merges/overwrites — no conflict resolution UI.
- **`LIBRARY_DISABLED_TYPES` blocks some element types:** Certain element types (embeddables, magic frames) cannot be added to the library — not documented in the UI.

## Notes
- The `token` parameter in the portal URL is a random ID generated per session — used by the portal for analytics, not for authentication.
- `useHash=true` in the portal URL makes the portal put the `addLibrary` parameter in the URL hash rather than query string — required for the Excalidraw URL token parser.
- `data/library.ts:782` and `799` — a `hashchange` listener re-parses library tokens whenever the URL hash changes, enabling install flows that update the hash.
