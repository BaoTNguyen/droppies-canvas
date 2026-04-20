import 'package:test/test.dart';
import 'package:droppies_canvas/grid/grid_config.dart';

void main() {
  group('GridConfig defaults', () {
    test('default grid is off', () {
      final g = GridConfig();
      expect(g.type, GridType.off);
    });

    test('default cell width is 48', () {
      final g = GridConfig();
      expect(g.cellWidth, 48.0);
    });

    test('default box ratio is 1.0 (square cells)', () {
      final g = GridConfig();
      expect(g.boxRatio, 1.0);
    });

    test('cellHeight == cellWidth * boxRatio', () {
      final g = GridConfig(cellWidth: 60, boxRatio: 2.0, type: GridType.lines);
      expect(g.cellHeight, closeTo(120.0, 0.001));
    });
  });

  group('BoxRatio clamping', () {
    test('boxRatio below 0.1 is clamped to 0.1', () {
      final g = GridConfig(boxRatio: 0.0);
      expect(g.boxRatio, 0.1);
    });

    test('boxRatio above 10 is clamped to 10', () {
      final g = GridConfig(boxRatio: 999.0);
      expect(g.boxRatio, 10.0);
    });

    test('boxRatio exactly at boundaries is accepted', () {
      expect(GridConfig(boxRatio: 0.1).boxRatio, 0.1);
      expect(GridConfig(boxRatio: 10.0).boxRatio, 10.0);
    });
  });

  group('CellWidth clamping', () {
    // EDGE CASE: zero or negative cell width must not produce divide-by-zero in renderer
    test('cellWidth below 1 is clamped to 1', () {
      final g = GridConfig(cellWidth: 0.0);
      expect(g.cellWidth, greaterThanOrEqualTo(1.0));
    });

    test('cellWidth is preserved when valid', () {
      final g = GridConfig(cellWidth: 96.0);
      expect(g.cellWidth, 96.0);
    });
  });

  group('Grid types', () {
    test('GridType.off means no grid lines should be drawn', () {
      final g = GridConfig(type: GridType.off);
      expect(g.type, GridType.off);
    });

    test('GridType.lines is set correctly', () {
      final g = GridConfig(type: GridType.lines);
      expect(g.type, GridType.lines);
    });

    test('GridType.dots is set correctly', () {
      final g = GridConfig(type: GridType.dots);
      expect(g.type, GridType.dots);
    });
  });

  group('Visible grid lines calculation', () {
    // The grid renderer must know how many lines to draw given a viewport.
    test('visibleColumns returns correct count for viewport', () {
      final g = GridConfig(cellWidth: 50, boxRatio: 1, type: GridType.lines);
      // viewport 500px wide starting at canvas x=0 → 10 columns + 1 border = 11 lines
      final cols = g.visibleColumns(viewportLeft: 0, viewportRight: 500);
      expect(cols, greaterThanOrEqualTo(10));
      expect(cols, lessThanOrEqualTo(12)); // small buffer allowed
    });

    // EDGE CASE: viewport not aligned to grid origin — lines start before viewport
    test('visibleColumns accounts for non-aligned viewport offset', () {
      final g = GridConfig(cellWidth: 100, boxRatio: 1, type: GridType.lines);
      // viewport starts at x=150 (mid-cell) and ends at x=350
      final cols = g.visibleColumns(viewportLeft: 150, viewportRight: 350);
      expect(cols, greaterThanOrEqualTo(2));
    });

    test('visibleRows uses cellHeight (cellWidth * boxRatio)', () {
      final g = GridConfig(cellWidth: 50, boxRatio: 2, type: GridType.lines);
      // cellHeight = 100; viewport 400px tall → ~4 rows
      final rows = g.visibleRows(viewportTop: 0, viewportBottom: 400);
      expect(rows, greaterThanOrEqualTo(4));
    });
  });

  group('Serialization', () {
    test('toJson round-trip preserves all fields', () {
      final g = GridConfig(type: GridType.dots, cellWidth: 72, lineWidth: 1.5, boxRatio: 0.5);
      final restored = GridConfig.fromJson(g.toJson());
      expect(restored.type, GridType.dots);
      expect(restored.cellWidth, 72.0);
      expect(restored.lineWidth, 1.5);
      expect(restored.boxRatio, 0.5);
    });
  });
}
