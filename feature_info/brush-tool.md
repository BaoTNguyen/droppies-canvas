# Brush Tool (Freehand Drawing)

## What It Does
The primary drawing tool. The user holds the left mouse button and draws a freehand stroke. Pen tablet pressure controls line width in real time, producing thick-to-thin tapered strokes. A point optimizer runs during drawing to reduce the number of stored points without visibly affecting stroke quality. Single clicks produce a dot instead of being discarded.

## How to Use It
- Press **B** (default) or click the brush icon in the toolbar to activate
- **Left-click drag** to draw a stroke
- Stroke width varies with stylus pressure; mouse clicks default to full pressure
- **Single click** (no drag) places a small dot (3-point synthetic stroke)
- **Brush size slider** in the toolbar controls the base width (default 12 px)
- Pressure sensitivity multiplier is configurable in Settings > General

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| BrushTool | `lorien/InfiniteCanvas/Tools/BrushTool.gd` | 1–95 | Input handling, pressure sampling, dot detection |
| BrushStroke | `lorien/BrushStroke/BrushStroke.gd` | 1–171 | Data model + Line2D renderer for a single stroke |
| BrushStrokeOptimizer | `lorien/BrushStroke/BrushStrokeOptimizer.gd` | 1–58 | Removes redundant points during drawing |
| InfiniteCanvas | `lorien/InfiniteCanvas/InfiniteCanvas.gd` | 196–262 | `start_stroke`, `add_stroke_point`, `end_stroke` orchestration + undo/redo commit |
| pressure_curve.tres | `lorien/InfiniteCanvas/pressure_curve.tres` | — | Godot Curve resource shaping pressure response |

## Architecture Notes
`BrushTool` samples `InputEventMouseMotion.pressure` every frame while `performing_stroke` is true. The raw pressure passes through a configurable `Curve` resource (`pressure_curve.tres`) and is multiplied by a user-set sensitivity scalar (default 1.5). The result drives the width curve of a `Line2D` node (one per stroke). Each stroke caps at `MAX_POINTS` (1,000) and auto-splits — a new `BrushStroke` is started seamlessly so the user never notices.

The optimizer (`BrushStrokeOptimizer`) runs on every new point and removes a point if it is both within 2 px of the previous point **and** the direction change is less than 1°. This dual-condition filter prevents over-reduction on sharp corners. Points more than 100 px from the previous point always pass through (protects fast strokes from being thinned). The optimizer reports how many points it removed (printed to console).

Pressure values are stored as integers in `[30, 255]` (8-bit, clamped from `MIN_PRESSURE_VALUE`). Spike smoothing caps the change between consecutive pressure samples at `MAX_PRESSURE_DIFF` (20) to suppress hardware spikes (a known Linux stylus issue).

On `end_stroke`, the final stroke is added to the scene tree and registered in `UndoRedo` so a single Ctrl+Z removes the entire stroke.

## Pros
- Pressure-sensitive width with a configurable response curve — feels natural with a tablet
- Spike smoothing prevents jarring artifacts on Linux where pressure spikes are common
- The optimizer is effective: complex strokes routinely see 40–60% point reduction with no visible quality loss
- Auto-split at 1,000 points works seamlessly; the user never sees a break
- Dot detection handles the "tap to place a point" use case cleanly rather than discarding tiny strokes

## Cons / Limitations
- **No mouse smoothing / stabilizer**: jittery mouse input produces jagged strokes; there is no "lazy follower" or moving-average stabilization
- Optimizer thresholds (`ANGLE_THRESHOLD = 1.0°`, `DISTANCE_THRESHOLD = 2.0 px`) are hardcoded constants — no per-user tuning
- The `TODO` comment in `PanZoomCamera` notes the distance threshold should scale with zoom level but currently does not; at high zoom, too many points are kept; at low zoom, strokes may be over-simplified
- Pressure is lost in SVG export (see `svg-export.md`) — exported strokes all render at `stroke-width:2`
- No tilt/rotation data is captured from the stylus, only pressure

## Decision Guidance
The brush tool is the strongest part of Lorien. The pressure system works well for tablet users. The main missing feature for serious use is stroke stabilization — without it, mouse-only users will struggle with precision. This is worth adding as a smoothing window on the `_current_position` before it's fed to `add_stroke_point`.
