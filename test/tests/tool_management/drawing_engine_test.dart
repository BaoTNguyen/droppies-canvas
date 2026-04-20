import 'package:test/test.dart';
import 'package:flutter/painting.dart';
import 'package:droppies_canvas/engine/drawing_engine.dart';
import 'package:droppies_canvas/models/canvas_document.dart';
import 'package:droppies_canvas/models/stroke_point.dart';
import 'package:droppies_canvas/models/pen_config.dart';
import 'package:droppies_canvas/models/stroke.dart';

void main() {
  late DrawingEngine engine;

  StrokePoint pt(double x, double y, {int ts = 0}) =>
      StrokePoint(x: x, y: y, pressure: 0.5, velocity: 5.0, timestamp: ts);

  setUp(() {
    engine = DrawingEngine(
      document: CanvasDocument.create(name: 'Test Canvas'),
    );
  });

  group('Stroke lifecycle', () {
    test('beginStroke returns a stroke with the start point', () {
      final stroke = engine.beginStroke(pt(10, 20));
      expect(stroke.points.length, 1);
      expect(stroke.points.first.x, 10.0);
    });

    test('continueStroke adds points to in-progress stroke', () {
      engine.beginStroke(pt(0, 0));
      engine.continueStroke(pt(10, 10));
      engine.continueStroke(pt(20, 20));
      final finished = engine.endStroke();
      expect(finished.points.length, 3);
    });

    test('endStroke adds the stroke to the document', () {
      engine.beginStroke(pt(0, 0));
      engine.continueStroke(pt(50, 50));
      engine.endStroke();
      expect(engine.document.strokes.length, 1);
    });

    test('endStroke returns completed stroke with correct color', () {
      engine.activeColor = const Color(0xFF00FF00);
      engine.beginStroke(pt(0, 0));
      final s = engine.endStroke();
      expect(s.color.value, 0xFF00FF00);
    });

    // EDGE CASE: endStroke without beginStroke must not throw or corrupt state
    test('endStroke without beginStroke is a no-op', () {
      expect(() => engine.endStroke(), returnsNormally);
      expect(engine.document.strokes.isEmpty, isTrue);
    });

    // EDGE CASE: continueStroke without beginStroke must not throw
    test('continueStroke without active stroke is a no-op', () {
      expect(() => engine.continueStroke(pt(10, 10)), returnsNormally);
    });

    test('multiple strokes accumulate in document', () {
      for (int i = 0; i < 5; i++) {
        engine.beginStroke(pt(i * 10.0, 0));
        engine.continueStroke(pt(i * 10.0 + 5, 50));
        engine.endStroke();
      }
      expect(engine.document.strokes.length, 5);
    });
  });

  group('Eraser — whole-stroke mode', () {
    test('eraseAt removes stroke whose path intersects the eraser circle', () {
      engine.beginStroke(pt(50, 50));
      engine.continueStroke(pt(100, 50));
      engine.endStroke();

      engine.eraseAt(const Offset(75, 50), 20.0);
      expect(engine.document.strokes.isEmpty, isTrue);
    });

    test('eraseAt does not remove stroke outside eraser radius', () {
      engine.beginStroke(pt(0, 0));
      engine.continueStroke(pt(10, 0));
      engine.endStroke();

      engine.eraseAt(const Offset(200, 200), 5.0);
      expect(engine.document.strokes.length, 1);
    });

    test('eraseAt removes only the intersecting stroke when multiple exist', () {
      // Stroke A at y=0
      engine.beginStroke(pt(0, 0)); engine.continueStroke(pt(100, 0)); engine.endStroke();
      // Stroke B at y=200
      engine.beginStroke(pt(0, 200)); engine.continueStroke(pt(100, 200)); engine.endStroke();

      engine.eraseAt(const Offset(50, 0), 10.0);
      expect(engine.document.strokes.length, 1);
      expect(engine.document.strokes.first.points.first.y, 200.0);
    });

    // EDGE CASE: erasing from empty canvas does not throw
    test('eraseAt on empty canvas is a no-op', () {
      expect(() => engine.eraseAt(const Offset(0, 0), 20.0), returnsNormally);
    });

    // EDGE CASE: eraser radius of 0 erases nothing
    test('eraseAt with radius 0 erases nothing', () {
      engine.beginStroke(pt(50, 50)); engine.endStroke();
      engine.eraseAt(const Offset(50, 50), 0.0);
      expect(engine.document.strokes.length, 1);
    });
  });

  group('Viewport culling', () {
    test('strokesInViewport returns only strokes whose bounding box intersects', () {
      // Stroke inside viewport
      engine.beginStroke(pt(100, 100)); engine.continueStroke(pt(200, 200)); engine.endStroke();
      // Stroke outside viewport
      engine.beginStroke(pt(5000, 5000)); engine.continueStroke(pt(5100, 5100)); engine.endStroke();

      final visible = engine.strokesInViewport(const Rect.fromLTWH(0, 0, 500, 500));
      expect(visible.length, 1);
    });

    test('strokesInViewport returns empty list when no strokes exist', () {
      final visible = engine.strokesInViewport(const Rect.fromLTWH(0, 0, 1000, 1000));
      expect(visible, isEmpty);
    });

    // EDGE CASE: stroke that partially overlaps viewport edge is included
    test('stroke partially inside viewport is included', () {
      engine.beginStroke(pt(450, 250)); engine.continueStroke(pt(550, 250)); engine.endStroke();
      final visible = engine.strokesInViewport(const Rect.fromLTWH(0, 0, 500, 500));
      expect(visible.length, 1);
    });
  });

  group('Tool switching', () {
    test('switching tool does not affect strokes already drawn', () {
      engine.activeTool = ToolType.pen;
      engine.beginStroke(pt(0, 0)); engine.endStroke();

      engine.activeTool = ToolType.eraser;
      expect(engine.document.strokes.length, 1);
    });
  });
}
