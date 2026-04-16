---
name: Stats Panel
description: Editable position/size/angle/font stats for selected elements, multi-element aggregation, bitmask-controlled collapsible sections
type: project
---

# Stats Panel

## Overview
The Stats panel (Alt+/) shows and allows direct numeric editing of position (X, Y), dimensions (W, H), rotation angle, and font size for selected elements. Multiple elements are grouped into "atomic units" (by group membership) and can be moved/resized together via the panel. Collapsible sections are controlled by a bitmask stored in appState.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| Stats/index.tsx | `packages/excalidraw/components/Stats/index.tsx` | 115–443 | Main stats component, `StatsInner` memo |
| actionToggleStats | `packages/excalidraw/actions/actionToggleStats.tsx` | 27 | Alt+/: toggles `appState.stats.open` |
| StatsInner memo | `packages/excalidraw/components/Stats/index.tsx` | 115 | Re-renders on sceneNonce/selectedElements/panels change |
| Position sub-component | `packages/excalidraw/components/Stats/index.tsx` | ~302 | Editable X, Y inputs |
| Dimension sub-component | `packages/excalidraw/components/Stats/index.tsx` | ~310 | Editable W, H inputs |
| Angle sub-component | `packages/excalidraw/components/Stats/index.tsx` | ~320 | Rotation angle (disabled for frame elements) |
| FontSize sub-component | `packages/excalidraw/components/Stats/index.tsx` | ~335 | Font size (text elements only) |
| CanvasGrid sub-component | `packages/excalidraw/components/Stats/index.tsx` | ~345 | gridStep input (when grid mode enabled) |
| getAtomicUnits | `packages/excalidraw/components/Stats/utils.ts` | 234–252 | Groups selected elements by groupId for joint editing |
| isPropertyEditable | `packages/excalidraw/components/Stats/utils.ts` | 46–53 | Disables angle for frame elements |
| STATS_PANELS bitmask | `packages/common/src/constants.ts` | ~line 450 | Bitmask for collapsible panel open/close state |
| panels toggle | `packages/excalidraw/components/Stats/index.tsx` | 199–207, 257–263 | XOR toggle: `appState.stats.panels ^= STATS_PANELS.x` |

## How It Works

### Opening & Rendering
`actionToggleStats` (actionToggleStats.tsx:27): shortcut is `!event[KEYS.CTRL_OR_CMD] && event.altKey && event.code === CODES.SLASH` — specifically Alt+/ without Ctrl/Cmd. Toggles `appState.stats.open`.

`StatsInner` (Stats/index.tsx:115) is memoized and re-renders when `sceneNonce`, `selectedElements`, `stats.panels` bitmask, `gridStep`, or `croppingElementId` changes. This prevents unnecessary re-renders during canvas interactions that don't affect selected elements.

Stats panel is fully hidden when zen mode is on (LayerUI.tsx:295).

### Editable Properties
For a single element:
- **Position** (`x`, `y`): canvas coordinates in scene space
- **Dimensions** (`width`, `height`): element bounding box dimensions
- **Angle**: rotation in degrees (0–360); disabled for frame elements via `isPropertyEditable()` (utils.ts:46–53)
- **FontSize**: only shown for text elements
- **CanvasGrid / gridStep**: only shown when `gridModeEnabled === true`

Editing any input immediately updates the element via `updateScene()` — changes are applied on every keystroke (live), not just on blur.

### Multi-Element Aggregation
`getAtomicUnits()` (Stats/utils.ts:234–252): groups selected elements by their `groupIds` into "atomic units" — elements that share a group ID are treated as one unit for position/size operations. This means if you select a group of elements, changing X in the Stats panel moves all of them together, maintaining their relative positions.

Multi-element components (`MultiPosition`, `MultiDimension`, `MultiAngle`, `MultiFontSize`) receive `atomicUnits`. For display, they show aggregated/mixed values. For editing, deltas are applied proportionally to each element in the atomic unit.

### Collapsible Sections
`STATS_PANELS` is a bitmask (from `@excalidraw/common`) where each bit represents a panel section. Toggling a section XORs `appState.stats.panels` with the corresponding bit (Stats/index.tsx:199–207, 257–263). This state persists in `appState` and is saved to localStorage on autosave.

## Dependencies
- `appState.stats.open`, `appState.stats.panels` (visibility + section state)
- `appState.gridModeEnabled`, `appState.gridStep` (CanvasGrid section visibility)
- `appState.croppingElementId` (prevents stats from showing during crop editing)
- `appState.zenModeEnabled` (hides stats panel entirely)

## Pros
- **Numeric precision:** Position and size can be set exactly via keyboard input — critical for technical/architectural diagrams where alignment to pixel boundaries matters.
- **Live updates:** Changes apply on every keystroke, giving immediate visual feedback without needing to confirm.
- **Atomic unit grouping:** Groups are respected — editing a grouped selection through the stats panel maintains relative positioning.
- **Bitmask panel state is persisted:** The open/close state of each collapsible section survives page reloads.
- **Grid step editable in Stats:** The only UI for changing `gridStep` is in the Stats panel — useful discovery for users who find it.

## Cons
- **Angle is disabled for frames:** `isPropertyEditable()` explicitly disables angle editing for frame elements. Frames cannot be rotated via the Stats panel or rotate handle. This is an intentional limitation but not communicated to users in the UI.
- **No bulk style editing:** The Stats panel covers geometry (position, size, angle) and font size only — cannot bulk-edit colors, fill style, or stroke width numerically.
- **Alt+/ shortcut conflicts with some OS/keyboard layouts:** Alt+/ produces different characters on non-US keyboard layouts. The stats panel may be difficult to toggle on some locales.
- **Stats panel is always floating:** It cannot be docked or resized — it overlaps the canvas in a fixed position, which can obscure small or precisely-placed elements.
- **No X/Y coordinate system explanation:** The coordinate origin (0, 0) in scene space is not explained — users may be confused by large or negative coordinates depending on where they started drawing.
- **gridStep is the only canvas-level stat:** The Stats panel is otherwise element-focused — adding canvas-level stats like "total elements," "canvas bounds," or "selection bounds" would be useful but not present.

## Notes
- `appState.stats.panels` is a numeric bitmask, not a plain boolean — each bit position corresponds to a section. This design allows adding new sections without changing the data structure.
- The Angle input has special handling for frame elements: `isPropertyEditable(element, "angle")` (utils.ts:46–53) returns `false` for `isFrameLikeElement(element)`.
- Stats panel visibility is explicitly excluded from zen mode: if `zenModeEnabled`, the panel container is set to `display: none` at LayerUI level, overriding any `stats.open` state.
