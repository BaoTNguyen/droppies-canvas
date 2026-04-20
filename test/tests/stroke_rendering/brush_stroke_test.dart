import 'package:test/test.dart';
import 'package:flutter/painting.dart';
import 'package:droppies_canvas/models/stroke.dart';
import 'package:droppies_canvas/models/stroke_point.dart';

void main() {
  StrokePoint pt(double x, double y, {double pressure = 0.5, double velocity = 0.0, int ts = 0}) =>
      StrokePoint(x: x, y: y, pressure: pressure, velocity: velocity, timestamp: ts);

  group('Stroke construction', () {
    test('stroke has a non-empty unique id', () {
      final s = Stroke(
        points: [pt(0, 0), pt(10, 10)],
        color: const Color(0xFFFF0000),
        baseWidth: 5.0,
        tool: ToolType.pen,
      );
      expect(s.id, isNotEmpty);
    });

    test('two strokes created at the same time have different ids', () {
      final a = Stroke(points: [pt(0, 0)], color: const Color(0xFF000000), baseWidth: 5, tool: ToolType.pen);
      final b = Stroke(points: [pt(0, 0)], color: const Color(0xFF000000), baseWidth: 5, tool: ToolType.pen);
      expect(a.id, isNot(b.id));
    });

    // EDGE CASE: single-point stroke is valid (tap without movement)
    test('single-point stroke is valid', () {
      final s = Stroke(
        points: [pt(50, 50)],
        color: const Color(0xFF000000),
        baseWidth: 3.0,
        tool: ToolType.pen,
      );
      expect(s.points.length, 1);
    });
  });

  group('Bounding box', () {
    test('bounding box contains all points', () {
      final s = Stroke(
        points: [pt(10, 20), pt(50, 80), pt(30, 5)],
        color: const Color(0xFF000000),
        baseWidth: 2.0,
        tool: ToolType.pen,
      );
      expect(s.boundingBox.left, lessThanOrEqualTo(10));
      expect(s.boundingBox.top, lessThanOrEqualTo(5));
      expect(s.boundingBox.right, greaterThanOrEqualTo(50));
      expect(s.boundingBox.bottom, greaterThanOrEqualTo(80));
    });

    // EDGE CASE: bounding box expands by baseWidth/2 on all sides (for hit testing)
    test('bounding box is inflated by at least baseWidth/2', () {
      const w = 10.0;
      final s = Stroke(
        points: [pt(100, 100), pt(200, 200)],
        color: const Color(0xFF000000),
        baseWidth: w,
        tool: ToolType.pen,
      );
      expect(s.boundingBox.left, lessThanOrEqualTo(100 - w / 2));
      expect(s.boundingBox.top, lessThanOrEqualTo(100 - w / 2));
      expect(s.boundingBox.right, greaterThanOrEqualTo(200 + w / 2));
      expect(s.boundingBox.bottom, greaterThanOrEqualTo(200 + w / 2));
    });

    // EDGE CASE: single-point bounding box is a non-zero square
    test('single-point bounding box is non-degenerate', () {
      final s = Stroke(points: [pt(50, 50)], color: const Color(0xFF000000), baseWidth: 6.0, tool: ToolType.pen);
      expect(s.boundingBox.width, greaterThan(0));
      expect(s.boundingBox.height, greaterThan(0));
    });
  });

  group('containsPoint', () {
    test('point on the stroke path is inside tolerance', () {
      final s = Stroke(
        points: [pt(0, 0), pt(100, 0)],
        color: const Color(0xFF000000),
        baseWidth: 4.0,
        tool: ToolType.pen,
      );
      expect(s.containsPoint(const Offset(50, 0), 10.0), isTrue);
    });

    test('point far from stroke is outside tolerance', () {
      final s = Stroke(
        points: [pt(0, 0), pt(100, 0)],
        color: const Color(0xFF000000),
        baseWidth: 4.0,
        tool: ToolType.pen,
      );
      expect(s.containsPoint(const Offset(50, 100), 10.0), isFalse);
    });

    // EDGE CASE: point near endpoint is still inside tolerance
    test('point near endpoint counts as hit', () {
      final s = Stroke(
        points: [pt(0, 0), pt(100, 0)],
        color: const Color(0xFF000000),
        baseWidth: 4.0,
        tool: ToolType.pen,
      );
      expect(s.containsPoint(const Offset(0, 0), 5.0), isTrue);
      expect(s.containsPoint(const Offset(100, 0), 5.0), isTrue);
    });

    test('zero tolerance only matches exact point position', () {
      final s = Stroke(
        points: [pt(50, 50)],
        color: const Color(0xFF000000),
        baseWidth: 4.0,
        tool: ToolType.pen,
      );
      expect(s.containsPoint(const Offset(50, 50), 0.0), isTrue);
      expect(s.containsPoint(const Offset(50.1, 50), 0.0), isFalse);
    });
  });

  group('Serialization', () {
    test('toJson round-trip preserves all fields', () {
      final original = Stroke(
        points: [pt(10, 20, pressure: 0.8, velocity: 150.0, ts: 1000)],
        color: const Color(0xFF3A7BD5),
        baseWidth: 8.0,
        tool: ToolType.pen,
      );
      final json = original.toJson();
      final restored = Stroke.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.color.value, original.color.value);
      expect(restored.baseWidth, original.baseWidth);
      expect(restored.tool, original.tool);
      expect(restored.points.length, original.points.length);
      expect(restored.points.first.x, original.points.first.x);
      expect(restored.points.first.pressure, original.points.first.pressure);
    });

    // EDGE CASE: stroke with many points serializes without truncation
    test('stroke with 1000 points round-trips without data loss', () {
      final points = List.generate(1000, (i) => pt(i.toDouble(), i.toDouble()));
      final s = Stroke(points: points, color: const Color(0xFF000000), baseWidth: 2.0, tool: ToolType.pen);
      final restored = Stroke.fromJson(s.toJson());
      expect(restored.points.length, 1000);
    });

    // EDGE CASE: deserializing malformed JSON throws FormatException, not null
    test('fromJson with missing required field throws FormatException', () {
      final broken = {'color': 0xFF000000}; // missing points, baseWidth, tool
      expect(() => Stroke.fromJson(broken), throwsA(isA<FormatException>()));
    });
  });
}
