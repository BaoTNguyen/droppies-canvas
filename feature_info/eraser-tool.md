# Eraser Tool

## What It Does
Removes entire strokes by painting over them with an eraser brush. The eraser does not partially erase a stroke (no split-at-eraser); instead, any stroke whose path passes through the eraser circle is deleted in full. Deletions are undoable.

## How to Use It
- Press **E** (default) or click the eraser icon in the toolbar
- **Hold left mouse button and drag** over strokes to erase them
- Eraser size is controlled by the same brush size slider
- On supported pen tablets, **flipping the stylus** (pen-inverted event) automatically switches to the eraser and back

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| EraserTool | `lorien/InfiniteCanvas/Tools/EraserTool.gd` | 1–78 | Hit detection, stroke removal, undo/redo commit |
| InfiniteCanvas | `lorien/InfiniteCanvas/InfiniteCanvas.gd` | 340–367 | `_do_delete_stroke` / `_undo_delete_stroke` (shared with selection delete) |
| InfiniteCanvas | `lorien/InfiniteCanvas/InfiniteCanvas.gd` | 66–78 | Pen-inverted detection → auto-switch to eraser |

## Architecture Notes
When erasing begins, the tool builds a bounding-box cache (`_bounding_box_cache`) for all strokes using a 20 px margin. On every `_process` frame while `performing_stroke` is true, `_remove_stroke` iterates over strokes visible in the camera frustum. For each candidate:

1. **Bounding box pre-test**: if the cursor is outside the stroke's padded bounding box, skip immediately
2. **Segment circle intersection**: for each consecutive pair of points in the stroke, compute the combined radius (eraser_radius + segment_pressure_radius) and call `Geometry.segment_intersects_circle`. If any segment passes the test, the stroke is marked for removal

Marked strokes are batched into a single `UndoRedo` action ("Erase Stroke") and deleted atomically. The bounding-box cache is rebuilt fresh at the start of each erase gesture (not kept hot between gestures).

The pen-inverted path in `InfiniteCanvas._process_event` saves the active tool type, switches to eraser, but keeps `_active_tool_type` pointing at the previous tool. When the stylus is flipped back, `use_tool(_active_tool_type)` restores the original tool.

## Pros
- Pen-inverted auto-switch is a first-class feature — tablet users can erase by flipping the stylus without touching the toolbar
- Bounding-box pre-test makes the per-frame intersection check cheap even with hundreds of strokes on screen
- Erasure is batched into a single undo step — Ctrl+Z un-erases the entire drag gesture atomically

## Cons / Limitations
- **Whole-stroke deletion only**: erasing through the middle of a stroke removes the entire stroke, not just the intersected portion. This is a fundamental UX limitation for detailed work
- The bounding-box cache is rebuilt on every new erase gesture — if the user starts/stops rapidly, this is redundant work; it should be invalidated incrementally as strokes are added/removed
- Erasing only checks strokes **in the camera frustum** (`get_strokes_in_camera_frustrum()`), not all strokes. This means strokes that are mostly off-screen but extend into the cursor area may not be caught
- There is a known FIXME in `_undo_delete_stroke`: undone strokes are appended at the back of the draw order, not restored to their original z-index position

## Decision Guidance
The eraser is functional but the whole-stroke deletion model is a significant constraint — it is common to want to partially erase a stroke. Implementing partial erasure would require splitting a `BrushStroke` into two strokes at the erased segment, which is a moderate but well-scoped addition. If your use case involves heavy erasing of detail, this limitation will be felt frequently.
