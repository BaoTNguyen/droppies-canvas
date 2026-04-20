import 'package:flutter/painting.dart';
import '../models/stroke.dart';
import '../models/stroke_point.dart';
import '../models/pen_config.dart';
import '../models/canvas_document.dart';
import 'canvas_transform.dart';
import 'undo_redo_history.dart';

class AddStrokeAction extends CanvasAction {
  final Stroke stroke;
  AddStrokeAction(this.stroke);

  @override
  void apply(DrawingEngine engine) {
    engine.document.strokes.add(stroke);
  }

  @override
  void revert(DrawingEngine engine) {
    engine.document.strokes.remove(stroke);
  }
}

class EraseAction extends CanvasAction {
  final List<Stroke> erasedStrokes;
  EraseAction(this.erasedStrokes);

  @override
  void apply(DrawingEngine engine) {
    for (final stroke in erasedStrokes) {
      engine.document.strokes.remove(stroke);
    }
  }

  @override
  void revert(DrawingEngine engine) {
    engine.document.strokes.addAll(erasedStrokes);
  }
}

class DrawingEngine {
  final CanvasDocument document;
  final CanvasTransform transform = CanvasTransform();
  final UndoRedoHistory history = UndoRedoHistory();

  ToolType activeTool = ToolType.pen;
  Color activeColor = const Color(0xFFFFFFFF);
  PenConfig activePen = const PenConfig(
    id: 'default', name: 'Default', type: PenType.fixed,
    width: 5.0, pressureSensitivity: 0, velocityImpact: 0, zoomLocked: false,
  );

  Stroke? _currentStroke;
  Stroke? get currentStroke => _currentStroke;

  void cancelStroke() {
    _currentStroke = null;
  }

  DrawingEngine({required this.document}) {
    history.engine = this;
  }

  Stroke beginStroke(StrokePoint startPoint) {
    _currentStroke = Stroke(
      points: [startPoint],
      color: activeColor,
      baseWidth: activePen.width,
      tool: activeTool,
    );
    return _currentStroke!;
  }

  void continueStroke(StrokePoint point) {
    if (_currentStroke == null) return;
    _currentStroke!.points.add(point);
  }

  Stroke endStroke() {
    final stroke = _currentStroke;
    if (stroke == null) {
      return Stroke(
        points: const [],
        color: activeColor,
        baseWidth: activePen.width,
        tool: activeTool,
      );
    }
    _currentStroke = null;
    document.strokes.add(stroke);
    history.push(AddStrokeAction(stroke));
    document.touch();
    return stroke;
  }

  void eraseAt(Offset canvasPoint, double radius) {
    if (radius <= 0) return;
    final toRemove = document.strokes
        .where((s) => s.containsPoint(canvasPoint, radius))
        .toList();
    if (toRemove.isEmpty) return;
    for (final s in toRemove) {
      document.strokes.remove(s);
    }
    history.push(EraseAction(toRemove));
    document.touch();
  }

  List<Stroke> strokesInViewport(Rect viewport) {
    return document.strokes
        .where((s) => s.boundingBox.overlaps(viewport))
        .toList();
  }
}
