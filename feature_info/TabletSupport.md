# Tablet Support

## Summary
Infinipaint has first-class support for drawing tablets with pressure-sensitive pens. Pen pressure dynamically scales the brush stroke width in real time, and pen proximity detection can optionally suppress mouse-movement interference while the pen is hovering. Tablet button mappings are configurable: by default, pen button 1 maps to middle-click (pan) and pen button 2 maps to right-click. A time-based stroke-smoothing system reduces the wobble that inexpensive tablets produce. Users can also configure a minimum brush size floor so pressure-sensitive strokes never become invisible.

## How It Works
SDL3's pen event API (`SDL_pen.h`) supplies pressure values and proximity events. Inside `BrushTool::tool_update()`, the current pen pressure is read and fed into a time-windowed smoothing queue (`penSmoothingData`) — a `std::deque<SmoothingPoint>` where each entry has a pressure value and a timestamp. The smoothed pressure value is computed by averaging entries within the `smoothingSamplingTime` window, then applied to scale the stroke's `penWidth`. All tablet parameters live in `Toolbar::TabletOptions`: `pressureAffectsBrushWidth`, `smoothingSamplingTime`, `middleClickButton`, `rightClickButton`, `ignoreMouseMovementWhenPenInProximity`, `brushMinimumSize`, and `zoomWhilePenDownAndButtonHeld`. These are accessible from Menu → Settings → Tablet.

## Code Locations
| Role | File | Lines / Symbol |
|------|------|----------------|
| Tablet configuration | `infinipaint-0.4.2/src/Toolbar.hpp` | `Toolbar::TabletOptions` struct |
| Pressure smoothing queue | `infinipaint-0.4.2/src/DrawingProgram/Tools/BrushTool.hpp` | `BrushTool::penSmoothingData`, `SmoothingPoint` |
| Pressure application in stroke | `infinipaint-0.4.2/src/DrawingProgram/Tools/BrushTool.cpp` | `BrushTool::tool_update()` |
| SDL pen event intake | `infinipaint-0.4.2/src/main.cpp` | SDL3 pen event handling (SDL_PENEVENT) |
| Pen proximity suppress flag | `infinipaint-0.4.2/src/InputManager.hpp` | `InputManager::hideCursor` (used in `BrushTool::tool_update()`) |
| Eraser tip detection | `infinipaint-0.4.2/src/DrawingProgram/Tools/BrushTool.cpp` | eraser-tip event handling |

## User-Facing Pros
- **Per-stroke pressure smoothing**: The time-window smoothing queue removes jitter from low-quality tablets without introducing artificial lag on high-quality tablets — the window size is user-configurable, not hardcoded.
- **Configurable button mapping**: Both tablet pen buttons can be independently reassigned to middle-click or right-click, accommodating different pen ergonomics and user preferences.
- **Pen proximity suppression**: `ignoreMouseMovementWhenPenInProximity` prevents the mouse cursor from interfering with pen input when the pen is close to but not touching the tablet surface, avoiding phantom strokes.
- **Minimum brush size floor**: `brushMinimumSize` ensures that even at minimum pressure a stroke remains visible, avoiding the frustration of strokes that disappear entirely with light touch.
- **Automatic eraser-tip detection**: SDL3 reports eraser-end proximity events and the brush tool switches to the eraser tool automatically when the pen is flipped, matching the behavior users expect from the hardware.

## User-Facing Cons / Limitations
- **No tilt support**: Pen tilt data exposed by SDL3 is not used; stroke width and angle are purely pressure-driven, so tilt-sensitive calligraphy or hatching effects are not possible.
- **Pressure curve is not customizable**: The pressure-to-width mapping is linear (scaled by the smoothed pressure value); there is no curve editor to apply a gamma or S-curve response.
- **Zoom while pen down requires button hold**: `zoomWhilePenDownAndButtonHeld` enables zoom during pen contact only when a button is held, which can be awkward for users who habitually zoom with a button without lifting the pen.
- **Settings not per-document**: `TabletOptions` is saved in the global application config, not per canvas file, so tablet calibration set for one project applies globally.

## Decision Guidance
Keep this feature. Tablet support is a core requirement for the target drawing audience. The tilt-based stroke variation is the most artistically valuable missing capability and would require changes only in `BrushTool::tool_update()` (reading tilt from the SDL pen event) and `BrushStrokeCanvasComponent` (storing angle per point). A pressure curve editor is a medium-complexity enhancement with high user-satisfaction impact.

## Related Features
- [BrushAndDrawingTools.md](BrushAndDrawingTools.md) — pressure data feeds directly into stroke width computation
- [CanvasNavigation.md](CanvasNavigation.md) — tablet button assignments control pan/zoom navigation
