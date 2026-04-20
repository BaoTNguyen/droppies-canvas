import 'package:test/test.dart';
import 'package:droppies_canvas/models/stroke_point.dart';
import 'package:droppies_canvas/models/pen_config.dart';

void main() {
  StrokePoint pt({required double pressure, required double velocity}) =>
      StrokePoint(x: 0, y: 0, pressure: pressure, velocity: velocity, timestamp: 0);

  group('StrokePoint velocity derivation', () {
    test('velocity is computed from consecutive points with non-zero time delta', () {
      final a = StrokePoint(x: 0, y: 0, pressure: 0.5, velocity: 0, timestamp: 0);
      final b = StrokePoint.fromMotion(x: 30, y: 40, pressure: 0.5, previousPoint: a, timestamp: 10);
      // distance = 50px in 10ms → 5 px/ms
      expect(b.velocity, closeTo(5.0, 0.1));
    });

    // EDGE CASE: zero time delta (two events same timestamp) must not divide by zero
    test('zero time delta clamps velocity to previous velocity', () {
      final a = StrokePoint(x: 0, y: 0, pressure: 0.5, velocity: 3.0, timestamp: 100);
      final b = StrokePoint.fromMotion(x: 10, y: 0, pressure: 0.5, previousPoint: a, timestamp: 100);
      expect(b.velocity, isNotNaN);
      expect(b.velocity.isFinite, isTrue);
    });

    // EDGE CASE: velocity spike smoothing — single huge jump is dampened
    test('velocity spike larger than 3x previous is clamped', () {
      final a = StrokePoint(x: 0, y: 0, pressure: 0.5, velocity: 2.0, timestamp: 0);
      // 1000px in 1ms = 1000 px/ms — should be clamped relative to previous
      final b = StrokePoint.fromMotion(x: 1000, y: 0, pressure: 0.5, previousPoint: a, timestamp: 1);
      expect(b.velocity, lessThan(1000.0));
    });
  });

  group('PenConfig.computeWidth — fixed pen', () {
    test('fixed pen ignores pressure and velocity', () {
      final pen = PenConfig(
        id: 'fixed',
        name: 'Fixed',
        type: PenType.fixed,
        width: 10.0,
        pressureSensitivity: 0,
        velocityImpact: 0,
        zoomLocked: false,
      );
      expect(pen.computeWidth(pt(pressure: 0.1, velocity: 500), 1.0), closeTo(10.0, 0.01));
      expect(pen.computeWidth(pt(pressure: 1.0, velocity: 0), 1.0), closeTo(10.0, 0.01));
    });
  });

  group('PenConfig.computeWidth — pressure sensitive', () {
    late PenConfig pen;

    setUp(() => pen = PenConfig(
          id: 'pressure',
          name: 'Pressure Pen',
          type: PenType.pressureSensitive,
          width: 20.0,
          pressureSensitivity: 1.0,
          velocityImpact: 0,
          zoomLocked: false,
        ));

    test('full pressure produces full width', () {
      expect(pen.computeWidth(pt(pressure: 1.0, velocity: 0), 1.0), closeTo(20.0, 0.5));
    });

    test('zero pressure produces minimum width (not zero)', () {
      final w = pen.computeWidth(pt(pressure: 0.0, velocity: 0), 1.0);
      expect(w, greaterThan(0));
      expect(w, lessThan(20.0));
    });

    test('mid pressure produces mid-range width', () {
      final w = pen.computeWidth(pt(pressure: 0.5, velocity: 0), 1.0);
      expect(w, greaterThan(0));
      expect(w, lessThanOrEqualTo(20.0));
    });

    test('sensitivity of 0 reverts to fixed width behavior', () {
      final noPressure = PenConfig(
        id: 'p', name: 'P', type: PenType.pressureSensitive,
        width: 10.0, pressureSensitivity: 0.0, velocityImpact: 0, zoomLocked: false,
      );
      expect(noPressure.computeWidth(pt(pressure: 0.1, velocity: 0), 1.0),
             closeTo(noPressure.computeWidth(pt(pressure: 1.0, velocity: 0), 1.0), 0.5));
    });
  });

  group('PenConfig.computeWidth — velocity sensitive', () {
    late PenConfig pen;

    setUp(() => pen = PenConfig(
          id: 'vel',
          name: 'Velocity Pen',
          type: PenType.velocitySensitive,
          width: 20.0,
          pressureSensitivity: 0,
          velocityImpact: 1.0,
          zoomLocked: false,
        ));

    // fast stroke = thin line (like a real pen)
    test('high velocity produces thinner stroke', () {
      final slow = pen.computeWidth(pt(pressure: 0.5, velocity: 1.0), 1.0);
      final fast = pen.computeWidth(pt(pressure: 0.5, velocity: 50.0), 1.0);
      expect(slow, greaterThan(fast));
    });

    test('velocityImpact of 0 disables velocity effect', () {
      final flat = PenConfig(
        id: 'v', name: 'V', type: PenType.velocitySensitive,
        width: 10.0, pressureSensitivity: 0, velocityImpact: 0.0, zoomLocked: false,
      );
      expect(flat.computeWidth(pt(pressure: 0.5, velocity: 0), 1.0),
             closeTo(flat.computeWidth(pt(pressure: 0.5, velocity: 100), 1.0), 0.5));
    });
  });

  group('PenConfig.computeWidth — inverted velocity', () {
    test('inverted: high velocity = thicker stroke', () {
      final pen = PenConfig(
        id: 'inv', name: 'Inverted', type: PenType.velocityInverted,
        width: 20.0, pressureSensitivity: 0, velocityImpact: 1.0, zoomLocked: false,
      );
      final slow = pen.computeWidth(pt(pressure: 0.5, velocity: 1.0), 1.0);
      final fast = pen.computeWidth(pt(pressure: 0.5, velocity: 50.0), 1.0);
      expect(fast, greaterThan(slow));
    });
  });

  group('PenConfig.computeWidth — zoom lock', () {
    test('zoom-locked pen width scales with zoom to keep screen size constant', () {
      final locked = PenConfig(
        id: 'z', name: 'Z', type: PenType.fixed,
        width: 10.0, pressureSensitivity: 0, velocityImpact: 0, zoomLocked: true,
      );
      // at scale 2x, canvas-space width should halve so screen width stays 10px
      final w1 = locked.computeWidth(pt(pressure: 0.5, velocity: 0), 1.0);
      final w2 = locked.computeWidth(pt(pressure: 0.5, velocity: 0), 2.0);
      expect(w2, closeTo(w1 / 2, 0.1));
    });

    test('zoom-unlocked pen width does NOT scale with zoom', () {
      final unlocked = PenConfig(
        id: 'z', name: 'Z', type: PenType.fixed,
        width: 10.0, pressureSensitivity: 0, velocityImpact: 0, zoomLocked: false,
      );
      final w1 = unlocked.computeWidth(pt(pressure: 0.5, velocity: 0), 1.0);
      final w2 = unlocked.computeWidth(pt(pressure: 0.5, velocity: 0), 2.0);
      expect(w1, closeTo(w2, 0.01));
    });
  });

  group('PenConfig serialization', () {
    test('toJson round-trip preserves all fields', () {
      final pen = PenConfig(
        id: 'mypen', name: 'My Pen', type: PenType.pressureSensitive,
        width: 12.5, pressureSensitivity: 0.8, velocityImpact: 0.3, zoomLocked: true,
      );
      final restored = PenConfig.fromJson(pen.toJson());
      expect(restored.id, pen.id);
      expect(restored.name, pen.name);
      expect(restored.type, pen.type);
      expect(restored.width, pen.width);
      expect(restored.pressureSensitivity, pen.pressureSensitivity);
      expect(restored.velocityImpact, pen.velocityImpact);
      expect(restored.zoomLocked, pen.zoomLocked);
    });
  });
}
