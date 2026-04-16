# Grid Overlay

## What It Does
Renders an optional reference grid over the infinite canvas. The grid scales and repositions dynamically as the user pans and zooms, keeping grid lines/dots fixed in world space. Three patterns are available: dots, lines, or none (off). The grid color is automatically derived from the canvas background color.

## How to Use It
- Open **Settings > Appearance**
- Set **Grid Pattern** to Dots, Lines, or None
- Set **Grid Size** to control the spacing between dots/lines (default 25 px)
- The grid updates immediately in the canvas when settings are changed
- Grid color is always `canvas_background_color * 1.25` — slightly lighter than the background, not user-configurable separately

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| InfiniteCanvasGrid | `lorien/InfiniteCanvas/InfiniteCanvasGrid.gd` | 1–83 | All grid rendering via Godot's `_draw()` API |
| SettingsDialog | `lorien/UI/Dialogs/SettingsDialog.gd` | 155–166 | Emits `grid_size_changed` / `grid_pattern_changed` signals |
| Main | `lorien/Main.gd` | 332–339 | Routes signals from settings to `InfiniteCanvasGrid` |
| InfiniteCanvas | `lorien/InfiniteCanvas/InfiniteCanvas.gd` | 157–159 | `enable_grid()` pass-through |

## Architecture Notes
`InfiniteCanvasGrid` extends `Node2D` and uses Godot's `_draw()` callback to render the grid every time the camera moves or zooms. It connects to `zoom_changed` and `position_changed` signals from `PanZoomCamera` to call `update()` (Godot's trigger for re-drawing a `Node2D`).

**Dots pattern**: computes the start/end index in both axes from camera offset and viewport size, then draws `ceil(grid_size * 0.12)` px squares at each grid intersection. The dot size scales with the grid size.

**Lines pattern**: draws a series of vertical and horizontal `draw_line()` calls covering the visible viewport extent plus one unit of padding on each side to avoid clipping at the edge.

**Grid scaling with zoom**: `grid_size` is adjusted by `pow(zoom, 0.75)` — a sub-linear zoom response that keeps the grid visible at both close and far zoom levels without becoming too fine or too coarse. This is a well-chosen exponent.

The `set_grid_scale` method (called by `InfiniteCanvas.set_canvas_scale`) multiplies the internal `_grid_size` by the UI scale factor — the grid stays consistent across HiDPI displays.

## Pros
- Sub-linear zoom scaling (`pow(zoom, 0.75)`) is smart: grid dots don't disappear at low zoom or become overwhelming at high zoom
- Auto-derived grid color (background × 1.25) means the grid is always subtly visible regardless of canvas color, without any user configuration
- Immediate live preview when changing grid settings in the dialog (signals connected in real time)
- Three patterns (dots, lines, none) cover the most common reference grid needs

## Cons / Limitations
- **No snap-to-grid**: the grid is visual only — drawing tools do not snap to grid intersections. This significantly limits its usefulness for technical diagrams or aligned layouts
- Grid color is not user-configurable: the `1.25` multiplier produces a subtle tint, but on some canvas colors the grid may be nearly invisible or too prominent with no way to adjust
- The grid has no "show only at zoom levels above X" threshold — at very high zoom the grid can feel cluttered; at very low zoom it disappears to a uniform texture
- `set_grid_scale` accumulates multiplications (it does `_grid_size *= size` each time it's called) — if this is called multiple times without a reset, the grid size will be wrong

## Decision Guidance
The grid is a useful visual reference but its value is limited without snap-to-grid. If Lorien is being used for structured note-taking, diagrams, or aligned layouts, adding snap-to-grid for shape tools (at minimum) would greatly increase the grid's utility. The `set_grid_scale` accumulation bug is worth fixing regardless.
