# Droppies Canvas - Feature Analysis & Implementation Tracker

## Source Materials

- `initial_ideas.md` — rough feature notes
- `main_layout_for_dropper_canvas.png` — UI layout mockup showing toolbar, color palette, grid, settings panel, and canvas naming
- `MainSettings Sample.png` — settings panel mockup with grid options (Off/Lines/Dots), width slider, box ratio, and background color presets (Custom, Default, Light, Blueprint)
- `infinipaint.png` — reference screenshot of InfiniPaint showing left toolbar, brush panel, right-click radial menu, and freehand drawing

## Reference Source Code

| App | Branch | Language/Framework | Key Strength |
|-----|--------|--------------------|--------------|
| Excalidraw | `excalidraw` | TypeScript / React | Polished UI, rich shapes, collaboration, snapping |
| Lorien | `lorien` | GDScript / Godot 3.x | Velocity/pressure-sensitive brushes, lightweight |
| InfiniPaint | `infinipaint` | C++ / Skia | GPU grid rendering, radial menus, layers, P2P collab |

---

## Feature Breakdown

### 1. Drawing Tools (Pen, Eraser, Text, Shapes)

**Desired (from mockup):** "different items, pen, eraser, text, basic stuff lol"

| Feature | Excalidraw | Lorien | InfiniPaint |
|---------|-----------|--------|-------------|
| Freehand brush | `packages/excalidraw/components/App.tsx` (freedraw tool) | `Lorien-0.6.0/lorien/InfiniteCanvas/Tools/BrushTool.gd` | `infinipaint-0.4.2/src/DrawingProgram/Tools/` (BrushTool) |
| Eraser | Whole-element eraser tool | Whole-stroke eraser with bounding-box pre-test + segment-circle intersection (`EraserTool.gd`) | Object-level eraser |
| Text | Double-click WYSIWYG `<textarea>` overlay; binds to shapes | Not available | Text tool available |
| Shapes | Rectangle, diamond, ellipse, line, arrow (14 tools total) | Line (15deg snap), rectangle, circle/ellipse (shift-constrain); baked to polylines | Line, ellipse, rectangle with fill/outline modes |

**Implementation approach:**
- Start with freehand brush, eraser, and basic shapes (line, rectangle, ellipse)
- Lorien's approach of baking shapes to polylines is simpler for an initial version
- Text can be deferred to a later phase; Excalidraw's WYSIWYG overlay pattern is the gold standard
- Android: use `Canvas.drawPath()` for freehand, `Canvas.drawRect()`/`drawOval()` for shapes

---

### 2. Pen/Brush Settings

**Desired (from notes):**
- Pressure-sensitive pen
- Velocity-sensitive pen (regular vs inverted) — inspired by Lorien
- Fixed-width pen
- Custom presets
- Pen width with zoom scale or fixed scale toggle
- Velocity impact slider

| Feature | Excalidraw | Lorien | InfiniPaint |
|---------|-----------|--------|-------------|
| Pressure sensitivity | No (uses roughjs roughness only) | Yes — `InputEventMouseMotion.pressure`, configurable curve resource (`pressure_curve.tres`), spike smoothing (max diff of 20), 8-bit storage [30,255] | Yes — with `penSmoothingData` time-based smoothing queue |
| Velocity sensitivity | No | Mentioned as a feature concept; width is pressure-driven in code | No |
| Fixed width | Default behavior (no pressure) | Achievable by setting pressure multiplier to 0 | Round caps toggle, fixed size available |
| Brush size slider | Stroke width property per element | Toolbar slider (default 12px base) | Configurable stroke width |
| Lock size to zoom | No (strokes are vector objects) | No | Yes — `ToolConfiguration`, all sizes zoom-relative by default |
| Brush presets | No | No | `ToolConfiguration` persists settings to JSON |

**Implementation approach:**
- Lorien's pressure model is the best reference: sample `MotionEvent.getPressure()` on Android, apply a configurable curve, clamp spikes
- For velocity sensitivity: calculate velocity from consecutive `MotionEvent` timestamps and positions, map velocity to width via a configurable curve; "inverted" mode = faster stroke -> thicker line (opposite of default)
- A velocity impact slider controls how much velocity affects width (0 = no effect, 1 = full effect)
- Store pen presets as JSON objects: `{ type, width, pressureCurve, velocityImpact, zoomLocked }`
- Zoom-lock toggle: if locked, stroke width stays constant in screen space; if unlocked, width scales with canvas zoom

---

### 3. Canvas & Grid System

**Desired (from notes + mockups):**
- Infinite canvas
- Grid types: Off / Lines / Dots
- Grid settings: width of boxes, width of lines, box ratio (length:width 0.1-10)
- Dot grid: identical settings to box grid
- Background color + theme

**Settings panel mockup shows:**
- Three-way toggle: OFF | LINES | DOTS
- Width slider
- Box Ratio slider (value in px, range shown as 0.1-10, default 1)
- Background Color presets: Custom, Default, Light, Blueprint

| Feature | Excalidraw | Lorien | InfiniPaint |
|---------|-----------|--------|-------------|
| Infinite canvas | Yes — unbounded scrollX/scrollY | Yes — no fixed boundaries, camera state persists per-project | Yes — pan (Space), zoom (scroll/Z key), rotate (radial menu) |
| Grid lines | Dashed lines at configurable `gridSize` with bold lines every `gridStep` (`renderer/staticScene.ts`) | Dots or lines (configurable), zoom-aware, visual only | 4 types: circle points, square points, square lines, horizontal lines — GPU shader rendered (`GridManager.hpp`, `WorldGrid.hpp`) |
| Grid dots | Via gridStep config | Supported | Circle points and square points modes |
| Grid snap | Object snapping (8px, zoom-aware) but mutually exclusive with grid display | No snap (visual only) | No snap (visual only) |
| Background color | Configurable via appState | Configurable via settings | `ToolConfiguration::GlobalConfig` |
| Canvas rotation | No | No | Yes — via right-click radial menu, snaps to 45deg |

**Implementation approach:**
- Android infinite canvas: use `Matrix` for pan/zoom transforms on a custom `View`; track `translationX`, `translationY`, `scale`
- Grid rendering: draw in `onDraw()` — calculate visible grid lines/dots based on current viewport and zoom level
- For lines mode: draw vertical + horizontal lines at intervals of `cellWidth`; bold every N lines
- For dots mode: draw small circles at grid intersections
- Box ratio controls the aspect ratio of grid cells (width / height)
- InfiniPaint's GPU shader approach is ideal for performance but complex; start with simple Canvas draw calls, optimize later
- Background color presets: Custom (user picker), Default (dark ~#1a1a2e from mockup), Light (#f5f5f5), Blueprint (#1e3a5f)

---

### 4. UI Layout

**Desired (from mockup `main_layout_for_dropper_canvas.png`):**
- Top-left: "leave" button + canvas name text field
- Top-left below name: toolbar row (pen, eraser, text, etc.) with tool selector squares
- Below toolbar: color palette row (pink, orange, yellow, green variants, cyan, blue)
- Top-right: "settings" button
- Right side: "layers, grid toggle, grid sizing, canvas settings"
- Design emphasis: "logical", "intuitive", "meaningful"

**Desired (from notes):**
- Menu and tool placement — reference Concepts app for tool wheel movement vs side label

| Feature | Excalidraw | Lorien | InfiniPaint |
|---------|-----------|--------|-------------|
| Toolbar | Top-left shape buttons with keyboard shortcuts | Top bar: color swatch, brush size slider, tool icons | Left sidebar: tool buttons, color swatches |
| Settings panel | Right panel for element stats/properties | Dialog with 4 tabs (General, Appearance, Rendering, Keybindings) | Right panel for layer/grid/brush settings |
| Color picker | Inline color pickers for stroke/fill + eyedropper (`EyeDropper.tsx`) | Palette-based (built-in + custom), no hex input | Full picker with foreground/background slots, named palettes |
| Context menu | Standard right-click | Not documented | Radial `PaintCircleMenu` — color ring + rotation ring |
| Layers panel | No traditional layers | No layers | Full layer system: hierarchical, folders, visibility, opacity, 29 blend modes (`DrawingProgram/Layers/`) |

**Implementation approach:**
- Follow the mockup layout closely: top-left cluster for tools/colors, right side for settings/layers
- Use Android `ConstraintLayout` or Compose for responsive positioning
- Settings panel: slide-in panel from the right (as shown in `MainSettings Sample.png`)
- Color palette: horizontal row of preset color circles; tap to select, long-press for custom picker
- Layers panel can be deferred to a later phase — not in the initial mockup focus
- "Leave" button returns to a project list/home screen
- Canvas name is editable inline (tap to rename)

---

### 5. Settings Panel

**Desired (from `MainSettings Sample.png` mockup):**
```
SETTINGS
  Grid
    [OFF] [LINES] [DOTS]     <- three-way toggle, LINES selected
    Width                     <- slider
    Box Ratio          2 px   <- slider with value label
                         1    <- ratio value

  Background Color
    [Custom] [Default] [Light] [Blueprint]  <- circular preset buttons
```

**Implementation approach:**
- Overlay panel anchored to top-right settings icon
- Grid section: `SegmentedControl` / `MaterialButtonToggleGroup` for Off/Lines/Dots
- Width slider: controls line thickness (for lines mode) or dot radius (for dots mode)
- Box Ratio slider: controls cell aspect ratio; value clamped to 0.1-10
- Background Color: 4 circular buttons; "Custom" opens a full color picker dialog
- Persist all settings per-canvas in a local database or JSON file

---

### 6. Right-Click / Context Menu

**Desired (from notes):** "you can right click to bring up a menu" (referencing InfiniPaint)

| Feature | Excalidraw | Lorien | InfiniPaint |
|---------|-----------|--------|-------------|
| Context menu | Standard browser right-click | None | `PaintCircleMenu` radial menu — color palette ring + canvas rotation ring; snaps to 45deg |

**Implementation approach:**
- On Android, long-press replaces right-click — use long-press to trigger a radial context menu
- InfiniPaint's `PaintCircleMenu` is the best reference for the radial pattern
- Include quick-access to: color selection, brush size, undo/redo, tool switch
- Consider Concepts app's tool wheel as additional UX reference (noted in `initial_ideas.md`)

---

### 7. Canvas Orientation

**Desired (from notes):** "you can change the orientation of the canvas"

| Feature | Excalidraw | Lorien | InfiniPaint |
|---------|-----------|--------|-------------|
| Canvas rotation | No | No | Yes — drag outer ring of radial menu to rotate; snaps to 45deg multiples |

**Implementation approach:**
- Add a rotation value to the canvas `Matrix` transform
- InfiniPaint's approach: integrate rotation into the radial context menu
- Support free rotation + snap to 0/45/90/135/180/225/270/315 degrees
- Display rotation indicator in status bar or corner of canvas

---

## Implementation Priority (Suggested)

### Phase 1 — Core Canvas
1. Infinite canvas with pan/zoom (pinch + two-finger drag)
2. Freehand brush tool with fixed width
3. Eraser tool (whole-stroke)
4. Color palette (preset colors from mockup)
5. Background color (Default dark theme)
6. Basic UI layout matching mockup (toolbar, color row, settings button, canvas name)

### Phase 2 — Grid & Settings
7. Grid system (Off/Lines/Dots toggle)
8. Grid settings (width, box ratio)
9. Settings panel UI (matching mockup)
10. Background color presets (Custom, Default, Light, Blueprint)

### Phase 3 — Advanced Brush
11. Pressure-sensitive brush (Android stylus)
12. Velocity-sensitive brush with impact slider
13. Pen presets (save/load configurations)
14. Zoom-lock toggle for brush size

### Phase 4 — Extended Tools
15. Shape tools (line, rectangle, ellipse)
16. Text tool
17. Selection tool (move, delete, recolor)
18. Canvas rotation

### Phase 5 — Polish
19. Context/radial menu (long-press)
20. Layers system
21. Undo/redo
22. File save/load/export
23. Multi-canvas tabs
