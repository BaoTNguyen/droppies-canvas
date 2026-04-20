# Droppies Canvas — Tech Stack Decision

## Constraints Matrix

| Constraint | Impact |
|---|---|
| Android-first, minimal OS issues | Favor native Android APIs or proven cross-platform layer |
| Future cross-platform viability | Avoid Android-only APIs in core logic |
| Complex canvas: freehand, pressure, velocity | Needs low-latency stylus input + custom paint pipeline |
| Infinite canvas + pan/zoom/rotate | Matrix transforms, viewport culling |
| Local file I/O to Obsidian vault directory | File system access, no cloud required |
| Obsidian: manual addition (no plugin) | Export PNG + optional `.md` sidecar; no Obsidian API needed |

---

## Candidates Evaluated

### 1. Native Kotlin + Jetpack Compose Canvas
- **Pro:** Best Android stylus API (`MotionEvent.getPressure()`, `TOOL_TYPE_STYLUS`), zero abstraction overhead, Compose `Canvas` is production-ready
- **Con:** Android-only; complete rewrite for iOS/desktop; no path to Obsidian desktop integration
- **Risk:** If user ever wants macOS/Windows companion app, entire codebase is thrown away

### 2. Flutter (Dart)
- **Pro:** `CustomPainter` + `Canvas` is purpose-built for drawing; `PointerEvent` exposes pressure/tilt on Android; single codebase targets Android → iOS → desktop; `perfect_freehand` algorithm available as Dart package; `path_provider` + `file_picker` for vault directory access
- **Con:** Dart ecosystem is smaller; `PointerEvent` pressure on Android requires API 26+; thin wrapper around platform APIs means debugging stylus edge cases is harder than native
- **Risk:** Flutter's stylus pressure support is good but not as granular as native `MotionEvent` — spike smoothing must be done in Dart, not delegated to a system API

### 3. React Native + react-native-skia
- **Pro:** Skia rendering (same as InfiniPaint), TypeScript, large ecosystem
- **Con:** Bridge overhead hurts 60fps drawing; Skia integration still maturing; JS GC pauses visible during fast strokes
- **Risk:** Frame drops during fast freehand strokes — the exact core feature

### 4. Kotlin Multiplatform Mobile (KMM)
- **Pro:** Shared business logic in Kotlin, native UI per platform
- **Con:** Shared drawing logic is the hard part — KMM shares business logic but NOT UI, so you write the canvas renderer twice anyway; immature tooling
- **Risk:** Gives the illusion of cross-platform while still requiring duplicate canvas implementations

---

## Recommendation: Flutter

**Rationale:**
1. The `perfect_freehand` algorithm (Excalidraw's stroke engine) has a [Dart port](https://pub.dev/packages/perfect_freehand) — this is the single biggest leverage point for a high-quality first version
2. `CustomPainter.paint(Canvas canvas, Size size)` gives direct access to Flutter's Skia-backed canvas — same rendering engine as InfiniPaint's reference code
3. `PointerEvent.pressure` (0.0–1.0) and `PointerEvent.radiusMajor` on Android API 26+ covers the pressure sensitivity requirement
4. Velocity is derived from consecutive `PointerEvent` positions + timestamps — identical math regardless of platform
5. Obsidian export = write PNG to a user-chosen directory via `dart:io` — no platform channel needed
6. Android → iOS is a recompile, not a rewrite

**Flutter version:** 3.22+ (Dart 3.4+)
**Minimum Android API:** 26 (Android 8.0) — required for reliable stylus pressure

---

## Project Structure (Flutter)

```
droppies_canvas/
  lib/
    models/           # CanvasDocument, Stroke, StrokePoint, etc.
    engine/           # CanvasTransform, DrawingEngine, UndoRedoHistory
    tools/            # PenTool, EraserTool, ShapeTool
    grid/             # GridConfig, GridRenderer
    settings/         # CanvasSettings, SettingsRepository
    export/           # ObsidianExporter, PngRenderer
    ui/               # Widgets (CanvasView, Toolbar, SettingsPanel, etc.)
  test/               # ← these test files belong here in the Flutter project
```

---

## Obsidian Integration Design

**Mechanism:** File export — no plugin, no API, no Obsidian process interaction.

**Flow:**
1. User sets vault path once in app settings (stored in `SharedPreferences`)
2. On save/export, app writes to `<vaultPath>/Droppies/<canvasName>.png`
3. Optionally writes `<vaultPath>/Droppies/<canvasName>.md` sidecar:
   ```markdown
   ---
   created: 2026-04-17T20:00:00
   tags: [canvas, droppies]
   ---
   ![[<canvasName>.png]]
   ```
4. User opens Obsidian, finds the file in their vault — no sync needed

**Why PNG not Obsidian's `.canvas` format:**
Obsidian's `.canvas` format is a node-graph format (cards + arrows). Droppies Canvas is a freehand drawing app — its output is raster/vector art, not a knowledge graph. PNG is the correct format. The `.md` sidecar makes it linkable from any note.
