---
name: Search & Command Palette
description: In-canvas element text search with highlight overlays, fuzzy command palette with all actions/tools/shortcuts
type: project
---

# Search & Command Palette

## Overview
Two keyboard-driven discovery features: In-canvas search (Ctrl+F) finds text elements and frame names, highlighting matches with overlay rectangles. The command palette (Ctrl+Shift+P or Ctrl+/) provides fuzzy search over all actions, tools, library items, and hardcoded commands.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| SearchMenu.tsx | `packages/excalidraw/components/SearchMenu.tsx` | full file | In-canvas search panel |
| searchQueryAtom | `packages/excalidraw/components/SearchMenu.tsx` | 55 | Jotai atom for current search query |
| searchItemInFocusAtom | `packages/excalidraw/components/SearchMenu.tsx` | 56 | Jotai atom for focused result index |
| handleSearch (debounced) | `packages/excalidraw/components/SearchMenu.tsx` | 787–876 | Searches text + frame elements, computes highlight rects |
| SEARCH_DEBOUNCE | `packages/excalidraw/components/SearchMenu.tsx` | ~line 783 | 350ms debounce on search input |
| CommandPalette.tsx | `packages/excalidraw/components/CommandPalette/CommandPalette.tsx` | full file | Fuzzy command palette |
| CommandPalette shortcut | `packages/excalidraw/components/CommandPalette/CommandPalette.tsx` | 139–146 | Ctrl+Shift+P OR Ctrl+/ |
| defaultCommandPaletteItems.ts | `packages/excalidraw/components/CommandPalette/defaultCommandPaletteItems.ts` | full file | Currently only `toggleTheme` |
| CommandPalette categories | `packages/excalidraw/components/CommandPalette/CommandPalette.tsx` | 85–93 | App, Export, Tools, Editor, Elements, Links, Library |
| CommandPalette types | `packages/excalidraw/components/CommandPalette/types.ts` | full file | `CommandPaletteItem` type |
| fuzzy library | `packages/excalidraw/components/CommandPalette/CommandPalette.tsx` | line 2 | `fuzzy` npm package for fuzzy matching |

## How It Works

### In-Canvas Search
Opening: `Ctrl/Cmd + F` (SearchMenu.tsx:296–313) opens the search panel, focusing the input.

`handleSearch()` (debounced 350ms, lines 787–876):
1. Builds a `RegExp` with `gi` flags from the query (special characters escaped)
2. Iterates all visible elements:
   - Text elements: matches `textEl.originalText` (raw text before wrapping)
   - Frame elements: matches `frame.name ?? getDefaultFrameName(frame)`
3. Separates results into `frameMatches` (shown first) and `textMatches`
4. For each text match, computes per-line highlight positions using `measureText()` — producing `matchedLines[]` with `{ offsetX, offsetY, width, height }` in scene coordinates
5. Stores result in state; the canvas renderer draws highlight rectangles over matching positions

Navigation: `Enter`, `ArrowUp`, `ArrowDown` cycle through results when the search panel has focus. Focused result scrolls into view and the matching element is visually highlighted.

### Command Palette
Opening: `Ctrl/Cmd + Shift + P` or `Ctrl/Cmd + /` (CommandPalette.tsx:139–146).

Items are assembled dynamically from:
- All registered `ActionManager` actions (categorized by type)
- All tools from `SHAPES` (Tools category)
- Library items (Library category)
- Hardcoded items: `actionClearCanvas`, `actionLink`, `actionToggleSearchMenu`, `actionCopyElementLink`, `actionLinkToElement`
- Default items from `defaultCommandPaletteItems.ts` (currently just `toggleTheme`)

**Categories** (lines 85–93): `App`, `Export`, `Tools`, `Editor`, `Elements`, `Links`, `Library`.

Fuzzy matching: uses the `fuzzy` npm package. As the user types, all items are scored and sorted by fuzzy match quality. Each item shows its keyboard shortcut alongside the label (via `getShortcutFromShortcutName()`).

## Dependencies
- `appState.openDialog` (search opens as a dialog)
- `ActionManager` (command palette item source)
- `app.library` (command palette library items)
- `fuzzy` npm package
- `SHAPES` array (tool items)

## Pros
- **Search highlights are overlay rectangles on canvas:** Matches are visually indicated in-place — users don't need to navigate away from the canvas context to find elements.
- **Frame names are searchable:** Searching for a frame name focuses the frame, useful for large multi-diagram documents.
- **Command palette covers all actions:** Every registered action + every tool + library items are all searchable from one input — power users can avoid memorizing all shortcuts.
- **Fuzzy matching is forgiving:** Typos and partial matches still surface relevant commands.
- **Shortcuts shown in palette:** Each palette item displays its keyboard shortcut — the palette doubles as a shortcut discovery tool.
- **Search is debounced at 350ms:** Fast enough to feel responsive, slow enough to avoid thrashing on every keystroke.

## Cons
- **Search only covers text content and frame names:** Element labels, shape types, colors, and other properties are not searchable. You cannot search "find all red rectangles."
- **No regex search from the UI:** The implementation uses RegExp internally, but there is no way for users to use regex patterns.
- **Command palette items are assembled on every open:** No caching — all actions, tools, and library items are re-evaluated on each palette open. Large libraries may produce a noticeable delay.
- **`defaultCommandPaletteItems.ts` has only one item:** The file exists as an extension point, but currently contains only `toggleTheme`. The architecture suggests more items were planned but not yet added.
- **No command palette history:** Recently used commands are not ranked higher — every open starts with the same sorted list.
- **Search highlight positions can become stale:** If elements are edited while the search panel is open, highlight positions may not update until the next search query.

## Notes
- `SEARCH_DEBOUNCE = 350ms` (SearchMenu.tsx) is configurable only by modifying the source — no user setting.
- The command palette categories (`App`, `Export`, `Tools`, etc.) are used for display grouping only — they do not affect search ranking.
- `actionToggleSearchMenu` is itself a command palette item — the palette and search are mutually aware and can open each other.
