# Shape Tools (Line, Rectangle, Circle/Ellipse)

## What It Does
Three tools for drawing geometric primitives: a straight line, an axis-aligned rectangle, and an ellipse (or constrained circle). All three produce the same `BrushStroke` node type as the freehand brush — the shapes are rendered as polylines with the same pressure-width system, not as separate vector primitives.

## How to Use It
**Line Tool** (shortcut **L**)
- Click and drag to draw a straight line from anchor to cursor
- Hold **Shift** while dragging to snap the angle to the nearest 15° increment

**Rectangle Tool** (shortcut **R**)
- Click and drag to define the top-left to bottom-right bounding box of the rectangle
- Releases as four connected line segments

**Circle/Ellipse Tool** (shortcut **C**)
- Click and drag to define the bounding box; the ellipse fits inside it
- Hold **Shift** while dragging to constrain to a perfect circle

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| LineTool | `lorien/InfiniteCanvas/Tools/LineTool.gd` | 1–59 | Line drawing + 15° angle snapping |
| RectangleTool | `lorien/InfiniteCanvas/Tools/RectangleTool.gd` | 1–48 | 4-segment rectangle |
| CircleTool | `lorien/InfiniteCanvas/Tools/CircleTool.gd` | 1–89 | Ellipse / circle approximation |
| CanvasTool | `lorien/InfiniteCanvas/Tools/CanvasTool.gd` | — | Base class with `add_subdivided_line` helper |
| InfiniteCanvas | `lorien/InfiniteCanvas/InfiniteCanvas.gd` | 101–129 | `use_tool()` — disables optimizer for all shape tools |

## Architecture Notes
All shape tools reuse `BrushStroke` as their output type. Shapes do not store a "type" flag — they become ordinary polyline strokes once committed.

**Line**: On every `MouseMotion` event while dragging, the tool calls `remove_last_stroke_point()` to erase the preview tail, then re-adds it at the updated cursor position (or snapped position). Snapping uses `floor(angle / 15°) * 15°`. On release, `add_subdivided_line` replaces the two-point placeholder with a densely-subdivided polyline so that pressure taper looks correct on long lines.

**Rectangle**: On every `MouseMotion`, `remove_all_stroke_points()` discards the whole rectangle preview and redraws all four sides via `add_subdivided_line`. A small `2%` offset on corners prevents the closing-point overlap artifact that would make a visual "bump" where two lines share a vertex.

**Circle/Ellipse**: Pre-computes `sin[]` and `cos[]` lookup arrays at `_init()` for all 360°. During motion preview, steps every 15° (24 points). On final commit, steps every 4° (90 points) for a smoother final stroke. `r1` and `r2` are derived from the bounding box; `Shift` forces `r1 == r2`.

The stroke optimizer is explicitly **disabled** for all shape tools (`_use_optimizer = false` in `InfiniteCanvas.use_tool()`), ensuring no points are pruned from geometric strokes.

## Pros
- 15° snapping on the line tool is genuinely useful for technical diagrams
- Circle/ellipse pre-bakes trig lookups — no repeated `sin()`/`cos()` calls per frame during preview
- Two-resolution circle (15° preview, 4° final) balances interactivity with quality
- Shapes integrate with undo/redo, selection, copy/paste, and SVG export identically to brush strokes — no special-casing required

## Cons / Limitations
- **Shapes are permanently baked into polylines** — there is no way to later resize, rotate, or reshape a rectangle or circle. Once committed they are indistinguishable from freehand strokes
- Rectangle has no Shift-to-square constraint (unlike Circle which has Shift-to-circle)
- The circle's step size during final commit is fixed at 4°, giving a 90-point polygon. At very large sizes the approximation looks slightly faceted; at small sizes it's overkill
- No polygon tool, triangle tool, or arrow tool
- Subdivided line implementation is in `CanvasTool` base class but is undocumented — subtle bugs there would affect all three tools

## Decision Guidance
The shape tools cover the most common geometric primitives adequately for a sketching app. The key limitation is the bake-on-commit design: shapes cannot be resized after drawing. If non-destructive editing of shapes matters for your workflow, this would require a significant architectural change (storing shape parameters separately from the polyline output). For casual sketching and diagramming this is acceptable.
