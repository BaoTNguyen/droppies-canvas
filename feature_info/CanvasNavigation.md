# Canvas Navigation

## Summary
Infinipaint renders on a virtually infinite canvas that users can pan, zoom, and rotate freely. Panning is done by holding the middle mouse button (or Spacebar as a temporary shortcut), zooming by scroll wheel or a drag-zoom tool, and canvas rotation by dragging the outer ring of the right-click quick menu. Camera jumps to bookmarks and to other players' locations are animated with a configurable easing curve. Zoom is unbounded in principle, though the coordinate system uses a scaled scalar type to avoid floating-point precision loss at extreme magnifications.

## How It Works
`DrawCamera` holds the current viewport as a `CoordSpaceHelper c` (position, scale, rotation) plus a `viewingArea` vector. All navigation mutations call `DrawCamera::set_based_on_properties()` or `set_based_on_center()`, which update `c` directly or schedule a `SmoothMove` animation that interpolates over time in `update_main()`. Zoom speed is configurable via `Toolbar::scrollZoomSpeed` and `Toolbar::dragZoomSpeed`. The `PanCanvasTool` and `ZoomCanvasTool` are full tool subclasses like drawing tools, but the application also supports temporary mode switching: holding Space activates the pan tool momentarily (`TemporaryMoveToolSwitch::PAN`) and holding Z activates the zoom tool (`TemporaryMoveToolSwitch::ZOOM`), returning to the previous tool on key release. The right-click `PaintCircleMenu` exposes the rotation handle; its `currentRotationAngle` feeds directly into `DrawCamera`. `CoordSpaceHelper` coordinates are used throughout the renderer to map world positions to screen positions.

## Code Locations
| Role | File | Lines / Symbol |
|------|------|----------------|
| Camera state and animation | `infinipaint-0.4.2/src/DrawCamera.hpp` | `DrawCamera`, `SmoothMove`, `smooth_move_to()` |
| Coordinate space helper | `infinipaint-0.4.2/src/CoordSpaceHelper.hpp` | `CoordSpaceHelper` |
| Pan tool | `infinipaint-0.4.2/src/DrawingProgram/Tools/PanCanvasTool.hpp` | `PanCanvasTool` |
| Zoom tool | `infinipaint-0.4.2/src/DrawingProgram/Tools/ZoomCanvasTool.hpp` | `ZoomCanvasTool` |
| Temporary tool switch logic | `infinipaint-0.4.2/src/DrawingProgram/DrawingProgram.hpp` | `TemporaryMoveToolSwitch` enum, `tool_temporary_switch_update()` |
| Quick menu with rotation ring | `infinipaint-0.4.2/src/GUIStuff/Elements/PaintCircleMenu.hpp` | `PaintCircleMenu`, `currentRotationAngle` |
| Speed and easing config | `infinipaint-0.4.2/src/Toolbar.hpp` | `Toolbar::dragZoomSpeed`, `Toolbar::scrollZoomSpeed`, `jumpTransitionTime`, `jumpTransitionEasing` |
| Right-click popup origin | `infinipaint-0.4.2/src/Toolbar.hpp` | `Toolbar::rightClickPopupLocation`, `paint_popup()` |

## User-Facing Pros
- **Smooth animated jumps**: Camera transitions to bookmarks or other players' positions use a configurable cubic easing (`jumpTransitionEasing`) instead of teleporting, preserving spatial context.
- **Temporary tool shortcuts**: Space (pan) and Z (zoom) let users navigate without permanently switching tools, maintaining drawing flow for tablet users.
- **Canvas rotation**: The rotation ring in the quick menu allows tilting the canvas to a comfortable drawing angle, a feature typically found only in professional drawing tablets' driver software.
- **Zoom-level persistence**: Camera position, zoom, and rotation are saved with the file (`DrawCamera::save_file()`), so reopening a document restores the exact last viewing state.
- **Snap angles during rotation**: Dragging near the outer ring's boundary snaps to multiples of 45 degrees, making it easy to return to a clean upright orientation.

## User-Facing Cons / Limitations
- **Zoom direction is not user-configurable in-UI**: `flipZoomToolDirection` exists in `Toolbar` but is buried in settings rather than exposed as a prominent toggle, which can confuse users switching from tools with opposite drag conventions.
- **No minimap**: There is no overview thumbnail showing the user's location within the canvas relative to all content, making it hard to navigate a dense or large canvas without bookmarks.
- **Scroll-wheel zoom speed is global**: A single `scrollZoomSpeed` float applies everywhere; there is no way to set a slower speed for fine-zoom operations without changing the global setting.
- **Right-click rotation requires two right-clicks to dismiss**: The quick menu opens on right-click and closes on a second right-click, which is non-standard and can confuse first-time users expecting a context menu.

## Decision Guidance
Keep this feature set. The coordinate system design (`CoordSpaceHelper` decoupled from screen pixels) is the foundation that makes the infinite canvas possible and cannot be removed. If a minimap were added it would directly reduce the reliance on bookmarks for navigation orientation. The rotation feature is a meaningful differentiator for tablet artists and should be kept and potentially made more discoverable.

## Related Features
- [Bookmarks.md](Bookmarks.md) — bookmarks trigger `smooth_move_to()` camera jumps
- [OnlineCollaboration.md](OnlineCollaboration.md) — player-list jump also uses the camera animation system
- [GridSystem.md](GridSystem.md) — grid rendering depends on the current camera `CoordSpaceHelper`
- [ColorPicker.md](ColorPicker.md) — the right-click `PaintCircleMenu` also houses color palette and rotation
