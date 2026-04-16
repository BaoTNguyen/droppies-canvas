---
name: Undo/Redo History
description: Delta-based undo/redo stacks, CRDT-compatible element deltas, fractional index z-ordering, multiplayer undo behavior
type: project
---

# Undo/Redo History

## Overview
History is managed as two stacks of inverse deltas (not full snapshots). Each delta stores only the diff needed to revert or re-apply an action. Deltas are CRDT-compatible — applying them always generates new element version numbers, so collab clients treat undo/redo as new edits rather than conflicting reverts. There is no hard size cap on the undo stack.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| History class | `packages/excalidraw/history.ts` | 90 | Owns `undoStack` and `redoStack` arrays |
| undoStack / redoStack | `packages/excalidraw/history.ts` | 95–96 | `HistoryDelta[]` — plain arrays, no size cap |
| HistoryDelta.applyTo | `packages/excalidraw/history.ts` | 19–46 | Applies delta excluding `version`/`versionNonce` fields |
| Delta class | `packages/element/src/delta.ts` | 75 | `{ deleted, inserted }` partial diffs |
| StoreDelta | `packages/element/src/delta.ts` | ~100 | `elements` + `appState` deltas together |
| fractionalIndex.ts | `packages/element/src/fractionalIndex.ts` | full file | `generateNKeysBetween` for z-order encoding |
| orderByFractionalIndex | `packages/element/src/fractionalIndex.ts` | ~line 40 | Sorts elements by fractional index after delta apply |
| actionHistory | `packages/excalidraw/actions/actionHistory.tsx` | 50 | Calls `orderByFractionalIndex()` after undo/redo |
| LocalData.pauseSave | `excalidraw-app/data/LocalData.ts` | ~line 118 | Paused during collab to avoid IDB race conditions |

## How It Works

### Data Structure
`History` class (history.ts:90) owns two plain arrays:
- `undoStack: HistoryDelta[]` (line 95)
- `redoStack: HistoryDelta[]` (line 96)

Each `HistoryDelta` extends `StoreDelta` from `@excalidraw/element`, which wraps two `Delta<T>` objects: an elements delta and an appState delta. `Delta<T>` (delta.ts:75) stores `{ deleted: Partial<T>, inserted: Partial<T> }` — only the changed properties, not full copies. This makes undo/redo memory-efficient for large canvases.

### Applying a Delta (Undo/Redo)
`HistoryDelta.applyTo(elements, appState)` (history.ts:19–46):
1. Applies the elements delta and appState delta to the current scene
2. **Explicitly excludes `version` and `versionNonce`** (lines 30–34) via `excludedProperties: new Set(["version", "versionNonce"])`
3. Elements after apply always get freshly generated version numbers

The version exclusion is the key to multiplayer compatibility: every undo/redo is a "new edit" from the collab perspective — it generates new versions rather than rolling back to old ones.

### No Size Cap
There is no `MAX_HISTORY_SIZE` constant anywhere in the codebase. The undo stack grows unboundedly. Memory is managed only by delta compression (diffs, not snapshots) — a very large number of small edits will accumulate but individual entries are lightweight.

### Fractional Indexing for Z-Order
Each `ExcalidrawElement` has an `index: FractionalIndex` (from `fractional-indexing` npm package). Fractional indices encode z-order as part of the element data itself. After any delta is applied, `orderByFractionalIndex()` re-sorts the elements array to restore correct visual stacking. This enables incremental, conflict-free z-order reconciliation in multiplayer — no full array reorder needed.

After undo/redo, `actionHistory.tsx:50` calls `orderByFractionalIndex()` on the result to ensure correct render order.

### Collab Undo
The `History` class is shared — collab and local use the same undo stack. The difference is behavioral: since undo/redo generates new element versions (due to `version`/`versionNonce` exclusion), collaborators receive the undone state as a normal scene update — they do not see it as a "revert" but as a new change. This avoids the "who undid what" problem in shared history.

Local autosave (`LocalData.pauseSave("collaboration")`) is paused during collab sessions to prevent the autosaved local state from diverging from the synced collaborative state.

## Dependencies
- `appState.history` (tracks the stack state for UI — e.g., showing undo button as enabled/disabled)
- `fractional-indexing` npm package
- `@excalidraw/element` `StoreDelta`, `Delta`
- `actionHistory.tsx` (keyboard bindings: Ctrl+Z, Ctrl+Shift+Z)

## Pros
- **Delta-based history is memory-efficient:** Only diffs are stored, not snapshots. Even very active sessions with hundreds of operations should not accumulate significant memory.
- **Multiplayer undo is coherent:** The version exclusion trick means undo/redo integrates cleanly into the collab reconciliation model — no special-casing needed.
- **Fractional indexing preserves z-order across concurrent edits:** Two users reordering elements simultaneously will produce a deterministic merged result via fractional index sort.
- **Unbounded stack means no "undo limit" frustration:** Users can undo as far back as they need without hitting a cap.
- **CRDT-compatible deltas:** The `Delta<T>` design supports future migration to a fully CRDT-based sync model without changing the history data structure.

## Cons
- **No undo stack size cap means potential memory growth:** Long editing sessions with many small operations (e.g., freehand drawing) accumulate delta objects without bound. There is a `// TODO increase or remove once we optimize` comment adjacent to snapping (snapping.ts:44) suggesting performance is an active concern — similar caution applies here.
- **`actionFinalize.tsx:142,232,346` known bugs:** `// TODO: #7348` — invisible elements may incorrectly get recorded into the undo/redo store, polluting the history with no-op entries.
- **`delta.ts` has multiple `// TODO: #7348` edge cases:** CRDT delta application has acknowledged edge cases that can produce incorrect results in specific conflict scenarios.
- **No "undo tree" — only linear history:** Branching undo (make edit A, undo, make edit B — then recover edit A) is not supported. Once you branch by making a new edit after undo, the undone states are gone.
- **Collab undo only affects your own edits logically:** While the mechanism works, there is no UI indication that "undo" in a shared session might visually revert elements that other collaborators have also edited — no conflict resolution feedback.
- **No persistent history across sessions:** The undo stack is in-memory only — reloading the page starts with an empty undo stack.

## Notes
- `HistoryDelta` stores the **inverse** delta — applying it to the current state produces the previous state. This is the standard "command pattern" for undo.
- The `versionNonce` exclusion (history.ts:34) is specifically to prevent deterministic tie-breaking in reconciliation from producing incorrect results when the same element is undone/redone by different collaborators simultaneously.
