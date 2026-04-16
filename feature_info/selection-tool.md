# Selection Tool

## What It Does
Allows the user to select one or more strokes by drawing a rubber-band rectangle, then move, copy, paste, duplicate, recolor, or delete them. Selected strokes are highlighted in teal. All operations are undoable.

## How to Use It
- Press **S** (default) or click the selection icon in the toolbar
- **Left-click drag** on empty space to draw a selection rectangle
- Hold **Shift + drag** to add to the existing selection (multi-select)
- **Left-click and drag on selected strokes** to move them
- **Left-click on empty space** (with selection active) to deselect
- **Right-click** to deselect all
- **Delete key** to delete selected strokes
- **Ctrl+C** to copy, **Ctrl+V** to paste (pastes centered on cursor)
- **Ctrl+D** to duplicate (copy + immediate paste in one action)
- When the active color is changed while strokes are selected, **all selected strokes are recolored**
- Shift key toggles the cursor between a select-crosshair and a move-arrow

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| SelectionTool | `lorien/InfiniteCanvas/Tools/SelectionTool.gd` | 1–256 | All selection, movement, copy/paste, recolor logic |
| SelectionRectangle | `lorien/InfiniteCanvas/Tools/SelectionRectangle.gd` | — | Visual rubber-band rectangle drawn during selection drag |
| InfiniteCanvas | `lorien/InfiniteCanvas/InfiniteCanvas.gd` | 340–367 | `_do_delete_stroke` / `_undo_delete_stroke` used by delete action |
| InfiniteCanvas | `lorien/InfiniteCanvas/InfiniteCanvas.gd` | 264–276 | `add_strokes()` — used by paste to add multiple strokes with undo |

## Architecture Notes
Selection state is tracked using Godot scene groups on individual `BrushStroke` nodes:
- `GROUP_SELECTED_STROKES` — committed selection
- `GROUP_STROKES_IN_SELECTION_RECTANGLE` — provisional (rubber-band in progress)
- `GROUP_MARKED_FOR_DESELECTION` — Shift-click deselect pending
- `GROUP_COPIED_STROKES` — clipboard (strokes marked for paste)

Selection hit-testing uses per-stroke bounding boxes (pre-built at drag start) plus point-in-rect checks against the selection rectangle. Strokes are tested only against `get_strokes_in_camera_frustrum()` — off-screen strokes cannot be selected.

Movement records `global_position` for each selected stroke before the drag begins in `_stroke_positions_before_move`. On mouse release, a single undo action records all the `global_position` changes.

Copy stores references to live stroke nodes in the `GROUP_COPIED_STROKES` group — it is not a deep copy until paste is triggered. On paste, `_duplicate_stroke` creates new `BrushStroke` instances with all point data copied and a positional offset applied to center the paste at the cursor.

Recolor is immediate and destructive (no undo entry): changing the active color while strokes are selected calls `_on_brush_color_changed` which directly mutates `stroke.color` on all selected strokes.

## Pros
- Group-based selection state is an elegant use of Godot's node group system — no separate selection array to keep in sync
- Copy/paste correctly centers the pasted group at the cursor position, regardless of the original selection's position on the canvas
- Moving strokes is registered as a single undo action covering all moved strokes
- Recolor-on-selection is a power feature: select all strokes of one color and instantly repaint them

## Cons / Limitations
- **Off-screen strokes cannot be selected**: `compute_selection` only tests strokes in the camera frustum — if a stroke extends off-screen, only the visible portion is considered, and a rubber-band that would logically include it may miss it
- **Recolor has no undo**: changing the brush color while strokes are selected permanently recolors them with no undo entry (this is a silent data-loss risk)
- **Undo of delete restores strokes at wrong z-order**: the known FIXME in `_undo_delete_stroke` appends strokes at the back of the draw order instead of their original position — strokes reappear behind newer strokes after undo
- Selection only works with rectangular rubber-bands — no lasso/freehand selection
- The clipboard uses live node references (the `GROUP_COPIED_STROKES` group). If the source project is closed before pasting, the clipboard becomes stale without any warning

## Decision Guidance
The selection tool covers the basics well. The two most impactful gaps are: (1) undo for recolor — this should be registered in `UndoRedo` like movement is; and (2) the off-screen selection limitation, which means working with content spread across a large canvas requires careful scrolling. Both are fixable without architectural changes.
