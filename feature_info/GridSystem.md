# Grid System

## Summary
Users can overlay one or more configurable reference grids on the canvas to guide drawing and alignment. Four grid types are available: circle points, square points, square lines, and horizontal lines. Each grid has independent settings for cell size, color, opacity, optional bounds (to restrict the grid to a rectangular region), subdivisions, offset position, and a toggle for showing coordinate labels. Grids can be shown in front of or behind canvas content, and multiple grids can coexist simultaneously. Grid state is synchronized in collaborative sessions.

## How It Works
`GridManager` owns a `NetworkingObjects::NetObjOwnerPtr<NetworkingObjects::NetObjOrderedList<WorldGrid>>` — a networked list of `WorldGrid` structs. Each `WorldGrid` stores its configuration and implements `draw()`, which computes the visible grid extent from the current `DrawCamera` position and renders via Skia runtime-effect shaders (`SkRuntimeEffect`) for each grid type (`circlePointEffect`, `squarePointEffect`, `squareLinesEffect`, `horizontalLinesEffect`). Shader uniforms are populated from a `ShaderData` struct that encodes grid scale, closest grid point to the camera, and subdivision levels. `GridManager::draw_back()` and `draw_front()` are called from `World::draw()` at the appropriate z-order. The `GridModifyTool` provides interactive dragging of a grid's position and bounds on the canvas. The Toolbar's `grid_menu()` method renders the settings panel.

## Code Locations
| Role | File | Lines / Symbol |
|------|------|----------------|
| Grid data model | `infinipaint-0.4.2/src/WorldGrid.hpp` | `WorldGrid`, `GridType` enum, `ShaderData` |
| Grid manager (list + draw) | `infinipaint-0.4.2/src/GridManager.hpp` | `GridManager`, `draw_back()`, `draw_front()`, `draw_coordinates()` |
| Grid manager implementation | `infinipaint-0.4.2/src/GridManager.cpp` | `GridManager::add_default_grid()`, `finalize_grid_modify()` |
| Interactive grid modify tool | `infinipaint-0.4.2/src/DrawingProgram/Tools/GridModifyTool.hpp` | `GridModifyTool`, `set_grid()` |
| Toolbar grid panel | `infinipaint-0.4.2/src/Toolbar.hpp` | `Toolbar::grid_menu()`, `GridMenu` struct |
| World grid data (world.cpp) | `infinipaint-0.4.2/src/World.cpp` | `WorldGrid::register_class()` |

## User-Facing Pros
- **Multiple simultaneous grids**: Users can stack different grid types (e.g., a square-line grid underneath a circle-point grid) for complex alignment needs, with independent color, opacity, and bounds per grid.
- **GPU shader rendering**: All four grid types are rendered with Skia runtime-effect GLSL shaders rather than CPU-generated line lists, so the grid remains performant even at high canvas zoom levels where many grid lines would be visible.
- **Bounded grids**: The optional `bounds` (an `SCollision::AABB`) restricts a grid to a sub-rectangle of the canvas, enabling page-like regions within the infinite canvas.
- **Coordinate label display**: `showCoordinates = true` draws canvas-space coordinate values along grid axes, which is useful for technical diagrams and reference drawings.
- **Collaborative sync**: Grid configuration is part of the networked world state, so all collaborators share the same grids without any manual setup.

## User-Facing Cons / Limitations
- **No grid snapping**: Despite the visual grid, drawn objects do not snap to grid intersections. The grid is purely cosmetic — it cannot constrain input.
- **Grid settings UI is non-obvious**: Grid creation and modification flow through `Toolbar::grid_menu()` and a separate `GridModifyTool` modal; new users may not discover that the tool exists to interactively reposition grids.
- **SVG export disables grids**: The screenshot tool's documentation explicitly states grids cannot be displayed in SVG exports.
- **No isometric or hexagonal grid type**: The four available types do not include isometric or hexagonal patterns, which limits the application for certain design workflows.

## Decision Guidance
Keep this feature. The shader-based rendering is a good technical foundation. Grid snapping is the single most-requested missing capability in tools of this type and would significantly increase the grid's utility. Isometric and hexagonal grid types could be added by writing new Skia shader programs following the existing pattern without architectural changes.

## Related Features
- [CanvasNavigation.md](CanvasNavigation.md) — grid rendering depends on `DrawCamera`'s `CoordSpaceHelper`
- [CanvasExport.md](CanvasExport.md) — grids are excluded from SVG exports
- [OnlineCollaboration.md](OnlineCollaboration.md) — grids are networked world objects
