// API CONTRACT — defines all interfaces the implementation must satisfy.
// Tests import from 'package:droppies_canvas/...'; this file documents
// the expected public API surface so tests are self-explanatory.
//
// The coding agent must implement these classes in lib/ to satisfy the tests.
// Do NOT modify this file to make tests pass — implement the real classes.

import 'dart:ui';
import 'dart:io';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum ToolType { pen, eraser, line, rectangle, ellipse, text, selection }

enum GridType { off, lines, dots }

enum PenType { fixed, pressureSensitive, velocitySensitive, velocityInverted }

enum BackgroundPreset { defaultDark, light, blueprint, custom }

// ─── StrokePoint ──────────────────────────────────────────────────────────────

// A single captured input point on a stroke.
abstract class StrokePoint {
  double get x;
  double get y;
  double get pressure;   // 0.0–1.0; 0.5 when device reports no pressure
  double get velocity;   // px/ms, derived from consecutive points
  int    get timestamp;  // milliseconds since epoch
}

// ─── Stroke ───────────────────────────────────────────────────────────────────

abstract class Stroke {
  String         get id;
  List<StrokePoint> get points;
  Color          get color;
  double         get baseWidth;
  ToolType       get tool;
  Rect           get boundingBox;

  // Returns true if [point] falls within [tolerance] px of any stroke segment.
  bool containsPoint(Offset point, double tolerance);

  Map<String, dynamic> toJson();
  // static Stroke fromJson(Map<String, dynamic> json); — tested via round-trip
}

// ─── CanvasTransform ──────────────────────────────────────────────────────────

// Encapsulates the infinite canvas transform (pan + zoom + rotation).
abstract class CanvasTransform {
  double get translationX;
  double get translationY;
  double get scale;         // 1.0 = 100%
  double get rotationDeg;   // degrees, 0–360

  void pan(double dx, double dy);
  void zoom(double factor, Offset focalPoint); // focal point in screen coords
  void rotateTo(double degrees);               // absolute
  void resetToIdentity();

  // Coordinate conversion
  Offset screenToCanvas(Offset screenPoint);
  Offset canvasToScreen(Offset canvasPoint);

  // Clamps scale to [minScale, maxScale]
  static const double minScale = 0.05;
  static const double maxScale = 50.0;
}

// ─── GridConfig ───────────────────────────────────────────────────────────────

abstract class GridConfig {
  GridType get type;
  double   get cellWidth;  // px at scale=1; default 48
  double   get lineWidth;  // line thickness in px; default 1
  double   get boxRatio;   // cellHeight = cellWidth * boxRatio; clamped 0.1–10

  double get cellHeight;   // computed: cellWidth * boxRatio

  Map<String, dynamic> toJson();
  // static GridConfig fromJson(Map<String, dynamic> json);
}

// ─── CanvasSettings ───────────────────────────────────────────────────────────

abstract class CanvasSettings {
  GridConfig get grid;
  Color      get backgroundColor;

  static CanvasSettings defaultDark();   // backgroundColor #1a1a2e
  static CanvasSettings light();         // backgroundColor #f5f5f5
  static CanvasSettings blueprint();     // backgroundColor #1e3a5f

  Map<String, dynamic> toJson();
  // static CanvasSettings fromJson(Map<String, dynamic> json);
}

// ─── PenConfig ────────────────────────────────────────────────────────────────

abstract class PenConfig {
  String  get id;
  String  get name;
  PenType get type;
  double  get width;               // base stroke width in px
  double  get pressureSensitivity; // 0.0–1.0; only used when type == pressureSensitive
  double  get velocityImpact;      // 0.0–1.0; only used when type == velocity*
  bool    get zoomLocked;          // if true, width stays constant in screen space

  // Compute actual stroke width for a given input point.
  double computeWidth(StrokePoint point, double currentScale);

  Map<String, dynamic> toJson();
}

// ─── CanvasDocument ───────────────────────────────────────────────────────────

abstract class CanvasDocument {
  String         get id;
  String         get name;
  List<Stroke>   get strokes;
  CanvasSettings get settings;
  DateTime       get createdAt;
  DateTime       get updatedAt;

  Map<String, dynamic> toJson();
  // static CanvasDocument fromJson(Map<String, dynamic> json);
}

// ─── DrawingEngine ────────────────────────────────────────────────────────────

// Manages the mutable state of an active canvas session.
abstract class DrawingEngine {
  CanvasDocument   get document;
  CanvasTransform  get transform;
  ToolType         get activeTool;
  PenConfig        get activePen;
  Color            get activeColor;

  // Returns the newly created stroke
  Stroke beginStroke(StrokePoint startPoint);
  void   continueStroke(StrokePoint point);
  Stroke endStroke();    // finalizes, pushes to history, returns completed stroke

  void eraseAt(Offset canvasPoint, double radius); // removes strokes intersecting circle

  // Returns strokes whose bounding box intersects [viewport] (for culling)
  List<Stroke> strokesInViewport(Rect viewport);
}

// ─── UndoRedoHistory ─────────────────────────────────────────────────────────

abstract class CanvasAction {
  void apply(DrawingEngine engine);
  void revert(DrawingEngine engine);
}

abstract class UndoRedoHistory {
  int get stackDepth;
  bool get canUndo;
  bool get canRedo;

  void push(CanvasAction action);
  void undo();  // no-op if canUndo == false
  void redo();  // no-op if canRedo == false
  void clear();

  // Pushing a new action after an undo discards the redo stack
}

// ─── CanvasRepository ────────────────────────────────────────────────────────

abstract class CanvasRepository {
  Future<void>             save(CanvasDocument doc);
  Future<CanvasDocument?>  load(String id);
  Future<void>             delete(String id);
  Future<List<CanvasDocument>> listAll();
  Future<bool>             exists(String id);
}

// ─── ObsidianExporter ────────────────────────────────────────────────────────

abstract class ObsidianExporter {
  // Renders canvas to PNG and writes to <vaultPath>/Droppies/<sanitizedName>.png
  // Returns the written File.
  Future<File> exportPng(CanvasDocument doc, String vaultPath, {int width = 2048});

  // Writes a .md sidecar file that embeds the PNG via Obsidian wikilink.
  Future<File> exportMarkdownSidecar(CanvasDocument doc, String vaultPath);

  // Returns the Obsidian wikilink string: ![[Droppies/<sanitizedName>.png]]
  String obsidianImageLink(String canvasName);

  // Sanitizes a canvas name for use as a filename (no special chars, max 255 bytes).
  String sanitizeFilename(String name);
}
