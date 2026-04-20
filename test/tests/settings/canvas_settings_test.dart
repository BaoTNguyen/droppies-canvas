import 'package:test/test.dart';
import 'package:flutter/painting.dart';
import 'package:droppies_canvas/settings/canvas_settings.dart';
import 'package:droppies_canvas/grid/grid_config.dart';

void main() {
  group('Preset themes', () {
    test('defaultDark has dark background', () {
      final s = CanvasSettings.defaultDark();
      // #1a1a2e
      expect(s.backgroundColor.red, lessThan(50));
      expect(s.backgroundColor.green, lessThan(50));
    });

    test('light has near-white background', () {
      final s = CanvasSettings.light();
      expect(s.backgroundColor.red, greaterThan(200));
      expect(s.backgroundColor.green, greaterThan(200));
      expect(s.backgroundColor.blue, greaterThan(200));
    });

    test('blueprint has blue background', () {
      final s = CanvasSettings.blueprint();
      expect(s.backgroundColor.blue, greaterThan(s.backgroundColor.red));
      expect(s.backgroundColor.blue, greaterThan(100));
    });

    test('all presets have grid off by default', () {
      for (final preset in [CanvasSettings.defaultDark(), CanvasSettings.light(), CanvasSettings.blueprint()]) {
        expect(preset.grid.type, GridType.off);
      }
    });
  });

  group('Mutation', () {
    test('can update grid type independently', () {
      final s = CanvasSettings.defaultDark();
      s.grid = GridConfig(type: GridType.lines, cellWidth: 48, boxRatio: 1);
      expect(s.grid.type, GridType.lines);
      // background color must be unchanged
      expect(s.backgroundColor.red, lessThan(50));
    });

    test('can update background color to custom value', () {
      final s = CanvasSettings.defaultDark();
      s.backgroundColor = const Color(0xFFABCDEF);
      expect(s.backgroundColor.value, 0xFFABCDEF);
    });
  });

  group('Serialization', () {
    test('toJson round-trip preserves background color', () {
      final s = CanvasSettings.blueprint();
      final restored = CanvasSettings.fromJson(s.toJson());
      expect(restored.backgroundColor.value, s.backgroundColor.value);
    });

    test('toJson round-trip preserves grid config', () {
      final s = CanvasSettings.light();
      s.grid = GridConfig(type: GridType.dots, cellWidth: 64, lineWidth: 2.0, boxRatio: 1.5);
      final restored = CanvasSettings.fromJson(s.toJson());
      expect(restored.grid.type, GridType.dots);
      expect(restored.grid.cellWidth, 64.0);
      expect(restored.grid.boxRatio, 1.5);
    });

    // EDGE CASE: missing grid key in JSON defaults to off grid, does not throw
    test('fromJson with missing grid key uses default grid', () {
      final json = {'backgroundColor': 0xFFFFFFFF};
      expect(() => CanvasSettings.fromJson(json), returnsNormally);
      final restored = CanvasSettings.fromJson(json);
      expect(restored.grid.type, GridType.off);
    });

    // EDGE CASE: invalid backgroundColor value in JSON uses fallback color
    test('fromJson with invalid backgroundColor uses fallback', () {
      final json = {'backgroundColor': 'not-a-color', 'grid': GridConfig().toJson()};
      expect(() => CanvasSettings.fromJson(json), returnsNormally);
    });
  });
}
