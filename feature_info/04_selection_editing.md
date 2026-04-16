---
name: Selection & Editing Operations
description: Box and lasso selection, group/ungroup, align/distribute, z-index ordering, element locking, flip, duplicate
type: project
---

# Selection & Editing Operations

## Overview
Elements can be selected via rectangular box drag or freehand lasso. Selected elements can be grouped, reordered by z-index, aligned, distributed, duplicated, flipped, or locked. Groups and locked elements have special multi-selection behaviors.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| Box selection logic | `packages/excalidraw/components/App.tsx` | 10244–10310 | `selectionElement` rect, `getElementsWithinSelection()` |
| boxSelectionMode state | `packages/excalidraw/appState.ts` | 131 | `"contain"` vs `"overlap"` default |
| LassoTrail class | `packages/excalidraw/lasso/index.ts` | 1–220 | Freehand lasso with real-time selection updates |
| getLassoSelectedElementIds | `packages/excalidraw/lasso/utils.ts` | 22–90 | AABB + polygon enclosure + segment intersection |
| actionGroup | `packages/excalidraw/actions/actionGroup.tsx` | 86–212 | Ctrl+G: assigns shared `groupId` to selected elements |
| actionUngroup | `packages/excalidraw/actions/actionGroup.tsx` | 214–321 | Ctrl+Shift+G: removes group membership |
| actionAlign (6 actions) | `packages/excalidraw/actions/actionAlign.tsx` | 39–273 | Align top/bottom/left/right/hcenter/vcenter |
| actionDistribute (2 actions) | `packages/excalidraw/actions/actionDistribute.tsx` | 35–131 | Distribute horizontally/vertically |
| z-index actions | `packages/excalidraw/actions/actionZindex.tsx` | full file | Send backward/forward/to back/to front |
| zindex move logic | `packages/element/src/zindex.ts` | 36–604 | `moveOneLeft`, `moveOneRight`, `shiftElementsToEnd` |
| actionToggleElementLock | `packages/excalidraw/actions/actionElementLock.ts` | 24–153 | Ctrl+Shift+L: locks/unlocks selected elements |
| actionUnlockAllElements | `packages/excalidraw/actions/actionElementLock.ts` | 156–214 | Unlocks all when nothing selected |

## How It Works

### Box Selection
`appState.selectionElement` is set to a rectangle element during drag. `getElementsWithinSelection()` checks all elements against the rect. `appState.boxSelectionMode` determines whether elements must be fully `"contain"`ed or just `"overlap"` the selection rect. Ctrl+Alt+drag from selection mode switches to lasso (App.tsx:8562–8573, sets `{ type: "lasso", fromSelection: true }`).

### Lasso Selection
`LassoTrail.addPointToPath()` (lasso/index.ts:166) calls `updateSelection()` (line 174) on every pointer move. `getLassoSelectedElementIds()` runs:
1. Fast AABB bounds check (`doBoundsIntersect`)
2. Enclosure test: polygon vertices inside lasso via `polygonIncludesPointNonZero`
3. Intersection test: lasso segments against element segments via `intersectElementWithLineSegment`
Selection updates live during drawing. `selectElementsFromIds()` (line 92) promotes text-bound containers and removes frame children when a frame is selected.

### Group/Ungroup
`actionGroup` (Ctrl+G): creates `newGroupId = randomId()`, adds it to each selected element's `groupIds` array via `addToGroup()`. If elements come from different frames, they are removed from frames first. `syncMovedIndices()` reorders elements to be contiguous. `actionUngroup` (Ctrl+Shift+G): removes the current group from each element's `groupIds`, updates frame membership.

### Align & Distribute
Six align actions (top/bottom/left/right/hcenter/vcenter) map to `Ctrl+Shift+Arrow` keys. All call `alignElements()` from `@excalidraw/element`. **Known limitation:** `alignActionsPredicate()` (actionAlign.tsx:51) returns `false` if any selected element `isFrameLikeElement()` — align is completely disabled when a frame is in the selection (`// TODO enable aligning frames when implemented properly`). Same restriction in `actionDistribute.tsx:43`.

### Z-Index Ordering
Four actions: `actionSendBackward` (Ctrl+[), `actionBringForward` (Ctrl+]), `actionSendToBack` (Ctrl+Shift+[), `actionBringToFront` (Ctrl+Shift+]). The move logic in `zindex.ts` keeps containers and bound text together (`getTargetIndexAccountingForBinding()`), and ensures frame children move as a contiguous block (`getContiguousFrameRangeElements()`).

### Element Locking
`actionToggleElementLock` (Ctrl+Shift+L): if all selected elements are unlocked, locks them (`locked: true`). When locking multiple non-grouped elements, creates a temporary `newGroupId` stored in `appState.lockedMultiSelections` to keep them visually associated. Locked elements are immediately removed from `selectedElementIds`. `actionUnlockAllElements` fires when nothing is selected but locked elements exist.

## Dependencies
- `appState.selectedElementIds`, `appState.selectionElement`, `appState.boxSelectionMode`
- `appState.lockedMultiSelections` (tracks temp groups for locked multi-selections)
- `@excalidraw/element` `alignElements()`, `distributeElements()`, `orderByFractionalIndex()`
- `zindex.ts` (binding-aware z-ordering)

## Pros
- **Lasso selection is real-time:** Selection updates as you draw, with polygon + segment intersection testing — far more precise than box selection for non-rectangular layouts.
- **Z-index is binding-aware:** Moving an arrow in z-order automatically keeps its bound endpoints and text labels in their correct relative position.
- **Locking with temp groups:** Locking multiple non-grouped elements creates a visual grouping (`lockedMultiSelections`) so they can be unlocked together.
- **Ctrl+Alt+drag triggers lasso from selection mode:** No tool switch needed — accessible as a modifier gesture.
- **Group membership stacks:** `groupIds` is an array, not a single ID — elements can belong to multiple nested groups.

## Cons
- **Align/distribute is blocked for frames:** Any selection containing a frame element silently disables all align and distribute actions. No error message — the buttons just become inactive. This is a significant gap for diagram workflows. (TODOs in actionAlign.tsx:51 and actionDistribute.tsx:43)
- **Box selection has only two modes (contain/overlap):** No per-axis selection, no "touch" mode that selects partially visible elements.
- **No "select similar" feature:** Cannot select all elements with the same fill color, font, or style.
- **Lasso selection doesn't support keyboard navigation:** Once the lasso is drawn you cannot add/remove individual elements with Shift+click in the same gesture.
- **Group reorder enforces contiguity:** `syncMovedIndices()` reorders z-indices when grouping — may move elements relative to non-grouped elements unexpectedly.
- **Unlock all is all-or-nothing:** `actionUnlockAllElements` unlocks every locked element on the canvas, not just the ones near the selection.

## Notes
- `actionAlign.tsx:50` and `actionDistribute.tsx:43` both contain explicit `// TODO enable aligning/distributing frames when implemented properly` — this is a known product gap, not an accidental omission.
- The `lockedMultiSelections` field in appState is a special-purpose mechanism only for locking — it is not a general-purpose "group without grouping" feature.
