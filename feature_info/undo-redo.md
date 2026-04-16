# Undo / Redo

## What It Does
Provides unlimited undo and redo for drawing and editing operations. Each project maintains its own independent undo/redo history — switching between project tabs preserves each project's history. Supported operations: add stroke (brush/shape tools), erase strokes, move strokes, delete selected strokes, add multiple strokes (paste).

## How to Use It
- **Ctrl+Z** to undo the last action
- **Ctrl+Y** (or **Ctrl+Shift+Z** depending on keybinding) to redo
- Toolbar has dedicated Undo and Redo buttons
- History depth is unlimited (Godot's `UndoRedo` default has no cap in v3.x)

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| Project | `lorien/ProjectManager/Project.gd` | — | Owns the `UndoRedo` instance for this project |
| InfiniteCanvas | `lorien/InfiniteCanvas/InfiniteCanvas.gd` | 229–262 | Registers stroke-add actions in undo/redo |
| InfiniteCanvas | `lorien/InfiniteCanvas/InfiniteCanvas.gd` | 264–276 | Registers multi-stroke-add (paste) |
| InfiniteCanvas | `lorien/InfiniteCanvas/InfiniteCanvas.gd` | 340–367 | `_do_delete_stroke` / `_undo_delete_stroke` |
| EraserTool | `lorien/InfiniteCanvas/Tools/EraserTool.gd` | 58–67 | Registers erase actions |
| SelectionTool | `lorien/InfiniteCanvas/Tools/SelectionTool.gd` | 191–197 | Registers move-strokes actions |
| Main | `lorien/Main.gd` | 413–422 | Routes Ctrl+Z/Y to the active project's UndoRedo |

## Architecture Notes
Each `Project` object owns a Godot `UndoRedo` instance. This is the right design — tab-switching changes the active project but each project's history is isolated.

Actions are registered with `create_action` → `add_do_method` / `add_undo_method` / `add_do_property` / `add_undo_property` → `commit_action`. Godot's `UndoRedo` uses reference counting via `add_undo_reference` / `add_do_reference` to keep stroke nodes alive after they're removed from the scene tree.

**Registered undo actions**:
| Action Name | Where Registered | What It Does/Undoes |
|-------------|-----------------|---------------------|
| `"Stroke"` | `InfiniteCanvas.end_stroke` | Add/remove a single drawn stroke |
| `"Add Strokes"` | `InfiniteCanvas.add_strokes` | Add/remove a batch of strokes (paste) |
| `"Erase Stroke"` | `EraserTool` | Delete/restore erased strokes |
| `"Delete Selection"` | `InfiniteCanvas._delete_selected_strokes` | Delete/restore selected strokes |
| `"Move Strokes"` | `SelectionTool._add_undoredo_action_for_moved_strokes` | Set/restore `global_position` on moved strokes |

## Pros
- Per-project undo history is isolated — undoing in tab A does not affect tab B
- `add_undo_reference` correctly keeps stroke nodes alive in memory after removal from scene tree, preventing use-after-free when redoing
- Batch undo for eraser (entire drag gesture = single undo step) and paste (all pasted strokes = single undo step) is good UX
- Move operations use `add_do_property` / `add_undo_property` on `global_position` — clean and minimal

## Cons / Limitations
- **Recolor has no undo**: changing the active color while strokes are selected directly mutates `stroke.color` without creating an undo entry (confirmed in `SelectionTool._on_brush_color_changed`)
- **Undo-delete restores strokes at wrong z-order**: `_undo_delete_stroke` appends strokes at the back of the draw order. A FIXME comment acknowledges this but notes it's hard to fix without storing the full before/after stroke array
- **Clear canvas has no undo**: the `clear()` action from the toolbar button (`_on_clear_canvas`) removes all strokes without registering an undo entry — this is a silent, irreversible operation
- History is never pruned: a long drawing session accumulates an unbounded undo stack, which grows memory usage over time
- Undo button in the toolbar does not grey out when there is nothing to undo (no visual feedback of history state)

## Decision Guidance
Undo/redo is mostly solid. The two critical gaps are: (1) **clear canvas should be undoable** — as a destructive one-click action with no confirmation, its lack of undo is a real data loss risk; and (2) **recolor should be undoable** — it silently mutates data. Both are straightforward to fix by registering the actions in `UndoRedo`.
