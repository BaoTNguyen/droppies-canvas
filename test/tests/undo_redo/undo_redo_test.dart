import 'package:test/test.dart';
import 'package:flutter/painting.dart';
import 'package:droppies_canvas/engine/drawing_engine.dart';
import 'package:droppies_canvas/engine/undo_redo_history.dart';
import 'package:droppies_canvas/models/canvas_document.dart';
import 'package:droppies_canvas/models/stroke.dart';
import 'package:droppies_canvas/models/stroke_point.dart';

void main() {
  late DrawingEngine engine;
  late UndoRedoHistory history;

  StrokePoint pt(double x, double y) =>
      StrokePoint(x: x, y: y, pressure: 0.5, velocity: 5.0, timestamp: 0);

  void drawStroke(double x1, double y1, double x2, double y2) {
    engine.beginStroke(pt(x1, y1));
    engine.continueStroke(pt(x2, y2));
    engine.endStroke(); // endStroke should push AddStrokeAction to history
  }

  setUp(() {
    engine = DrawingEngine(document: CanvasDocument.create(name: 'Undo Test'));
    history = engine.history;
  });

  group('Initial state', () {
    test('cannot undo or redo on empty history', () {
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });

    test('stack depth is 0 initially', () {
      expect(history.stackDepth, 0);
    });
  });

  group('Add stroke and undo', () {
    test('drawing a stroke enables undo', () {
      drawStroke(0, 0, 100, 100);
      expect(history.canUndo, isTrue);
    });

    test('undo removes the last drawn stroke', () {
      drawStroke(0, 0, 100, 100);
      expect(engine.document.strokes.length, 1);
      history.undo();
      expect(engine.document.strokes.length, 0);
    });

    test('undo of multiple strokes removes in LIFO order', () {
      drawStroke(0, 0, 10, 10);
      drawStroke(20, 20, 30, 30);
      drawStroke(40, 40, 50, 50);

      history.undo();
      expect(engine.document.strokes.length, 2);
      history.undo();
      expect(engine.document.strokes.length, 1);
      history.undo();
      expect(engine.document.strokes.length, 0);
    });

    test('canUndo becomes false after undoing all actions', () {
      drawStroke(0, 0, 10, 10);
      history.undo();
      expect(history.canUndo, isFalse);
    });
  });

  group('Redo', () {
    test('redo after undo restores the stroke', () {
      drawStroke(0, 0, 100, 100);
      history.undo();
      expect(engine.document.strokes.length, 0);
      history.redo();
      expect(engine.document.strokes.length, 1);
    });

    test('canRedo becomes true after undo', () {
      drawStroke(0, 0, 50, 50);
      history.undo();
      expect(history.canRedo, isTrue);
    });

    test('canRedo becomes false after redo consumes the stack', () {
      drawStroke(0, 0, 50, 50);
      history.undo();
      history.redo();
      expect(history.canRedo, isFalse);
    });

    // EDGE CASE: new action after undo clears the redo stack
    test('drawing after undo clears redo stack', () {
      drawStroke(0, 0, 10, 10);
      drawStroke(20, 20, 30, 30);
      history.undo();
      expect(history.canRedo, isTrue);
      drawStroke(40, 40, 50, 50); // new action
      expect(history.canRedo, isFalse);
    });
  });

  group('Undo erase action', () {
    test('undo of erase restores erased strokes', () {
      drawStroke(0, 0, 100, 0);
      expect(engine.document.strokes.length, 1);
      engine.eraseAt(const Offset(50, 0), 20.0);
      expect(engine.document.strokes.length, 0);
      history.undo();
      expect(engine.document.strokes.length, 1);
    });
  });

  group('No-op safety', () {
    // EDGE CASE: calling undo when canUndo is false does not throw
    test('undo on empty history is a no-op', () {
      expect(() => history.undo(), returnsNormally);
    });

    // EDGE CASE: calling redo when canRedo is false does not throw
    test('redo when nothing to redo is a no-op', () {
      expect(() => history.redo(), returnsNormally);
    });

    test('multiple undos past the beginning stabilize at empty state', () {
      drawStroke(0, 0, 10, 10);
      history.undo();
      history.undo(); // extra undo — must not crash or corrupt
      expect(engine.document.strokes, isEmpty);
    });
  });

  group('Clear', () {
    test('clear empties both undo and redo stacks', () {
      drawStroke(0, 0, 10, 10);
      drawStroke(20, 20, 30, 30);
      history.undo();
      history.clear();
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
      expect(history.stackDepth, 0);
    });

    test('clear does not affect existing strokes in the document', () {
      drawStroke(0, 0, 10, 10);
      history.clear();
      expect(engine.document.strokes.length, 1);
    });
  });
}
