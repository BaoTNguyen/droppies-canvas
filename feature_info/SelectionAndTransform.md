# Selection and Transform

## Summary
Users can select one or more canvas objects using a rectangular rubber-band marquee (Rectangle Select) or a freehand lasso (Lasso Select), then move, scale, and rotate the selection interactively. The Edit/Cursor tool allows single-object selection by clicking. Selected objects can be copied, cut, and pasted; paste places objects at the cursor's current world position. Objects can be pushed to the front or back of the drawing order. After any transform, the changes are committed as a networked update and pushed to the undo stack.

## How It Works
`DrawingProgramSelection` is a member of `DrawingProgram` and manages the selected set as a `std::vector<CanvasComponentContainer::ObjInfo*>`. Selection queries use the BVH cache (`DrawingProgramCache`) to efficiently find objects whose camera-space bounding boxes intersect the selection collider, avoiding linear scans of all canvas components. The transform state machine inside `DrawingProgramSelection` tracks three operations — `TRANSLATE`, `SCALE`, and `ROTATE` — each with its own data struct. A `CoordSpaceHelperTransform` encodes the current transform relative to the selection's initial AABB. When the user releases input, `commit_transform_selection()` serializes the new `CoordSpaceHelper` for each selected component and sends it to the server, where it is applied to all clients. The `RectSelectTool` and `LassoSelectTool` build the selection collider and feed it into `DrawingProgramSelection::add_from_cam_coord_collider_to_selection()`. Shift and Alt modifier keys add to or subtract from the current selection.

## Code Locations
| Role | File | Lines / Symbol |
|------|------|----------------|
| Selection state machine | `infinipaint-0.4.2/src/DrawingProgram/DrawingProgramSelection.hpp` | `DrawingProgramSelection`, `TransformOperation` enum |
| Rectangle select tool | `infinipaint-0.4.2/src/DrawingProgram/Tools/RectSelectTool.hpp` | `RectSelectTool` |
| Lasso select tool | `infinipaint-0.4.2/src/DrawingProgram/Tools/LassoSelectTool.hpp` | `LassoSelectTool` |
| Edit/click tool | `infinipaint-0.4.2/src/DrawingProgram/Tools/EditTool.hpp` | `EditTool` |
| Transform coordinate helper | `infinipaint-0.4.2/src/CoordSpaceHelperTransform.hpp` | `CoordSpaceHelperTransform` |
| BVH-based collision lookup | `infinipaint-0.4.2/src/DrawingProgram/DrawingProgramCache.hpp` | `DrawingProgramCache::get_front_object_colliding_with_in_editing_layer()` |
| Clipboard data model | `infinipaint-0.4.2/src/MainProgram.hpp` | `MainProgram::Clipboard` |
| Transform send to network | `infinipaint-0.4.2/src/DrawingProgram/DrawingProgram.hpp` | `DrawingProgram::send_transforms_for()` |

## User-Facing Pros
- **Movable rotation center**: The user can drag the larger orange circle handle to reposition the pivot point before rotating, enabling rotation around a custom center (e.g., the corner of an object).
- **Additive/subtractive selection**: Shift adds objects to the current selection and Alt removes objects, matching standard desktop application conventions without requiring deselect-and-restart.
- **Lasso tool for irregular areas**: The freehand lasso avoids selecting unwanted neighbors when objects are closely packed, unlike a rectangular marquee.
- **Paste-at-cursor**: Paste repositions objects to the current cursor world position while preserving their size and relative arrangement, making it practical to duplicate content in different parts of the canvas.
- **BVH-accelerated hit testing**: Selection queries run against the same BVH tree used for rendering, so they scale to large canvases without per-object linear scans.

## User-Facing Cons / Limitations
- **No group/ungroup**: Selected objects cannot be permanently grouped into a single compound object; every transform is applied individually to each selected item.
- **Stroke color change through selection is limited**: `DrawingProgramSelection` tracks a `StrokeColorChangeData` struct that can change stroke color for all selected items, but there is no equivalent bulk fill-color change.
- **Selection is layer-aware but can be confusing**: The `LayerSelector` controls whether selection queries span all visible layers or only the editing layer; switching modes mid-workflow without explicit guidance can result in unexpected misses.
- **No object alignment or distribution**: There are no "align left edges" or "distribute horizontally" commands for multiple selected objects.

## Decision Guidance
Keep this feature. The BVH-backed selection and the networked transform commit are well-designed for the collaborative model. The most impactful missing capability is object alignment/distribution, which is a common ask in any canvas application and would be achievable by operating on the existing `selectedSet` without architectural changes.

## Related Features
- [BrushAndDrawingTools.md](BrushAndDrawingTools.md) — objects created by drawing tools become selection targets
- [LayerManagement.md](LayerManagement.md) — layer selector affects which objects can be selected
- [UndoRedo.md](UndoRedo.md) — transforms are undoable
- [OnlineCollaboration.md](OnlineCollaboration.md) — transforms are sent to the server and applied to all clients
