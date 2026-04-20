# Droppies Canvas — Test Suite

This directory is the **specification contract** for the Droppies Canvas Flutter app.
Tests define required behavior. A separate agent implements `lib/` to satisfy them.

## How to use these tests

Once the Flutter project is scaffolded, copy the contents of this `tests/` directory
into the Flutter project's `test/` directory and run:

```bash
flutter test
```

All tests will fail until the implementation exists — that is the intent.

## Directory structure

```
tests/
  TECH_STACK.md              ← Tech stack decision and rationale
  CONTRACT.dart              ← Full API surface (abstract classes + enums)
  canvas_core/
    canvas_transform_test.dart    ← Pan, zoom, rotate, coordinate conversion
  stroke_rendering/
    brush_stroke_test.dart        ← Stroke model, bounding box, hit testing, serialization
    pressure_velocity_test.dart   ← Pressure/velocity width calculation, PenConfig
  tool_management/
    drawing_engine_test.dart      ← Stroke lifecycle, eraser, viewport culling
  grid_system/
    grid_config_test.dart         ← Grid types, box ratio clamping, visible line count
  settings/
    canvas_settings_test.dart     ← Theme presets, mutation, serialization
  file_persistence/
    canvas_document_test.dart     ← Document model, JSON round-trip, error handling
    canvas_repository_test.dart   ← Save/load/delete/list, corruption handling
  undo_redo/
    undo_redo_test.dart           ← Undo/redo stack, LIFO order, redo-clear-on-new-action
  obsidian_export/
    obsidian_export_test.dart     ← PNG export, filename sanitization, .md sidecar
```

## Implementation packages required

```yaml
dependencies:
  flutter:
    sdk: flutter
  uuid: ^4.0.0              # for Stroke/Document IDs
  path_provider: ^2.1.0     # for default storage path on Android
  file_picker: ^8.0.0       # for user-chosen Obsidian vault path
  perfect_freehand: ^2.0.0  # Bezier stroke smoothing algorithm

dev_dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.25.0
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

## Expected lib/ structure

```
lib/
  models/
    stroke.dart             ← Stroke, ToolType
    stroke_point.dart       ← StrokePoint (+ fromMotion factory)
    pen_config.dart         ← PenConfig, PenType
    canvas_document.dart    ← CanvasDocument
  engine/
    canvas_transform.dart   ← CanvasTransform
    drawing_engine.dart     ← DrawingEngine
    undo_redo_history.dart  ← UndoRedoHistory, CanvasAction, AddStrokeAction, EraseAction
  grid/
    grid_config.dart        ← GridConfig, GridType
  settings/
    canvas_settings.dart    ← CanvasSettings
  file_persistence/
    canvas_repository.dart  ← CanvasRepository
  export/
    obsidian_exporter.dart  ← ObsidianExporter
```

## Feature phase coverage

| Phase | Feature | Tests covering it |
|---|---|---|
| 1 | Infinite canvas pan/zoom | `canvas_transform_test.dart` |
| 1 | Freehand brush (fixed width) | `brush_stroke_test.dart`, `drawing_engine_test.dart` |
| 1 | Eraser (whole-stroke) | `drawing_engine_test.dart` |
| 1 | Color palette | `drawing_engine_test.dart` (activeColor) |
| 2 | Grid system | `grid_config_test.dart` |
| 2 | Settings panel | `canvas_settings_test.dart` |
| 3 | Pressure-sensitive brush | `pressure_velocity_test.dart` |
| 3 | Velocity-sensitive brush | `pressure_velocity_test.dart` |
| 3 | Pen presets | `pressure_velocity_test.dart` (PenConfig serialization) |
| 3 | Zoom-lock toggle | `pressure_velocity_test.dart` |
| 4 | Canvas rotation | `canvas_transform_test.dart` (rotateTo) |
| 5 | Undo/redo | `undo_redo_test.dart` |
| 5 | File save/load | `canvas_repository_test.dart` |
| 5 | Obsidian export | `obsidian_export_test.dart` |
