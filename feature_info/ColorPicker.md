# Color Picker

## Summary
Infinipaint provides two simultaneously active color slots — a foreground color (used for brush strokes and shape outlines) and a background/fill color (used for shape fills). Users click either color swatch in the left toolbar to open a full color picker dialog, which also houses a named color palette system. Palettes can be created, renamed, and deleted; individual colors can be added or removed from the active palette. The right-click quick menu (PaintCircleMenu) shows the current palette's colors as a radial strip for rapid color switching without opening the picker dialog.

## How It Works
`DrawingProgram` exposes a `get_foreground_color_ptr()` and `ToolConfiguration::GlobalConfig` stores `foregroundColor` and `backgroundColor` as `Vector4f` RGBA values. The `Toolbar` class holds pointers `colorLeft` and `colorRight` that point to whichever color slot is being edited. `Toolbar::color_selector_left()` and `color_selector_right()` render the two swatch buttons; clicking one populates `colorLeft`/`colorRight` and opens the picker dialog via `color_palette()`. Palettes are stored in `Toolbar::PaletteData` as a `std::vector<Palette>` where each `Palette` holds a `std::vector<Vector3f>` of RGB triples; this is serialized to and loaded from disk by `Toolbar::save_palettes()` / `load_palettes()`. The `PaintCircleMenu` receives the current palette from the `Toolbar` each frame and renders it as a ring of color dots. The `EyeDropperTool` writes the sampled color back to whichever slot (`selectingStrokeColor` flag in `EyeDropperToolConfig`) is active.

## Code Locations
| Role | File | Lines / Symbol |
|------|------|----------------|
| Foreground/background color storage | `infinipaint-0.4.2/src/DrawingProgram/ToolConfiguration.hpp` | `GlobalConfig::foregroundColor`, `GlobalConfig::backgroundColor` |
| Toolbar color swatch & picker GUI | `infinipaint-0.4.2/src/Toolbar.hpp` | `Toolbar::color_selector_left()`, `Toolbar::color_selector_right()`, `Toolbar::color_palette()` |
| Palette persistence | `infinipaint-0.4.2/src/Toolbar.hpp` | `Toolbar::PaletteData`, `save_palettes()`, `load_palettes()` |
| Quick-menu color ring | `infinipaint-0.4.2/src/GUIStuff/Elements/PaintCircleMenu.hpp` | `PaintCircleMenu`, `Data::palette`, `Data::selectedColor` |
| Eyedropper tool | `infinipaint-0.4.2/src/DrawingProgram/Tools/EyeDropperTool.hpp` | `EyeDropperTool` |
| Eyedropper config | `infinipaint-0.4.2/src/DrawingProgram/ToolConfiguration.hpp` | `EyeDropperToolConfig::selectingStrokeColor` |

## User-Facing Pros
- **Two independent color slots**: Maintaining a foreground and a fill color simultaneously means users can switch between outline and fill drawing modes without repeatedly reopening the picker.
- **Named palettes**: Multiple saved palettes allow quick context switches (e.g., a "Brand Colors" palette alongside a "Warm Grays" palette) without manually re-entering hex values.
- **Radial quick menu access**: The right-click ring of palette colors enables one-gesture color switching mid-stroke without opening any dialog.
- **Eyedropper supports both slots**: `selectingStrokeColor` is togglable, so the eyedropper can sample color into either the foreground or fill slot without changing tools multiple times.

## User-Facing Cons / Limitations
- **No hex / HSL text input visible in code**: The picker stores colors as `Vector3f`/`Vector4f`; there is no evidence in the source of a hex code entry field, which frustrates users who know their brand colors numerically.
- **Palettes are local, not synced**: `PaletteData` is stored and loaded from disk by the local Toolbar; palettes are not part of the networked world state, so collaborators each maintain their own independent palette collections.
- **No alpha channel in palette swatches**: Palette colors are stored as `Vector3f` (RGB without alpha), so semi-transparent colors cannot be saved to a palette.
- **Default palette cannot be removed**: The code comment in `Toolbar::color_palette()` states the default palette cannot be deleted, which may frustrate users who want a clean custom setup.

## Decision Guidance
Keep this feature. Palettes and the quick-menu ring are effective UX patterns for a canvas drawing tool. The most impactful improvements are adding hex/HSL text input and syncing palette selections per-session (even just the "active palette" pointer) so collaborators share a consistent color context. Alpha-supporting palette entries are a lower priority unless annotation workflows (translucent highlights) are a primary use case.

## Related Features
- [BrushAndDrawingTools.md](BrushAndDrawingTools.md) — drawing tools consume the foreground/background colors
- [CanvasNavigation.md](CanvasNavigation.md) — right-click `PaintCircleMenu` also hosts the canvas rotation ring
- [RichTextEditing.md](RichTextEditing.md) — text color modifiers use the same RGBA color type
