# Canvas Export (Screenshot Tool)

## Summary
The Screenshot tool lets users define a rectangular region of the canvas and export it as a high-resolution image file in JPG, PNG, WEBP, or SVG format. After placing the capture rectangle, the user can resize it by dragging cyan corner handles and configure the output resolution (up to memory limits) and file format in a right-hand panel before triggering the export. The captured area reflects the actual canvas content, not just what is visible on screen, so exports can be at any resolution independent of the display. Transparent backgrounds are supported for PNG, WEBP, and SVG.

## How It Works
`ScreenshotTool` is a tool subclass that maintains a `ScreenshotControls` struct holding the capture rectangle as world-space floats (`rectX1`/`rectX2`/`rectY1`/`rectY2`), eight `SCollision::Circle` handles for dragging the boundary, and an `std::atomic<bool> setToTakeScreenshot` flag. When the user confirms export, `take_screenshot()` dispatches to either `take_screenshot_area_hw()` for raster formats or `take_screenshot_svg()` for SVG. The raster path renders the canvas content offscreen using the Skia GPU surface at the requested `imageSize` resolution, reads back pixel data, and encodes it using the appropriate Skia codec. The SVG path renders via a `SkSVGCanvas`. The tool configuration (`ToolConfiguration::ScreenshotToolConfig`) stores the last-used dimension size and format. The `MainProgram::takingScreenshot` flag temporarily hides the GUI overlay while the offscreen render is in progress.

## Code Locations
| Role | File | Lines / Symbol |
|------|------|----------------|
| Screenshot tool (all logic) | `infinipaint-0.4.2/src/DrawingProgram/Tools/ScreenshotTool.hpp` | `ScreenshotTool`, `ScreenshotControls`, `ScreenshotType` enum |
| Screenshot implementation | `infinipaint-0.4.2/src/DrawingProgram/Tools/ScreenshotTool.cpp` | `take_screenshot()`, `take_screenshot_area_hw()`, `take_screenshot_svg()` |
| Tool configuration persistence | `infinipaint-0.4.2/src/DrawingProgram/ToolConfiguration.hpp` | `ScreenshotToolConfig` |
| GUI overlay hide flag | `infinipaint-0.4.2/src/MainProgram.hpp` | `MainProgram::takingScreenshot`, `MainProgram::transparentBackground` |
| Toolbar menu entry | `infinipaint-0.4.2/src/Toolbar.hpp` | `Toolbar::top_toolbar()` (Menu -> Take Screenshot) |

## User-Facing Pros
- **Resolution-independent export**: The output resolution is set independently of screen resolution; users can export a small canvas region at 4K without needing a 4K monitor.
- **Transparent background option**: PNG, WEBP, and SVG exports support a transparent background toggle (`transparentBackground`), enabling compositing in external tools.
- **SVG vector export**: SVG output preserves vector shapes and text as scalable elements, not a rasterized bitmap, which is valuable for documentation or web use.
- **Adjustable region after initial placement**: The eight corner and edge handles allow fine-tuning the capture area without restarting the tool.
- **Aspect ratio is preserved automatically**: The resolution input is constrained to the capture rectangle's aspect ratio; the application recalculates the complementary dimension automatically.

## User-Facing Cons / Limitations
- **Grids are excluded from SVG**: The manual explicitly states that grids cannot be rendered in SVG exports, so grid-reliant diagrams cannot be exported as true vectors.
- **No batch/tiled export**: There is a single capture rectangle per export; exporting a very large canvas in sections requires multiple manual exports.
- **Memory is the only advertised limit**: The tool documentation warns that "extremely large images" may crash the image viewer, and there is no built-in size cap or warning before export. Very large raster exports can exceed GPU memory.
- **No export-to-clipboard**: Export always writes to a file via `screenshotSavePath`; there is no path to paste the result directly into another application.
- **Tool is not accessible during collaboration restrictions**: `MainProgram::takingScreenshot` hides the GUI globally, which could interfere with network keepalive if the export is slow.

## Decision Guidance
Keep this feature. The raster-export path via Skia GPU offscreen rendering is well-designed and resolution-independent. The SVG path is a meaningful differentiator. The most impactful improvement is adding a maximum pixel-count guard with a user warning before large exports to avoid silent memory exhaustion. Consider adding clipboard export as a convenience shortcut for smaller captures.

## Related Features
- [CanvasNavigation.md](CanvasNavigation.md) — the capture rectangle is positioned in world coordinates using the same `CoordSpaceHelper`
- [GridSystem.md](GridSystem.md) — grids are explicitly excluded from SVG exports
- [LayerManagement.md](LayerManagement.md) — all visible layers are composited into the export
