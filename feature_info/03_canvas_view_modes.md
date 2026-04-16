---
name: Canvas & View Modes
description: Infinite scroll/zoom, dark mode, grid mode, zen mode, view mode, object snapping, and background color
type: project
---

# Canvas & View Modes

## Overview
The canvas is infinite and zoomable (10%–3000%). Four distinct view modes — dark mode, grid, zen mode, and view/presentation mode — can be toggled independently. Object snapping aligns elements to each other or to a grid. The canvas background color is also configurable.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| Scroll/zoom state | `packages/excalidraw/types.ts` | 330–335 | `scrollX`, `scrollY`, `zoom: { value }` |
| handleWheel | `packages/excalidraw/components/App.tsx` | 12577–12660 | Mouse wheel → pan and zoom |
| getStateForZoom | `packages/excalidraw/scene/zoom.ts` | 3–35 | Pins cursor point during zoom |
| getNormalizedZoom | `packages/excalidraw/scene/normalize.ts` | 7–8 | Clamps zoom to [0.1, 30] |
| MIN_ZOOM / MAX_ZOOM | `packages/common/src/constants.ts` | 303–304 | 0.1 (10%) and 30 (3000%) |
| actionToggleTheme | `packages/excalidraw/actions/actionCanvas.tsx` | 468–494 | Toggles `appState.theme` light↔dark |
| actionToggleGridMode | `packages/excalidraw/actions/actionToggleGridMode.tsx` | full file | Toggles `gridModeEnabled`, `gridSize`, `gridStep` |
| strokeGrid | `packages/excalidraw/renderer/staticScene.ts` | 56–130 | Renders grid lines on canvas |
| actionToggleZenMode | `packages/excalidraw/actions/actionToggleZenMode.tsx` | full file | Toggles `zenModeEnabled`, CSS transitions on panels |
| actionToggleViewMode | `packages/excalidraw/actions/actionToggleViewMode.tsx` | full file | Toggles `viewModeEnabled`, disables drawing/selection |
| snapping.ts | `packages/excalidraw/snapping.ts` | full file | Object snap engine with SnapCache and gap snapping |
| SNAP_DISTANCE | `packages/excalidraw/snapping.ts` | 41, 48 | 8px base, scaled by zoom: `8 / zoomValue` |

## How It Works

### Infinite Scroll & Zoom
`handleWheel` (App.tsx:12577) intercepts scroll events. Without modifier: `scrollX -= deltaX / zoom.value`, `scrollY -= deltaY / zoom.value` — no boundaries, truly infinite. With Ctrl/Cmd: computes logarithmically amplified zoom delta, calls `getStateForZoom(viewportX, viewportY, nextZoom)` which mathematically pins the point under the cursor by adjusting scroll offsets to compensate for the zoom change.

### Dark Mode
`actionToggleTheme` (actionCanvas.tsx:468, shortcut `Alt+Shift+D`) flips `appState.theme` between `"light"` and `"dark"`. Rendering checks `theme` at draw time: `generateRoughOptions` calls `applyDarkModeFilter` on colors; `renderElement.ts:366` switches background fill colors. The canvas `background-color` CSS also updates.

### Grid Mode
`actionToggleGridMode` (shortcut `Ctrl+'`) sets `gridModeEnabled: true` and simultaneously sets `objectsSnapModeEnabled: false` (mutually exclusive). `strokeGrid()` (staticScene.ts:56–130) draws dashed lines at `gridSize` intervals with bold lines every `gridStep * gridSize` pixels. Lines are suppressed when zoom makes the grid smaller than 10px. Two configurable values: `appState.gridSize` (cell size in pixels) and `appState.gridStep` (bold line interval).

### Zen Mode
`actionToggleZenMode` (shortcut `Alt+Z`) sets `zenModeEnabled: true`. CSS transitions (`zen-mode-transition`) slide all UI panels off-screen:
- Left panel (shape actions): `transition-left`
- App toolbar (shapes bar): hidden via `zen-mode` CSS class
- Top-right panel, footer left, footer center, footer right: respective transition directions
- Stats panel: fully hidden
An "Exit Zen Mode" floating button appears if zen mode was entered via UI (not forced by props).

### View Mode
`actionToggleViewMode` (shortcut `Alt+R`) sets `viewModeEnabled: true`. Effects:
- Toolbar (`<Section heading="shapes">`) is not rendered at all
- `handleCanvasPointerDown` returns early — no drawing or selection
- Keyboard shortcuts for tools return early (except `"laser"` and `"hand"`)
- Pointer-move/up event listeners are not attached
If host passes `viewModeEnabled` as a prop, it overrides all appState changes (App.tsx:2765–2767).

### Object Snapping
`snapDraggedElements()` (snapping.ts:692) is called during element drag. Algorithm:
1. Build `SnapCache` (static cache of reference element corners + gap measurements) when scroll/zoom changes
2. For each selected element, compute snap candidate points (corners, center, midpoints) via `getElementsCorners()`
3. Check each candidate against `referenceSnapPoints` within `SNAP_DISTANCE = 8 / zoomValue` on each axis
4. Also check `visibleGaps` for equal-spacing snap opportunities
5. Apply smallest snap offset per axis; draw snap lines via `renderSnaps.ts`

Snapping activates when `objectsSnapModeEnabled && !Ctrl` OR `!objectsSnapModeEnabled && Ctrl && !gridMode` — i.e., Ctrl is the "snap override" key in both directions.

## Dependencies
- `appState.theme`, `appState.gridModeEnabled`, `appState.gridSize`, `appState.gridStep`
- `appState.zenModeEnabled`, `appState.viewModeEnabled`
- `appState.objectsSnapModeEnabled`, `appState.snapLines`
- `browser-fs-access`, `roughjs` for rendering

## Pros
- **Zoom range is generous:** 10%–3000% covers overview to fine pixel work. Cursor-pinning during zoom is mathematically correct — no jarring jumps.
- **Grid mode has hierarchical levels:** `gridSize` + `gridStep` means you get minor and major grid lines, useful for technical diagrams.
- **Zen mode is fully animated:** CSS slide transitions make the mode change feel polished rather than abrupt.
- **Object snap has gap snapping:** Equal-spacing detection means you can distribute elements evenly just by dragging — no action required.
- **Snapping is zoom-aware:** `SNAP_DISTANCE = 8 / zoomValue` keeps the "snap zone" constant in screen pixels regardless of zoom level.
- **View mode is truly read-only:** No accidental edits possible — toolbar, pointer handlers, and keyboard shortcuts are all blocked.

## Cons
- **Grid and object snap are mutually exclusive:** Enabling grid automatically disables object snapping and vice versa (`actionToggleGridMode` forces `objectsSnapModeEnabled: false`). Users cannot use both simultaneously.
- **Grid size is not configurable from the UI:** `gridSize` and `gridStep` are appState fields but there is no settings UI for them — you must use the Stats panel's CanvasGrid or the API.
- **`snapping.ts:44` TODO:** `// TODO increase or remove once we optimize` — snap distance cap exists for performance reasons, not UX reasons.
- **No per-axis snap toggle:** Cannot snap only horizontally or only vertically.
- **Dark mode is canvas-only:** The dark mode switch is not a system-level observer — it will not automatically follow OS dark/light preference changes.
- **`actionToggleTheme` can be disabled by host:** `UIOptions.canvasActions.toggleTheme` must be `true` for the action to appear (actionCanvas.tsx:480).

## Notes
- `MIN_ZOOM = 0.1`, `MAX_ZOOM = 30` (constants.ts:303–304). At 3000% zoom, a standard 1920px viewport covers ~64px of canvas — fine detail work is possible.
- Scroll has no boundary — `scrollX`/`scrollY` are unbounded. There is no "snap to origin" behavior by default except `Shift+1/2/3` zoom presets.
- Dark mode export is a separate option from the canvas dark mode (`exportWithDarkMode` appState flag) — you can export in dark mode without viewing in dark mode and vice versa.
