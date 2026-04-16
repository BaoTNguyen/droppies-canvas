# SVG Export

## What It Does
Exports the current project's strokes to a `.svg` file. The SVG includes a background rectangle and all strokes as `<polyline>` elements. The output is scaled to exactly contain all strokes, with a 2.5% margin on each side.

## How to Use It
- **Ctrl+E** or **Main Menu > Export > SVG**
- A file dialog appears pre-filled with `lorien.svg`
- Choose a save location and confirm
- The resulting `.svg` opens in any SVG viewer or vector editor

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| SvgExporter | `lorien/Misc/SvgExporter.gd` | 1–75 | Entire SVG export implementation |
| Main | `lorien/Main.gd` | 480–495 | Wires the export dialog and calls `SvgExporter.export_svg` |

## Architecture Notes
`SvgExporter.export_svg` performs a single-pass scan of all strokes to calculate the canvas bounding box (`min_dim`, `max_dim`). A 2.5% margin is added on all sides. It then writes:

1. `<svg>` header with `viewBox` set to the computed bounding box
2. `<rect>` for the background using the canvas background color
3. One `<polyline>` per stroke with `fill:none` and a fixed `stroke-width:2`

Points include the stroke's `global_position` offset (for moved strokes from the selection tool). The file is written using `File.store_string` line by line and flushed before closing.

The export runs synchronously on the main thread. For large canvases this can cause a momentary freeze. The time taken is printed to the console.

## Pros
- Clean, minimal SVG output — standards-compliant and opens correctly in Inkscape, browsers, and design tools
- The bounding box auto-crop means the SVG is tightly sized around the content, not an arbitrary canvas size
- Global position offset is correctly applied to moved strokes — copy/pasted content that was repositioned exports at the right location
- Implementation is only 75 lines — easy to read and modify

## Cons / Limitations
- **Pressure / variable stroke width is lost**: all polylines export with `stroke-width:2` regardless of the brush size or pressure data. The `TODO` at the top of the file explicitly notes this as missing
- **Brush size is ignored**: a stroke drawn at size 50 and a stroke drawn at size 2 look identical in the SVG
- **No alpha**: colors are exported as RGB hex (no transparency, consistent with the file format)
- **No layer separation**: all strokes are in a flat list with no grouping or layering in the SVG
- **Synchronous execution** on main thread: exporting a large canvas with thousands of strokes will freeze the UI until complete
- Only SVG is supported — no PNG, PDF, or other raster/vector formats

## Decision Guidance
SVG export exists and produces valid output, but the loss of stroke width/pressure information makes it unsuitable for cases where stroke weight variation matters (e.g., calligraphic notes, technical annotations). If visual fidelity in export is important, implementing variable `stroke-width` using pressure data per segment is the essential next step. Raster (PNG) export would also be straightforward via `InfiniteCanvas.take_screenshot()` which already calls `_viewport.get_texture().get_data()`.
