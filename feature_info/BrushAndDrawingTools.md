# Brush and Drawing Tools

## Summary
Infinipaint provides a suite of freehand and shape drawing tools that users can switch between from a toolbar. The primary tool is a freehand brush that renders pressure-sensitive, smoothed strokes for both mouse and tablet input. Additional tools let users draw straight lines, ellipses, and rectangles, each with configurable stroke width, fill/outline modes, and color. An eraser tool removes entire canvas components on contact. All stroke sizes are expressed relative to the current zoom level rather than in absolute pixels, so objects remain visually consistent as the user zooms in and out.

## How It Works
Each tool is a subclass of `DrawingProgramToolBase` and is owned by `DrawingProgram` as a `std::unique_ptr<DrawingProgramToolBase> drawTool`. On every frame, `DrawingProgram::update()` dispatches input events to the active tool via `tool_update()`. When a stroke is finished the tool calls into `DrawingProgramLayerManager` to commit the new `CanvasComponentContainer` object (a `BrushStrokeCanvasComponent`, `RectangleCanvasComponent`, `EllipseCanvasComponent`, or similar) to the currently-edited layer and pushes a corresponding `WorldUndoAction`. Tool configuration (widths, fill modes, round caps) is persisted to JSON via `ToolConfiguration`. Pen pressure data arrives from SDL3's pen events and is applied inside `BrushTool::tool_update()` using a time-based smoothing queue (`penSmoothingData`).

## Code Locations
| Role | File | Lines / Symbol |
|------|------|----------------|
| Tool base interface | `infinipaint-0.4.2/src/DrawingProgram/Tools/DrawingProgramToolBase.hpp` | `DrawingProgramToolBase` |
| Brush tool logic | `infinipaint-0.4.2/src/DrawingProgram/Tools/BrushTool.cpp` | `BrushTool::tool_update()`, `commit_stroke()` |
| Brush tool header | `infinipaint-0.4.2/src/DrawingProgram/Tools/BrushTool.hpp` | `BrushTool`, `penSmoothingData` |
| Eraser tool | `infinipaint-0.4.2/src/DrawingProgram/Tools/EraserTool.hpp` | `EraserTool` |
| Line draw tool | `infinipaint-0.4.2/src/DrawingProgram/Tools/LineDrawTool.hpp` | `LineDrawTool` |
| Ellipse draw tool | `infinipaint-0.4.2/src/DrawingProgram/Tools/EllipseDrawTool.hpp` | `EllipseDrawTool` |
| Rectangle draw tool | `infinipaint-0.4.2/src/DrawingProgram/Tools/RectDrawTool.hpp` | `RectDrawTool` |
| Tool configuration/persistence | `infinipaint-0.4.2/src/DrawingProgram/ToolConfiguration.hpp` | `ToolConfiguration`, `BrushToolConfig`, `EraserToolConfig` |
| Canvas component types | `infinipaint-0.4.2/src/CanvasComponents/CanvasComponentType.hpp` | `CanvasComponentType` enum |
| Brush stroke component | `infinipaint-0.4.2/src/CanvasComponents/BrushStrokeCanvasComponent.hpp` | `BrushStrokeCanvasComponent` |
| Active tool dispatch | `infinipaint-0.4.2/src/DrawingProgram/DrawingProgram.hpp` | `DrawingProgram::switch_to_tool()`, `drawTool` |

## User-Facing Pros
- **Tablet pressure sensitivity**: Stroke width scales with pen pressure in real time, including a configurable smoothing time (`TabletOptions::smoothingSamplingTime`) that prevents jittery strokes on inexpensive tablets.
- **Zoom-relative sizing**: All brush/eraser/shape widths are stored as a fraction of the viewport, so switching zoom levels never forces the user to rescale their tool size manually.
- **Shift-snapping on geometric tools**: Line, ellipse, and rectangle tools snap to common angles / square proportions when Shift is held, speeding up precise diagram work.
- **Round-cap option**: Brush and line tools offer a `hasRoundCaps` toggle, letting users match the aesthetic of existing strokes when switching brush styles.
- **Eraser granularity is object-based**: The eraser removes complete vector objects rather than painting transparency, which keeps the underlying data model clean for collaboration and undo.

## User-Facing Cons / Limitations
- **Eraser cannot erase partial strokes**: Because it deletes entire `CanvasComponent` objects, it is impossible to remove only part of a brush stroke. Users must redraw the remaining portion.
- **Minimum distance threshold is hardcoded**: `BrushTool` uses a compile-time constant `MINIMUM_DISTANCE_TO_NEXT_POINT = 0.002f`; very slow, deliberate strokes at high zoom can feel truncated if points are too close.
- **No brush texture or opacity blending**: All brush strokes render as solid-color paths via Skia; there is no support for textured brushes, opacity jitter, or watercolor-style wet edges.
- **Fill color applies to shapes only**: The secondary color slot drives shape fills but has no analogue for gradients or patterns — fills are flat RGBA only.

## Decision Guidance
Keep this feature as the core drawing capability of the application. It is the primary user interaction surface. The object-eraser limitation is an intentional design trade-off that simplifies network synchronization; if partial-stroke erasing is needed it would require switching from a vector-object model to a raster or segment-based model, which is a major architectural change. Consider the smoothing parameters and minimum-distance threshold as tuning candidates before any UI-level feature work.

## Related Features
- [LayerManagement.md](LayerManagement.md) — all drawn components land in a specific layer
- [UndoRedo.md](UndoRedo.md) — each committed stroke pushes an undo action
- [ColorPicker.md](ColorPicker.md) — foreground and fill colors feed into drawing tools
- [SelectionAndTransform.md](SelectionAndTransform.md) — drawn objects can be selected and moved after placement
