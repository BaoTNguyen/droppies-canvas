import 'dart:convert';
import 'package:test/test.dart';
import 'package:flutter/painting.dart';
import 'package:droppies_canvas/models/canvas_document.dart';
import 'package:droppies_canvas/models/stroke.dart';
import 'package:droppies_canvas/models/stroke_point.dart';
import 'package:droppies_canvas/settings/canvas_settings.dart';

void main() {
  CanvasDocument makeDoc({String name = 'Test', int strokeCount = 2}) {
    final doc = CanvasDocument.create(name: name);
    for (int i = 0; i < strokeCount; i++) {
      doc.strokes.add(Stroke(
        points: [
          StrokePoint(x: i * 10.0, y: 0, pressure: 0.5, velocity: 5.0, timestamp: i * 100),
          StrokePoint(x: i * 10.0 + 50, y: 50, pressure: 0.7, velocity: 8.0, timestamp: i * 100 + 50),
        ],
        color: const Color(0xFF3A7BD5),
        baseWidth: 6.0,
        tool: ToolType.pen,
      ));
    }
    return doc;
  }

  group('CanvasDocument creation', () {
    test('create assigns unique id', () {
      final a = CanvasDocument.create(name: 'A');
      final b = CanvasDocument.create(name: 'B');
      expect(a.id, isNot(b.id));
    });

    test('create sets name', () {
      final doc = CanvasDocument.create(name: 'My Canvas');
      expect(doc.name, 'My Canvas');
    });

    test('create initializes with empty strokes list', () {
      final doc = CanvasDocument.create(name: 'Empty');
      expect(doc.strokes, isEmpty);
    });

    test('create sets createdAt close to now', () {
      final before = DateTime.now();
      final doc = CanvasDocument.create(name: 'Time');
      final after = DateTime.now();
      expect(doc.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(doc.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('Serialization round-trip', () {
    test('toJson → fromJson preserves id, name, stroke count', () {
      final original = makeDoc(name: 'Round-trip', strokeCount: 3);
      final json = original.toJson();
      final restored = CanvasDocument.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.strokes.length, 3);
    });

    test('toJson → fromJson preserves stroke point coordinates', () {
      final original = makeDoc(strokeCount: 1);
      final restored = CanvasDocument.fromJson(original.toJson());
      expect(restored.strokes.first.points.first.x, original.strokes.first.points.first.x);
      expect(restored.strokes.first.points.last.pressure, original.strokes.first.points.last.pressure);
    });

    test('toJson → fromJson preserves settings', () {
      final doc = makeDoc();
      doc.settings = CanvasSettings.blueprint();
      final restored = CanvasDocument.fromJson(doc.toJson());
      expect(restored.settings.backgroundColor.value, doc.settings.backgroundColor.value);
    });

    test('toJson produces valid JSON string', () {
      final doc = makeDoc();
      final jsonStr = jsonEncode(doc.toJson());
      expect(() => jsonDecode(jsonStr), returnsNormally);
    });

    // EDGE CASE: document with 0 strokes round-trips cleanly
    test('empty document round-trips without error', () {
      final empty = CanvasDocument.create(name: 'Empty');
      final restored = CanvasDocument.fromJson(empty.toJson());
      expect(restored.strokes, isEmpty);
      expect(restored.name, 'Empty');
    });

    // EDGE CASE: document with 500 strokes round-trips without truncation
    test('document with 500 strokes preserves all strokes', () {
      final large = makeDoc(strokeCount: 500);
      final restored = CanvasDocument.fromJson(large.toJson());
      expect(restored.strokes.length, 500);
    });
  });

  group('fromJson error handling', () {
    // EDGE CASE: completely empty JSON object throws FormatException
    test('fromJson with empty map throws FormatException', () {
      expect(() => CanvasDocument.fromJson({}), throwsA(isA<FormatException>()));
    });

    // EDGE CASE: JSON with missing strokes key defaults to empty list, does not throw
    test('fromJson with missing strokes defaults to empty list', () {
      final json = {'id': 'abc', 'name': 'Test', 'createdAt': DateTime.now().toIso8601String()};
      expect(() => CanvasDocument.fromJson(json), returnsNormally);
      expect(CanvasDocument.fromJson(json).strokes, isEmpty);
    });

    // EDGE CASE: corrupted stroke in list is skipped, rest of document loads
    test('fromJson skips malformed strokes without losing valid strokes', () {
      final doc = makeDoc(strokeCount: 2);
      final json = doc.toJson();
      // corrupt the second stroke
      (json['strokes'] as List)[1] = {'broken': true};
      final restored = CanvasDocument.fromJson(json);
      expect(restored.strokes.length, lessThanOrEqualTo(2));
      expect(restored.strokes.length, greaterThanOrEqualTo(1));
    });
  });

  group('updatedAt', () {
    test('updatedAt changes when strokes are added', () async {
      final doc = CanvasDocument.create(name: 'Update Test');
      final before = doc.updatedAt;
      await Future.delayed(const Duration(milliseconds: 5));
      doc.strokes.add(Stroke(
        points: [StrokePoint(x: 0, y: 0, pressure: 0.5, velocity: 0, timestamp: 0)],
        color: const Color(0xFF000000), baseWidth: 3, tool: ToolType.pen,
      ));
      doc.touch(); // explicit update call — implementation must provide this
      expect(doc.updatedAt.isAfter(before), isTrue);
    });
  });
}
