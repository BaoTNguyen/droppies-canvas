# Rendering & Performance

## What It Does
Controls how strokes are rendered visually: anti-aliasing method, brush cap rounding, viewport scaling, and frame rate limits. These settings let the user trade visual quality against performance, and adapt to HiDPI displays.

## How to Use It
- **Settings > Rendering** to configure:
  - **Anti-aliasing**: None / OpenGL Hint / Texture Fill (requires restart)
  - **Brush Rounding**: Flat caps / Rounded caps (requires restart)
  - **Foreground FPS**: Target FPS when app is focused (default 144)
  - **Background FPS**: Target FPS when app is unfocused (default 10)
- **Settings > Appearance > UI Scale**: Auto (platform-appropriate) or Custom (user-specified float)

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| BrushStroke | `lorien/BrushStroke/BrushStroke.gd` | 32–48 | Applies AA mode and cap rounding to the Line2D on ready |
| BrushStrokeTexture | `lorien/BrushStroke/BrushStrokeTexture.gd` | — | Generates the texture used for TEXTURE_FILL AA mode |
| InfiniteCanvas | `lorien/InfiniteCanvas/InfiniteCanvas.gd` | 54–57 | Connects camera signals to all child cursors on ready |
| Main | `lorien/Main.gd` | 100–110 | Sets foreground/background FPS on focus change |
| Main | `lorien/Main.gd` | 532–563 | `_on_scale_changed` and `_get_platform_ui_scale` for HiDPI |
| BrushStroke | `lorien/BrushStroke/BrushStroke.gd` | 53–60 | Visibility culling via `VisibilityNotifier2D` |
| Config | `lorien/Config.gd` | 19–27 | All rendering defaults |

## Architecture Notes
**Anti-aliasing modes** (set per-stroke at instantiation time, require restart):
- `NONE`: raw `Line2D` with no AA
- `OPENGL_HINT`: sets `_line2d.antialiased = true` — relies on the GPU driver's line AA (quality varies by platform)
- `TEXTURE_FILL` (default): sets `_line2d.texture` to a pre-generated gradient texture — approximates AA by blending the stroke edges. Works consistently across all platforms

**Visibility culling**: Each `BrushStroke` has a `VisibilityNotifier2D` with a `rect` calculated from the stroke's bounding box. When the notifier reports `viewport_exited`, the stroke's `visible` is set to `false`. When it reports `viewport_entered`, `visible` is set to `true` and the stroke is added to the `GROUP_ONSCREEN` group. This is the primary performance optimization for large canvases — off-screen strokes incur zero render cost.

**FPS throttling**: `Main._notification` responds to `NOTIFICATION_WM_FOCUS_IN` and `NOTIFICATION_WM_FOCUS_OUT` to set `Engine.target_fps`. Default background FPS is 10 — enough to smoothly re-open the window but negligible CPU usage when Lorien is in the background.

**HiDPI scaling**: `Main._get_platform_ui_scale` detects macOS (`OS.get_screen_scale()`), Windows (DPI / 96), and Linux (heuristic based on screen dimensions). The scale is applied via `get_tree().set_screen_stretch(STRETCH_MODE_DISABLED, ...)` with the scale factor, setting `OS.min_window_size` to `Config.MIN_WINDOW_SIZE * scale`.

## Pros
- Visibility culling via `VisibilityNotifier2D` is a Godot-idiomatic and effective approach — large canvases with thousands of strokes remain interactive because off-screen strokes cost nothing to render
- Texture-fill AA mode works consistently across all platforms and GPU drivers, unlike the OpenGL hint which is driver-dependent
- FPS throttling in the background is thoughtful and reduces battery/CPU impact
- Platform-appropriate HiDPI detection covers macOS, Windows, and Linux with sensible fallbacks

## Cons / Limitations
- AA mode, brush rounding, and brush rounding require a restart because they are applied at stroke instantiation time — existing strokes in an open project are not updated when the setting changes (acknowledged in a comment in `SettingsDialog`)
- `VisibilityNotifier2D.rect` is set once at `refresh()` time using the stroke's bounding box; if a stroke is moved by the selection tool, the notifier rect is not updated — culling may become incorrect for moved strokes
- No LOD (level-of-detail): at very low zoom with thousands of strokes visible simultaneously, all strokes are rendered at full point density; no simplification is applied for distant view
- The viewport scale fix in `_on_window_resized` (re-setting `_viewport.set_size`) is a workaround for a Godot 3 quirk; it may cause a single-frame stutter on resize

## Decision Guidance
The performance architecture is well thought-out for the target use case (a single-user local drawing app). The visibility culling handles the most common performance scenario. The main gap for power users would be LOD on large canvases, but this is only relevant at scale. The VisibilityNotifier rect not updating on stroke move is a subtle bug worth fixing if move operations are frequently used.
