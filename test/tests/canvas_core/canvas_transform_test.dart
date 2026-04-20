import 'package:test/test.dart';
import 'package:flutter/painting.dart';
import 'package:droppies_canvas/engine/canvas_transform.dart';

void main() {
  late CanvasTransform t;

  setUp(() => t = CanvasTransform());

  group('Initial state', () {
    test('starts at identity transform', () {
      expect(t.translationX, 0.0);
      expect(t.translationY, 0.0);
      expect(t.scale, 1.0);
      expect(t.rotationDeg, 0.0);
    });
  });

  group('Pan', () {
    test('pan accumulates translation', () {
      t.pan(100, -50);
      expect(t.translationX, 100.0);
      expect(t.translationY, -50.0);

      t.pan(-30, 20);
      expect(t.translationX, 70.0);
      expect(t.translationY, -30.0);
    });

    test('pan with zero delta leaves transform unchanged', () {
      t.pan(0, 0);
      expect(t.translationX, 0.0);
      expect(t.translationY, 0.0);
    });

    // EDGE CASE: large pan values must not overflow or clamp
    test('pan accepts very large values', () {
      t.pan(1e7, -1e7);
      expect(t.translationX, 1e7);
      expect(t.translationY, -1e7);
    });
  });

  group('Zoom', () {
    test('zoom changes scale multiplicatively', () {
      t.zoom(2.0, Offset(0, 0));
      expect(t.scale, 2.0);
      t.zoom(0.5, Offset(0, 0));
      expect(t.scale, 1.0);
    });

    test('zoom clamps to minScale', () {
      t.zoom(0.0001, Offset(0, 0));
      expect(t.scale, greaterThanOrEqualTo(CanvasTransform.minScale));
    });

    test('zoom clamps to maxScale', () {
      t.zoom(1e6, Offset(0, 0));
      expect(t.scale, lessThanOrEqualTo(CanvasTransform.maxScale));
    });

    // EDGE CASE: zoom focal point adjusts translation so focal point stays fixed
    test('zoom around off-center focal point keeps focal point stationary', () {
      const focal = Offset(200, 300);
      final canvasBefore = t.screenToCanvas(focal);
      t.zoom(2.0, focal);
      final canvasAfter = t.screenToCanvas(focal);
      expect(canvasBefore.dx, closeTo(canvasAfter.dx, 0.5));
      expect(canvasBefore.dy, closeTo(canvasAfter.dy, 0.5));
    });

    test('zoom factor of 1.0 leaves scale unchanged', () {
      t.zoom(2.0, Offset.zero);
      t.zoom(1.0, Offset.zero);
      expect(t.scale, 2.0);
    });

    // EDGE CASE: negative zoom factor must be rejected (throws or is ignored)
    test('negative zoom factor does not corrupt state', () {
      t.zoom(-1.0, Offset.zero);
      expect(t.scale, greaterThan(0));
    });
  });

  group('Rotation', () {
    test('rotateTo sets rotation in degrees', () {
      t.rotateTo(45.0);
      expect(t.rotationDeg, 45.0);
    });

    test('rotateTo normalizes to 0–360 range', () {
      t.rotateTo(400.0);
      expect(t.rotationDeg, closeTo(40.0, 0.001));

      t.rotateTo(-90.0);
      expect(t.rotationDeg, closeTo(270.0, 0.001));
    });

    test('rotateTo(0) returns to no rotation', () {
      t.rotateTo(135.0);
      t.rotateTo(0.0);
      expect(t.rotationDeg, 0.0);
    });
  });

  group('Coordinate conversion', () {
    test('screenToCanvas is inverse of canvasToScreen at identity', () {
      const p = Offset(123.0, 456.0);
      final roundTrip = t.canvasToScreen(t.screenToCanvas(p));
      expect(roundTrip.dx, closeTo(p.dx, 0.01));
      expect(roundTrip.dy, closeTo(p.dy, 0.01));
    });

    test('screenToCanvas accounts for pan', () {
      t.pan(100, 200);
      final canvasOrigin = t.screenToCanvas(Offset(100, 200));
      expect(canvasOrigin.dx, closeTo(0, 0.01));
      expect(canvasOrigin.dy, closeTo(0, 0.01));
    });

    test('screenToCanvas accounts for scale', () {
      t.zoom(2.0, Offset.zero);
      final p = t.screenToCanvas(Offset(200, 400));
      expect(p.dx, closeTo(100, 0.01));
      expect(p.dy, closeTo(200, 0.01));
    });

    test('round-trip holds under combined pan + zoom + rotation', () {
      t.pan(50, -80);
      t.zoom(1.5, Offset(50, 50));
      t.rotateTo(30.0);
      const p = Offset(300, 150);
      final roundTrip = t.canvasToScreen(t.screenToCanvas(p));
      expect(roundTrip.dx, closeTo(p.dx, 0.1));
      expect(roundTrip.dy, closeTo(p.dy, 0.1));
    });
  });

  group('Reset', () {
    test('resetToIdentity restores all fields to initial values', () {
      t.pan(999, -999);
      t.zoom(5.0, Offset.zero);
      t.rotateTo(270.0);
      t.resetToIdentity();
      expect(t.translationX, 0.0);
      expect(t.translationY, 0.0);
      expect(t.scale, 1.0);
      expect(t.rotationDeg, 0.0);
    });
  });
}
