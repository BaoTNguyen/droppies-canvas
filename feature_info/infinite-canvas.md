# Infinite Canvas

## What It Does
The canvas has no fixed boundaries. The user can pan, zoom, and draw anywhere without hitting an edge. Every project opens with the same infinite canvas, and the camera position and zoom level are saved per-project so the view is restored exactly when reopening a file.

## How to Use It
- **Scroll wheel** to zoom in/out (anchored to cursor position)
- **Middle mouse button drag** to pan
- **Ctrl + Middle mouse button drag** for smooth drag-zoom
- **Arrow keys** to pan in small increments (20 px per press, scaled by zoom)
- **+/- keyboard shortcuts** (`canvas_zoom_in` / `canvas_zoom_out`) to zoom
- **`H` key** (`center_canvas_to_mouse`) to warp the view so the cursor becomes the new screen center
- Camera position and zoom persist across save/load cycles

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| InfiniteCanvas | `lorien/InfiniteCanvas/InfiniteCanvas.gd` | 1–384 | Viewport container; owns all tools, strokes, and camera |
| PanZoomCamera | `lorien/InfiniteCanvas/PanZoomCamera.gd` | 1–134 | Camera2D subclass handling all pan/zoom input |
| ProjectMetadata | `lorien/ProjectManager/ProjectMetadata.gd` | 1–28 | Saves/restores camera_zoom, camera_offset_x/y per project |
| InfiniteCanvas scene | `lorien/InfiniteCanvas/InfiniteCanvas.tscn` | — | Scene tree wiring tools, camera, grid, strokes node |

## Architecture Notes
The canvas is a `ViewportContainer` containing a `Viewport`. All strokes live as child nodes of a `Node2D` named `Strokes` inside that viewport. A `Camera2D` (`PanZoomCamera`) controls the view — panning adjusts `offset`, zooming adjusts `zoom` with the anchor math done manually to keep the cursor's world-space position fixed under the mouse. Zoom snaps to the nearest step of `ZOOM_INCREMENT` (1.1×, i.e. Krita-style geometric steps), clamped between 0.1× and 100×. Strokes outside the viewport frustum are hidden via `VisibilityNotifier2D` to avoid rendering cost.

## Pros
- Truly infinite workspace — no coordinate clipping or page boundaries anywhere in the code
- Zoom range is wide (0.1× to 100×) and snaps to clean geometric steps, so 1:1 is always reachable
- Cursor-anchored zoom is implemented correctly: world-space anchor stays fixed under the cursor during zoom
- Canvas position and zoom are saved into the project file's metadata, so every file remembers exactly where you left off
- Background FPS drops to a configurable value (default 10) when the window loses focus, conserving CPU

## Cons / Limitations
- No minimap or overview mode; if you lose content by scrolling far, there is no "fit all strokes to view" button
- Keyboard panning increment is a fixed 20 px regardless of zoom level — at high zoom it barely moves; at low zoom it jumps wildly
- The viewport `size` is set to `OS.window_size` on ready but relies on a `_on_window_resized` callback to avoid stretching; on rapid resize events this can produce a single-frame stutter
- No coordinate display showing the actual world-space position of the cursor (only camera offset is shown in the statusbar)

## Decision Guidance
The infinite canvas is the core primitive of Lorien — every other feature depends on it. The implementation is clean and the zoom math is correct. The main gap worth addressing is the lack of a "zoom to fit all content" shortcut, which becomes a usability problem once a canvas has strokes scattered far apart.
